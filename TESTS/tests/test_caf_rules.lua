--[[
    Offline CAF Rules Tests (Lua 5.1)
]]

-- Setup relative package paths for standalone execution
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
if testDir then
    package.path = testDir .. "?.lua;" .. package.path
end

local TestFramework = require("test_framework")
local MockPZ = require("mock_pz")

MockPZ.setupGlobals()

-- Create mock CAF context
local function createMockCAFContext(options)
    options = options or {}

    return {
        src = options.src or MockPZ.createItemContainer(),
        dest = options.dest or MockPZ.createItemContainer(),
        character = options.character or MockPZ.createIsoPlayer("TestPlayer", false),
        item = options.item or MockPZ.createInventoryItem("Base.Item", 1),
        flags = options.flags or { rejected = false, tradeAuthorized = false },
    }
end

-- Minimal Trade rule validation
local function tradeValidation(ctx)
    local srcParent = ctx.src:getParent()
    local modData = srcParent and srcParent:getModData() or nil

    -- Skip if not a shop or player is owner
    if not modData or not modData.isShop or ctx.character:getUsername() == modData.shopOwnerID then
        return
    end

    local itemType = ctx.item:getFullType()
    local priceConfig = modData.shopPrices and modData.shopPrices[itemType]

    if not priceConfig then
        return
    end

    local playerInv = ctx.character:getInventory()
    local priceCount = playerInv:getItemCount(priceConfig.type)

    if priceCount < priceConfig.count then
        ctx.flags.rejected = true
        ctx.flags.reason = "Missing: " .. priceConfig.count .. "x " .. priceConfig.type
        return
    end

    ctx.flags.tradeAuthorized = true
end

-- Minimal Protection rule
local function ruleShopProtection(ctx)
    local srcContainer = ctx.src
    local parent = srcContainer:getParent()

    local modData = parent and parent:getModData() or nil
    ---@diagnostic disable-next-line: unnecessary-if
    if modData and modData.isShop then
        local ownerID = modData.shopOwnerID
        local playerUsername = ctx.character:getUsername()

        -- Owner bypass
        if playerUsername == ownerID then
            return
        end

        -- Authorized trade bypass
        if ctx.flags.tradeAuthorized then
            return
        end

        -- Block customers
        ctx.flags.rejected = true
        ctx.flags.reason = "This item must be purchased."
    end
end

-- Minimal Audit rule
local function ruleShopAudit(ctx)
    local srcContainer = ctx.src
    local destContainer = ctx.dest

    local srcParent = srcContainer:getParent()
    local destParent = destContainer:getParent()

    local srcShop = srcParent and srcParent:getModData().isShop or false
    local destShop = destParent and destParent:getModData().isShop or false

    if srcShop or destShop then
        -- Would log, but we just verify it runs
        return
    end
end

-- Test: Trade rejects insufficient funds
TestFramework.test("CAFRules", "trade_insufficient_funds", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true
    srcParent.modData.shopOwnerID = "ShopOwner"
    srcParent.modData.shopPrices = {
        ["Base.Item"] = { type = "Base.Money", count = 100 },
    }

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local buyer = MockPZ.createIsoPlayer("Buyer", false)
    buyer:getInventory().getItemCount = function()
        return 50
    end -- Only 50, needs 100

    local ctx = createMockCAFContext({
        src = srcContainer,
        character = buyer,
        item = MockPZ.createInventoryItem("Base.Item", 1),
    })

    tradeValidation(ctx)

    TestFramework.assert_true(ctx.flags.rejected, "Should reject insufficient funds")
end)

-- Test: Trade allows sufficient funds
TestFramework.test("CAFRules", "trade_sufficient_funds", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true
    srcParent.modData.shopOwnerID = "ShopOwner"
    srcParent.modData.shopPrices = {
        ["Base.Item"] = { type = "Base.Money", count = 100 },
    }

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local buyer = MockPZ.createIsoPlayer("Buyer", false)
    buyer:getInventory().getItemCount = function()
        return 150
    end -- Has 150, needs 100

    local ctx = createMockCAFContext({
        src = srcContainer,
        character = buyer,
        item = MockPZ.createInventoryItem("Base.Item", 1),
    })

    tradeValidation(ctx)

    TestFramework.assert_true(ctx.flags.tradeAuthorized, "Should authorize sufficient trade")
    TestFramework.assert_false(ctx.flags.rejected, "Should not reject sufficient funds")
end)

-- Test: Protection rejects non-owner
TestFramework.test("CAFRules", "protection_rejects_non_owner", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true
    srcParent.modData.shopOwnerID = "ShopOwner"

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local ctx = createMockCAFContext({
        src = srcContainer,
        character = MockPZ.createIsoPlayer("Buyer", false),
    })

    ruleShopProtection(ctx)

    TestFramework.assert_true(ctx.flags.rejected, "Non-owner should be rejected")
end)

-- Test: Protection allows owner
TestFramework.test("CAFRules", "protection_allows_owner", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true
    srcParent.modData.shopOwnerID = "ShopOwner"

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local ctx = createMockCAFContext({
        src = srcContainer,
        character = MockPZ.createIsoPlayer("ShopOwner", false),
    })

    ruleShopProtection(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Owner should be allowed")
end)

-- Test: Protection allows authorized trade
TestFramework.test("CAFRules", "protection_allows_authorized_trade", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true
    srcParent.modData.shopOwnerID = "ShopOwner"

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local ctx = createMockCAFContext({
        src = srcContainer,
        character = MockPZ.createIsoPlayer("Buyer", false),
        flags = { rejected = false, tradeAuthorized = true },
    })

    ruleShopProtection(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Authorized trade should be allowed")
end)

-- Test: Audit rule runs on shop transfers
TestFramework.test("CAFRules", "audit_logs_shop_transfer", function()
    local srcParent = MockPZ.createIsoObject()
    srcParent.modData.isShop = true

    local srcContainer = MockPZ.createItemContainer()
    srcContainer:setParent(srcParent)

    local ctx = createMockCAFContext({
        src = srcContainer,
    })

    -- Should not error
    ruleShopAudit(ctx)
    TestFramework.assert_false(ctx.flags.rejected, "Audit should not reject")
end)

print("[OFFLINE TESTS] CAFRules tests loaded")
