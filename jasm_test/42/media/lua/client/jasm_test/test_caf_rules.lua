---@diagnostic disable: param-type-mismatch, global-in-non-module

local JASM_TestRunner = require("jasm_test_shared")

---Mock CAF context object
---@param options table?
---@return any
local function createMockCAFContext(options)
    options = options or {}
    local item = (
        options.item
        or {
            getFullType = function()
                return options.itemType or "Base.Item"
            end,
        }
    )

    local flagsInput = options.flags or {}

    -- Provide a default square if not set
    local squareX = options.squareX or 0
    local squareY = options.squareY or 0
    local squareZ = options.squareZ or 0

    local defaultSquare = {
        getX = function()
            return squareX
        end,
        getY = function()
            return squareY
        end,
        getZ = function()
            return squareZ
        end,
    }

    local ctx = {
        src = (options.src or {
            getParent = function()
                return options.srcParent
            end,
            getType = function()
                return "container"
            end,
        }),
        dest = (options.dest or {
            getParent = function()
                return options.destParent
            end,
            getType = function()
                return "container"
            end,
        }),
        character = (options.character or {
            getUsername = function()
                return options.username or "TestPlayer"
            end,
            getInventory = function()
                return options.inventory or {}
            end,
        }),
        item = item,
        flags = {
            rejected = flagsInput.rejected or false,
            reason = flagsInput.reason or "",
            adminOverride = flagsInput.adminOverride or false,
        },
        result = (options.result or item),
    }

    ---@diagnostic disable-next-line: inject-field
    ctx.flags.tradeAuthorized = flagsInput.tradeAuthorized or false

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

        -- Mock Square and ShopManager
        local mockSquare = createMockSquare(0, 0, 0)
        local srcParent = createMockParent(true, "ShopOwner", {})
        srcParent.getSquare = function()
            return mockSquare
        end

        local originalGetLock = _G.JASM_ShopManager.getShopLock
        _G.JASM_ShopManager.getShopLock = function()
            return "Buyer"
        end -- Locked by someone else

        local ctx = createMockCAFContext({
            srcParent = srcParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        -- Cleanup
        _G.JASM_ShopManager.getShopLock = originalGetLock

        JASM_TestRunner.assert_true(
            ctx.flags.rejected,
            "Owner should be rejected from taking items if shop is locked by someone else"
        )
    end)

    -- Test: Protection rule allows owner if shop is locked (Give/Restock)
    JASM_TestRunner.register("caf_protection_owner_locked_give", "client", function()
        local RuleShopProtection = require("just_another_shop_mod/rules/caf/shop_protection_rule")

        -- Mock Square and ShopManager
        local mockSquare = createMockSquare(0, 0, 0)
        local destParent = createMockParent(true, "ShopOwner", {})
        destParent.getSquare = function()
            return mockSquare
        end

        local originalGetLock = _G.JASM_ShopManager.getShopLock
        _G.JASM_ShopManager.getShopLock = function()
            return "Buyer"
        end -- Locked by someone else

        local ctx = createMockCAFContext({
            destParent = destParent,
            username = "ShopOwner",
        })

        RuleShopProtection(ctx)

        -- Cleanup
        _G.JASM_ShopManager.getShopLock = originalGetLock

        JASM_TestRunner.assert_false(
            ctx.flags.rejected,
            "Owner should be allowed to restock even if shop is locked"
        )
    end)

    print("[JASM_TEST] CAF Rules tests registered")
end

return init
