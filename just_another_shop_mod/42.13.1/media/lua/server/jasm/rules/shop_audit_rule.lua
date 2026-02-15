local ZUL = require("ZUL")

local logger = ZUL.new("ShopSystem")

---@param ctx CAF.Context
local ruleShopAudit = function(ctx)
	local srcContainer = ctx.src
	local destContainer = ctx.dest
	local player = ctx.character
	local item = ctx.item

	local srcShop = srcContainer:getParent():getModData().isShop
	local destShop = destContainer:getParent():getModData().isShop

	---@diagnostic disable-next-line: unnecessary-if
	if srcShop or destShop then
		logger:info("Transfer recorded", {
			player = player:getUsername(),
			item = item:getFullType(),
			from = srcShop and "Shop" or "Inventory",
			to = destShop and "Shop" or "Inventory",
		})
	end
end

return ruleShopAudit
