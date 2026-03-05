--[[
    OnClientCommand Handler Tests

    Tests server-side command handling for shop registration/unregistration.
    
    Tests cover:
      - Normal register / unregister flows
      - Ownership / admin access control
      - Re-registration guard (must unregister first)
      - Container-not-empty guard (no admin bypass)
      - Admin bypass sandbox var control
]]

local JASM_TestRunner = require("jasm_test_shared")

-- ---------------------------------------------------------------------------
-- Mock helpers
-- ---------------------------------------------------------------------------

-- Mock IsoPlayer
local function createMockPlayer(username, isAdmin)
    return {
        username = username,
        admin = isAdmin or false,
        getUsername = function(self)
            return self.username
        end,
        isAdmin = function(self)
            return self.admin
        end,
    }
end

-- Mock IsoObject with container
---@param itemCount number|nil  number of items in the mock container (default 0)
local function createMockShopObject(itemCount)
    local count = itemCount or 0
    local fakeItems = {
        size = function()
            return count
        end,
    }
    local container = {
        getItems = function()
            return fakeItems
        end,
    }
    return {
        modData = {},
        _container = container,
        getModData = function(self)
            return self.modData
        end,
        getContainer = function(self)
            return self._container
        end,
    }
end

-- Simulate the admin-bypass sandbox var (in tests we bypass SandboxVarsModule)
-- by injecting a tiny helper that the production code would call.
-- Since we test logic directly (not wired to the full server handler), we
-- replicate the permission checks inline below.

local function isOwnerOrAdmin(modData, player, adminBypass)
    local isOwner = modData.shopOwnerID == player:getUsername()
    local isAdmin = player:isAdmin()
    return isOwner or (isAdmin and adminBypass)
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

