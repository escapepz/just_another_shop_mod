local ZUL = require("ZUL")

local logger = ZUL.new("ShopSystem")

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
	---@diagnostic disable-next-line: unnecessary-if
	if srcParent then
		srcShop = srcParent:getModData().isShop
	end
	local destShop = false
	---@diagnostic disable-next-line: unnecessary-if
	if destParent then
		destShop = destParent:getModData().isShop
	end

	---@diagnostic disable-next-line: unnecessary-if
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
