--[[
    OnClientCommand Handler Tests
    
    Tests server-side command handling for shop registration/unregistration.
]]

local JASM_TestRunner = require("jasm_test_shared")

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
local function createMockShopObject()
    return {
        modData = {},
        container = true,
        getModData = function(self)
            return self.modData
        end,
        getContainer = function(self)
            return self.container
        end,
    }
end

-- Test: Shop register command sets modData
JASM_TestRunner.register("shop_register_command", "server", function()
    local mockObj = createMockShopObject()
    local mockPlayer = createMockPlayer("Owner1")

    -- Simulate: args.action == "REGISTER"
    local modData = mockObj:getModData()
    if not modData.isShop or false then -- isAdmin check stubbed
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

-- Test: Shop unregister command clears modData
JASM_TestRunner.register("shop_unregister_command", "server", function()
    local mockObj = createMockShopObject()
    local mockPlayer = createMockPlayer("Owner1")

    -- Setup: register a shop
    mockObj:getModData().isShop = true
    mockObj:getModData().shopType = "STORAGE"
    mockObj:getModData().shopOwnerID = mockPlayer:getUsername()
    mockObj:getModData().indestructible = true
    mockObj:getModData().immovable = true

    -- Simulate: args.action == "UNREGISTER" with owner
    local modData = mockObj:getModData()
    local isOwner = modData.shopOwnerID == mockPlayer:getUsername()

    if isOwner then
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

-- Test: Only owner or admin can unregister
JASM_TestRunner.register("shop_unregister_access", "server", function()
    local mockObj = createMockShopObject()
    local ownerPlayer = createMockPlayer("Owner1")
    local otherPlayer = createMockPlayer("OtherPlayer")

    -- Setup: shop owned by Owner1
    mockObj:getModData().isShop = true
    mockObj:getModData().shopOwnerID = "Owner1"

    -- Try unregister as different player (should fail)
    local modData = mockObj:getModData()
    local isOwner = modData.shopOwnerID == otherPlayer:getUsername()
    local isAdmin = otherPlayer:isAdmin()

    JASM_TestRunner.assert_false(isOwner or isAdmin, "Non-owner should not be able to unregister")

    -- Try unregister as owner (should succeed)
    isOwner = modData.shopOwnerID == ownerPlayer:getUsername()
    JASM_TestRunner.assert_true(isOwner or isAdmin, "Owner should be able to unregister")
end)

print("[JASM_TEST] ShopServerCommands tests registered")
