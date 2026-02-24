local ZUL = require("ZUL")
local logger = ZUL.new("JASM")

local ShopTrade = {}

---@param ctx CAF.Context
function ShopTrade.Validation(ctx)
    local srcParent = ctx.src:getParent()
    local modData = srcParent and srcParent:getModData() or nil

    -- Only trigger if source is a shop and player is NOT the owner
    if not modData or not modData.isShop or ctx.character:getUsername() == modData.shopOwnerID then
        return
    end

    local itemType = ctx.item:getFullType()
    local priceConfig = modData.shopPrices and modData.shopPrices[itemType]

    -- If no price is set, we default to the Protection Rule (lockdown)
    -- So we just return, and Protection Rule will see `tradeAuthorized` is nil/false and reject it.
    if not priceConfig then
        return
    end

    local playerInv = ctx.character:getInventory()
    local priceCount = playerInv:getItemCount(priceConfig.type)

    -- 1. VALIDATION
    if priceCount < priceConfig.count then
        ctx.flags.rejected = true
        ctx.flags.reason = "Missing: " .. priceConfig.count .. "x " .. priceConfig.type
        return
    end

    -- If valid, authorize trade so Protection doesn't block it
    ctx.flags.tradeAuthorized = true
end

---@param ctx CAF.Context
function ShopTrade.Payment(ctx)
    local srcParent = ctx.src:getParent()
    local modData = srcParent and srcParent:getModData() or nil

    -- Validation already checked ownership/shop status, but we re-check for safety
    if not modData or not modData.isShop or ctx.character:getUsername() == modData.shopOwnerID then
        return
    end

    local itemType = ctx.item:getFullType()
    local priceConfig = modData.shopPrices and modData.shopPrices[itemType]

    if not priceConfig then
        return
    end

    local playerInv = ctx.character:getInventory()
    local srcContainer = ctx.src

    -- 2. PAYMENT EXECUTION
    -- Remove from player
    for i = 1, priceConfig.count do
        playerInv:RemoveOneOf(priceConfig.type)
    end

    -- Add to shop
    -- We use AddItems to potentially handle multiple items more efficiently if needed,
    -- but loop AddItem is standard for simple transfers.
    -- However, we should preserve the item instance properties?
    -- No, currency is usually fungible (Nails, etc).
    for i = 1, priceConfig.count do
        srcContainer:AddItem(priceConfig.type)
    end

    logger:info("Trade Executed", {
        buyer = ctx.character:getUsername(),
        item = itemType,
        price = priceConfig.count .. "x " .. priceConfig.type,
    })
end

return ShopTrade
