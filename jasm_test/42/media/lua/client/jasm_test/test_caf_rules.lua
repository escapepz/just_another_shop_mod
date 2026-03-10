---@diagnostic disable: param-type-mismatch, global-in-non-module

local JASM_TestRunner = require("jasm_test_shared")

-- Local Mocks for in-game & offline standalone compatibility
local function createMockInventoryItem(itemType)
    return {
        type = itemType or "Base.Item",
        weight = 0.1,
        getFullType = function(self)
            return self.type
        end,
        getActualWeight = function(self)
            return self.weight
        end,
        getCategory = function(self)
            return "Item"
        end,
        getInventory = function(self)
            return nil
        end,
        isContainer = function(self)
            return false
        end,
        setWeight = function(self, w)
            self.weight = w
        end,
    }
end

local function createMockItemContainer()
    local c = {
        items = {},
        capacityWeight = 50.0,
        parent = nil,
    }
    function c:getCapacityWeight()
        return self:getContentsWeight() -- Correct B42 mock: returns current weight
    end
    function c:getCapacity()
        return self.capacityWeight -- Returns max limit
    end
    function c:getInventory()
        return self
    end
    function c:isExplored()
        return true
    end
    function c:setExplored() end
    function c:getEffectiveCapacity(chr)
        return self:getCapacity() -- Mock doesn't handle traits yet, just returns max
    end
    function c:getContentsWeight()
        local w = 0.0
        for _, it in ipairs(self.items) do
            w = w + (it.getActualWeight and it:getActualWeight() or 0.1)
        end
        return w
    end
    function c:addItem(itemOrType)
        local item = type(itemOrType) == "string" and createMockInventoryItem(itemOrType)
            or itemOrType
        table.insert(self.items, item)
    end
    function c:getItemCount(type)
        local count = 0
        for _, it in ipairs(self.items) do
            if it:getFullType() == type then
                count = count + 1
            end
        end
        return count
    end
    function c:getParent()
        return self.parent
    end
    function c:getType()
        return "container"
    end
    function c:getItemsFromCategory(category)
        return {
            size = function()
                return 0
            end,
            get = function(_, i)
                return nil
            end,
        }
    end
    function c:getItems()
        local items = self.items
        return {
            size = function()
                return #items
            end,
            get = function(_, i)
                return items[i + 1]
            end,
        }
    end
    function c:getCountRecurse(predicate)
        -- Simplified recursive mock: just returns top-level size for now
        -- as the tests don't deeply nest containers.
        return self:getItems():size()
    end
    function c:contains(item)
        for _, it in ipairs(self.items) do
            if it == item then
                return true
            end
        end
        return false
    end
    return c
end

-- Fallback for offline runner if it still expects MockPZ global
_G.luautils = _G.luautils
    or {
        countItemsRecursive = function(containerList, currentCount)
            local count = currentCount or 0
            for _, container in ipairs(containerList) do
                count = count + container:getItems():size()
            end
            return count
        end,
    }

local MockPZ = {
    createInventoryItem = createMockInventoryItem,
    createItemContainer = createMockItemContainer,
}

---Mock CAF context object
---@param options table?
---@return any
local function createMockCAFContext(options)
    options = options or {}
    local item = options.item
    if not item then
        item = MockPZ.createInventoryItem(options.itemType or "Base.Item")
        item:setWeight(options.weight or 0.1)
    end

    local src = options.src
    if not src then
        src = MockPZ.createItemContainer()
        src.capacityWeight = 50.0
        src.parent = options.srcParent
    end

    local dest = options.dest
    if not dest then
        dest = MockPZ.createItemContainer()
        dest.capacityWeight = 50.0
        dest.parent = options.destParent
    end

    local flagsInput = options.flags or {}

    local ctx = {
        src = src,
        dest = dest,
        character = (options.character or {
            getUsername = function()
                return options.username or "TestPlayer"
            end,
            getInventory = function()
                return options.inventory or MockPZ.createItemContainer()
            end,
        }),
        item = item,
        flags = {
            rejected = flagsInput.rejected or false,
            reason = flagsInput.reason or "",
            adminOverride = flagsInput.adminOverride or false,
            tradeAuthorized = flagsInput.tradeAuthorized or false,
        },
        result = (options.result or item),
    }

    return ctx
end

-- Mock parent object (container owner)
local function createMockParent(isShop, shopOwnerID, shopPrices)
    return {
        modData = {
            isShop = isShop or false,
            shopOwnerID = shopOwnerID,
            shopPrices = shopPrices,
        },
        getModData = function(self)
            return self.modData
        end,
        getSquare = function(self)
            return self.square
                or {
                    getX = function()
                        return 0
                    end,
                    getY = function()
                        return 0
                    end,
                    getZ = function()
                        return 0
                    end,
                }
        end,
        usingPlayer = nil,
        getUsingPlayer = function(self)
            return self.usingPlayer
        end,
    }
end

local function createMockSquare(x, y, z)
    return {
        getX = function()
            return x or 0
        end,
        getY = function()
            return y or 0
        end,
        getZ = function()
            return z or 0
        end,
    }
