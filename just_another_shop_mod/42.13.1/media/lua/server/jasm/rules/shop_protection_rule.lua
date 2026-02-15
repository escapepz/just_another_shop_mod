local ZUL = require("ZUL")
local pz_utils = require("pz_utils_shared")

local logger = ZUL.new("ShopSystem")

local SandboxVarsModule = pz_utils.escape.SandboxVarsModule
local KUtilities = pz_utils.konijima.Utilities

local SSandboxVars = SandboxVarsModule.Create("JASM", { AdminBypass = false })

---@param ctx CAF.Context
local RuleShopProtection = function(ctx)
	local srcContainer = ctx.src
	local player = ctx.character
	local item = ctx.item

	-- 1. Check if the source is a Shop
	local modData = srcContainer:getParent():getModData()
	if modData.isShop then
		local ownerID = modData.shopOwnerID
		local playerUsername = player:getUsername()

		-- Rule: Owners can take anything
		if playerUsername == ownerID then
			logger:debug("Owner access granted", {
				player = player:getUsername(),
				shop = modData.shopName,
			})
			return -- No rejection
		end

		-- Rule: Admin bypass (check sandbox option)
		local adminBypass = SSandboxVars.Get("AdminBypass", false)
		if adminBypass and KUtilities.IsPlayerAdmin(player) then
			logger:info("Admin bypass access", {
				player = player:getUsername(),
				item = item:getFullType(),
			})
			return -- No rejection
		end

		-- Rule: Customers are blocked
		ctx.flags.rejected = true
		ctx.flags.reason = "This item must be purchased."

		logger:info("Purchase required", {
			player = player:getUsername(),
			item = item:getFullType(),
			shop = modData.shopName,
		})
	end
end

return RuleShopProtection