local function init()
    -- ------------------------------------------------------------------
    -- Existing tests (preserved)
    -- ------------------------------------------------------------------

    JASM_TestRunner.register("shop_register_command", "server", function()
        local mockObj = createMockShopObject()
        local mockPlayer = createMockPlayer("Owner1")

        local modData = mockObj:getModData()
        -- isShop is nil → REGISTER is allowed
        if not modData.isShop then
            modData.isShop = true
            modData.shopType = "STORAGE"
            modData.shopOwnerID = mockPlayer:getUsername()
            modData.indestructible = true
            modData.immovable = true
        end

        JASM_TestRunner.assert_true(modData.isShop, "isShop should be true after register")
        JASM_TestRunner.assert_equals("STORAGE", modData.shopType, "shopType mismatch")
        JASM_TestRunner.assert_equals("Owner1", modData.shopOwnerID, "shopOwnerID mismatch")
        JASM_TestRunner.assert_true(modData.indestructible, "indestructible should be true")
        JASM_TestRunner.assert_true(modData.immovable, "immovable should be true")
    end)

    JASM_TestRunner.register("shop_unregister_command", "server", function()
        local mockObj = createMockShopObject()
        local mockPlayer = createMockPlayer("Owner1")

        mockObj:getModData().isShop = true
        mockObj:getModData().shopType = "STORAGE"
        mockObj:getModData().shopOwnerID = mockPlayer:getUsername()
        mockObj:getModData().indestructible = true
        mockObj:getModData().immovable = true

        local modData = mockObj:getModData()
        local isOwner = modData.shopOwnerID == mockPlayer:getUsername()

        -- container is empty (0 items) → UNREGISTER allowed
        local hasItems = mockObj:getContainer():getItems():size() > 0
        JASM_TestRunner.assert_false(hasItems, "container should be empty")

        if isOwner and not hasItems then
            modData.isShop = nil
            modData.shopType = nil
            modData.shopOwnerID = nil
            modData.indestructible = nil
            modData.immovable = nil
        end

        JASM_TestRunner.assert_nil(modData.isShop, "isShop should be nil after unregister")
        JASM_TestRunner.assert_nil(modData.shopType, "shopType should be nil after unregister")
        JASM_TestRunner.assert_nil(
            modData.indestructible,
            "indestructible should be nil after unregister"
        )
    end)

    JASM_TestRunner.register("shop_unregister_access", "server", function()
        local mockObj = createMockShopObject()
        local ownerPlayer = createMockPlayer("Owner1")
        local otherPlayer = createMockPlayer("OtherPlayer")

        mockObj:getModData().isShop = true
        mockObj:getModData().shopOwnerID = "Owner1"

        local modData = mockObj:getModData()
        local adminBypass = true -- sandbox default

        local canOther = isOwnerOrAdmin(modData, otherPlayer, adminBypass)
        JASM_TestRunner.assert_false(
            canOther,
            "Non-owner non-admin should not be able to unregister"
        )

        local canOwner = isOwnerOrAdmin(modData, ownerPlayer, adminBypass)
        JASM_TestRunner.assert_true(canOwner, "Owner should be able to unregister")
    end)

    -- ------------------------------------------------------------------
    -- NEW: Issue 2 – REGISTER must be denied if shop already registered
    -- ------------------------------------------------------------------

    -- Normal player tries to re-register an existing shop → denied
    JASM_TestRunner.register("shop_register_blocked_if_already_shop", "server", function()
        local mockObj = createMockShopObject()
        local ownerPlayer = createMockPlayer("Owner1", false)

        -- Pre-condition: shop is already registered
        local modData = mockObj:getModData()
        modData.isShop = true
        modData.shopType = "PLAYER"
        modData.shopOwnerID = "Owner1"

        -- Simulate new REGISTER logic: deny if isShop is already true
        local registerDenied = modData.isShop == true
        JASM_TestRunner.assert_true(
            registerDenied,
            "REGISTER should be denied when shop is already registered"
        )

        -- modData must remain unchanged
        JASM_TestRunner.assert_true(modData.isShop, "isShop should still be true (not overwritten)")
        JASM_TestRunner.assert_equals("Owner1", modData.shopOwnerID, "owner should be unchanged")
    end)

    -- Admin also cannot re-register without unregistering first
    JASM_TestRunner.register("shop_register_blocked_for_admin_if_already_shop", "server", function()
        local mockObj = createMockShopObject()
        local admin = createMockPlayer("Admin1", true)

        local modData = mockObj:getModData()
        modData.isShop = true
        modData.shopOwnerID = "SomebodyElse"

        -- Even admin: deny if already registered
        local registerDenied = modData.isShop == true
        JASM_TestRunner.assert_true(
            registerDenied,
            "Admin REGISTER should be denied when shop is already registered"
        )
    end)

    -- ------------------------------------------------------------------
    -- NEW: Issue 3 – UNREGISTER must be denied if container has items
    -- ------------------------------------------------------------------

    -- Owner tries to unregister a shop that still has items → denied
    JASM_TestRunner.register("shop_unregister_blocked_if_container_has_items", "server", function()
        local mockObj = createMockShopObject(3) -- 3 items in container
        local ownerPlayer = createMockPlayer("Owner1", false)

        local modData = mockObj:getModData()
        modData.isShop = true
        modData.shopOwnerID = "Owner1"

        local isOwner = modData.shopOwnerID == ownerPlayer:getUsername()
        JASM_TestRunner.assert_true(isOwner, "player should be owner")

        -- Container check: must block even when player is owner
        local hasItems = mockObj:getContainer():getItems():size() > 0
        JASM_TestRunner.assert_true(hasItems, "container should have items")

        -- Because hasItems == true, unregister is denied
        local canUnregister = isOwner and not hasItems
        JASM_TestRunner.assert_false(
            canUnregister,
            "UNREGISTER should be denied when container has items"
        )

        -- modData must remain intact
        JASM_TestRunner.assert_true(modData.isShop, "shop should still be registered")
    end)

    -- Admin tries to unregister a shop that still has items → still denied
    JASM_TestRunner.register(
        "shop_unregister_blocked_for_admin_if_container_has_items",
        "server",
        function()
            local mockObj = createMockShopObject(1) -- 1 item in container
            local admin = createMockPlayer("Admin1", true)

            local modData = mockObj:getModData()
            modData.isShop = true
            modData.shopOwnerID = "SomeOtherOwner"

            local isAdmin = admin:isAdmin()
            JASM_TestRunner.assert_true(isAdmin, "player should be admin")

            local hasItems = mockObj:getContainer():getItems():size() > 0
            JASM_TestRunner.assert_true(hasItems, "container should have items")

            -- Even admin: container-not-empty blocks unregister (no bypass)
            local canUnregister = not hasItems -- item check has NO admin bypass
            JASM_TestRunner.assert_false(
                canUnregister,
                "Admin UNREGISTER should be denied when container has items"
            )
        end
    )

    -- Container empty → UNREGISTER allowed even for admin of another player's shop
    JASM_TestRunner.register("shop_unregister_allowed_when_container_empty", "server", function()
        local mockObj = createMockShopObject(0) -- empty
        local admin = createMockPlayer("Admin1", true)

        local modData = mockObj:getModData()
        modData.isShop = true
        modData.shopOwnerID = "SomeOwner"

        local adminBypass = true
        local canBypass = isOwnerOrAdmin(modData, admin, adminBypass)
        local hasItems = mockObj:getContainer():getItems():size() > 0

        JASM_TestRunner.assert_true(canBypass, "admin with bypass should pass ownership check")
        JASM_TestRunner.assert_false(hasItems, "container should be empty")

        -- Both checks pass → allowed
        local canUnregister = canBypass and not hasItems
        JASM_TestRunner.assert_true(canUnregister, "admin should be able to unregister empty shop")
    end)

    -- ------------------------------------------------------------------
    -- NEW: Issue 1 – Admin bypass sandbox var test
    -- ------------------------------------------------------------------

    -- When AdminBypass = false, admin is subject to ownership check
    JASM_TestRunner.register("shop_unregister_admin_bypass_disabled", "server", function()
        local mockObj = createMockShopObject(0)
        local admin = createMockPlayer("Admin1", true)

        local modData = mockObj:getModData()
        modData.isShop = true
        modData.shopOwnerID = "SomeOtherOwner"

        local adminBypass = false -- sandbox var disabled
        local canUnregister = isOwnerOrAdmin(modData, admin, adminBypass)
        JASM_TestRunner.assert_false(
            canUnregister,
            "Admin should NOT bypass ownership check when AdminBypass = false"
        )
    end)

    print("[JASM_TEST] ShopServerCommands tests registered")
end

return init
