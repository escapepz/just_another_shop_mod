local ZUL = require("zul")

local logger = ZUL.new("just_another_shop_mod")

---@param ctx CAF.Context
local RuleShopAudit = function(ctx)
    local srcContainer = ctx.src
    local destContainer = ctx.dest
    local player = ctx.character
    local item = ctx.item

    -- floor can be nil (no parent)
    local srcParent = srcContainer:getParent()
    local destParent = destContainer:getParent()

    local srcType = srcContainer:getType()
    local destType = destContainer:getType()

    local srcShop = false

    if srcParent then
        srcShop = srcParent:getModData().isShop
    end
    local destShop = false

    if destParent then
        destShop = destParent:getModData().isShop
    end

    if srcShop or destShop then
        logger:info("Transfer recorded", {
            player = player:getUsername(),
            item = item:getFullType(),
            from = srcType .. "[" .. (srcShop and "Shop" or "Inventory") .. "]",
            to = destType .. "[" .. (destShop and "Shop" or "Inventory") .. "]",
        })
    end
end

return RuleShopAudit