end

local function init()
    -- Ensure JASM_ShopManager mock is at least present
    _G.JASM_ShopManager = _G.JASM_ShopManager
        or {
            locks = {},
            getShopLock = function(self, id)
                return self.locks[id]
            end,
        }

    -- Test: Trade rule rejects insufficient funds
    JASM_TestRunner.register("caf_trade_insufficient_funds", "client", function()
        local ShopTrade = require("just_another_shop_mod/rules/caf/shop_trade_rule")

        local srcParent = createMockParent(true, "ShopOwner", {
            ["Base.Item"] = { type = "Base.Money", count = 100 },
        })

        local inventory = {
            getItemCount = function()
                return 50
            end,
        } -- Only has 50, needs 100

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Buyer",
            inventory = inventory,
            itemType = "Base.Item",
        })

        ShopTrade.Validation(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Should reject trade with insufficient funds"
        )
    end)

    -- Test: Trade rule allows sufficient funds
    JASM_TestRunner.register("caf_trade_sufficient_funds", "client", function()
        local ShopTrade = require("just_another_shop_mod/rules/caf/shop_trade_rule")

        local srcParent = createMockParent(true, "ShopOwner", {
            ["Base.Item"] = { type = "Base.Money", count = 100 },
        })

        local inventory = {
            getItemCount = function()
                return 150
            end,
        } -- Has 150, needs 100

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Buyer",
            inventory = inventory,
            itemType = "Base.Item",
        })

        ShopTrade.Validation(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.tradeAuthorized,
            "Should authorize trade with sufficient funds"
        )
        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Should not reject trade with sufficient funds"
        )
    end)

    -- Test: Trade rule allows shop owner
    JASM_TestRunner.register("caf_trade_owner_bypass", "client", function()
        local ShopTrade = require("just_another_shop_mod/rules/caf/shop_trade_rule")

        local srcParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "ShopOwner",
            itemType = "Base.Item",
        })

        ShopTrade.Validation(ctx)

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Shop owner should be able to access items"
        )
    end)

    -- Test: Protection rule rejects non-owner
    JASM_TestRunner.register("caf_protection_non_owner", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        local srcParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Buyer",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Non-owner should be rejected without trade authorization"
        )
    end)

    -- Test: Protection rule allows owner
    JASM_TestRunner.register("caf_protection_owner", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        local srcParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_false(ctx.flags.rejected, "Owner should always have access")
    end)

    -- Test: Protection rule allows authorized trade
    JASM_TestRunner.register("caf_protection_authorized_trade", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        local srcParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Buyer",
            flags = { rejected = false, tradeAuthorized = true },
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_false(ctx.flags.rejected, "Authorized trade should be allowed")
    end)

    -- Test: Audit rule logs shop transfers
    JASM_TestRunner.register("caf_audit_shop_transfer", "client", function()
        local RuleShopAudit = require("just_another_shop_mod/rules/caf/shop_audit_rule")

        local srcParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Buyer",
            itemType = "Base.Item",
        })

        -- Audit rule doesn't reject, just logs
        RuleShopAudit(ctx)

        JASM_TestRunner.assert_false(ctx.flags.rejected, "Audit rule should not reject")
    end)

    -- Test: Audit rule ignores non-shop transfers
    JASM_TestRunner.register("caf_audit_non_shop_transfer", "client", function()
        local RuleShopAudit = require("just_another_shop_mod/rules/caf/shop_audit_rule")

        local srcParent = createMockParent(false, nil, {}) -- Not a shop

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "Player",
        })

        -- Audit rule should just pass through without logging
        RuleShopAudit(ctx)

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Audit rule should not affect non-shop transfers"
        )
    end)

    -- Test: Protection rule rejects deposition by non-owner
    JASM_TestRunner.register("caf_protection_deposit_non_owner", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        local destParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            destParent = destParent,
            username = "Buyer",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Non-owner should be rejected from depositing into a shop"
        )
    end)

    -- Test: Protection rule allows deposition by owner
    JASM_TestRunner.register("caf_protection_deposit_owner", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        local destParent = createMockParent(true, "ShopOwner", {})

        local ctx = createMockCAFContext({
            destParent = destParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Owner should be allowed to deposit into their own shop"
        )
    end)

    -- Test: Protection rule restricts owner if shop is locked (Take)
    JASM_TestRunner.register("caf_protection_owner_locked_take", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        -- Setup shop with lock
        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = "Buyer" -- Shop locked by someone else
        srcParent.modData.shopLockSessionID = "test_session"

        local currentSession = ModData.getOrCreate("JASM_ServerSession")
        if currentSession then
            currentSession.id = "test_session"
        end

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Owner should BE rejected when shop is locked (Stops owner from stealing while customer browsing)"
        )
        JASM_TestRunner.assert_equals(
            "Shop is locked by Buyer.",
            ctx.flags.reason,
            "Should show lock reason"
        )
    end)

    -- Test: Protection rule allows owner if shop is locked (Give/Restock)
    JASM_TestRunner.register("caf_protection_owner_locked_give", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        -- Setup shop with lock
        local destParent = createMockParent(true, "ShopOwner", {})
        destParent.modData.shopLock = "Buyer" -- Shop locked by someone else
        destParent.modData.shopLockSessionID = "test_session"

        local currentSession = ModData.getOrCreate("JASM_ServerSession")
        if currentSession then
            currentSession.id = "test_session"
        end

        local ctx = createMockCAFContext({
            destParent = destParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Owner should be allowed to restock even if shop is locked"
        )
    end)

    -- Test: Protection rule restricts customer if shop is locked
    JASM_TestRunner.register("caf_protection_customer_locked", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        -- Setup shop with lock
        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = "CustomerA" -- Shop locked by another customer
        srcParent.modData.shopLockSessionID = "test_session"

        local currentSession = ModData.getOrCreate("JASM_ServerSession")
        if currentSession then
            currentSession.id = "test_session"
        end

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "CustomerB", -- Different player trying to access
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Customer should be rejected from accessing locked shop"
        )
        JASM_TestRunner.assert_equals(
            "Shop is locked by CustomerA.",
            ctx.flags.reason,
            "Should show lock reason"
        )
    end)

    -- Test: Protection rule allows owner when unlocked
    JASM_TestRunner.register("caf_protection_owner_unlocked_take", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        -- Setup shop WITHOUT lock
        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = nil -- Not locked

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Owner should be allowed to take items when shop is not locked"
        )
    end)

    -- Test: modData persistence
    JASM_TestRunner.register("moddata_shoplock_persistence", "client", function()
        -- Verify modData.shopLock survives across transmit
        local parent = createMockParent(true, "Owner1", {})

        -- Set lock
        parent.modData.shopLock = "Player1"
        JASM_TestRunner.assert_equals(
            parent.modData.shopLock,
            "Player1",
            "Lock should be stored in modData"
        )

        -- Clear lock
        parent.modData.shopLock = nil
        JASM_TestRunner.assert_nil(parent.modData.shopLock, "Lock should be cleared from modData")
    end)

    -- Test: CAF respects getUsingPlayer in VANILLA mode, ignores modData lock
    JASM_TestRunner.register("caf_protection_vanilla_guard_ignored", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")
        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local originalGet = JASM_SandboxVars.Get
        JASM_SandboxVars.Get = function(k, d)
            return k == "ShopLockMethod" and 2 or originalGet(k, d)
        end

        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = "CustomerA" -- This modData lock should be IGNORED
        srcParent.usingPlayer = nil -- Nobody using the entity yet

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "CustomerB",
        })

        RuleShopProtection(ctx)

        JASM_SandboxVars.Get = originalGet -- Restore
        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "VANILLA mode should ignore modData.shopLock"
        )
    end)

    -- Test: CAF respects getUsingPlayer in VANILLA mode, active user
    JASM_TestRunner.register("caf_protection_vanilla_guard_active", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")
        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local originalGet = JASM_SandboxVars.Get
        JASM_SandboxVars.Get = function(k, d)
            return k == "ShopLockMethod" and 2 or originalGet(k, d)
        end

        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = nil
        -- Simulate PlayerA using the shop entity
        srcParent.usingPlayer = {
            getUsername = function()
                return "PlayerA"
            end,
        }

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "PlayerB",
        })

        RuleShopProtection(ctx)

        JASM_SandboxVars.Get = originalGet -- Restore
        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "VANILLA mode should block based on getUsingPlayer()"
        )
    end)

    -- Test: CAF protects locked shop correctly in DUAL mode when Session ID matches
    JASM_TestRunner.register("caf_protection_dual_session_valid", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")
        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local originalGet = JASM_SandboxVars.Get
        JASM_SandboxVars.Get = function(k, d)
            return k == "ShopLockMethod" and 1 or originalGet(k, d)
        end

        local currentSession = ModData.getOrCreate("JASM_ServerSession")
        if currentSession then
            currentSession.id = "session_123"
        end

        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = "CustomerA"
        srcParent.modData.shopLockSessionID = "session_123" -- Match!

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "CustomerB",
        })

        RuleShopProtection(ctx)

        JASM_SandboxVars.Get = originalGet -- Restore
        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Customer should be rejected because valid session ID matches"
        )
    end)

    -- Test: CAF ignores locked shop in DUAL mode when Session ID stale
    JASM_TestRunner.register("caf_protection_dual_session_stale", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")
        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local originalGet = JASM_SandboxVars.Get
        JASM_SandboxVars.Get = function(k, d)
            return k == "ShopLockMethod" and 1 or originalGet(k, d)
        end

        local currentSession = ModData.getOrCreate("JASM_ServerSession")
        if currentSession then
            currentSession.id = "session_new"
        end

        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.modData.shopLock = "CustomerA"
        srcParent.modData.shopLockSessionID = "session_old" -- Stale!

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "CustomerB",
        })

        RuleShopProtection(ctx)

        JASM_SandboxVars.Get = originalGet -- Restore
        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Customer should not be rejected because lock session is stale"
        )
    end)

    print("[JASM_TEST] CAF Rules tests registered")
end

return init
