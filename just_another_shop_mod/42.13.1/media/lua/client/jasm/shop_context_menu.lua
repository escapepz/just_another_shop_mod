local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

local function onShopAction(worldobjects, playerObj, action, shopType)
	local containerObj = nil
	for _, obj in ipairs(worldobjects) do
		if obj:getContainer() then
			containerObj = obj
			break
		end
	end

	if not containerObj then
		return
	end

	local args = {
		x = containerObj:getX(),
		y = containerObj:getY(),
		z = containerObj:getZ(),
		index = containerObj:getObjectIndex(),
		shopType = shopType,
		action = action,
	}

	-- Sends command to server
	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
end

local function doShopContextMenu(player, context, worldobjects, test)
	if test then
		return
	end
	local playerObj = getSpecificPlayer(player)
	local isAdmin = KUtilities.IsPlayerAdmin(playerObj)

	local containerObj = nil
	for _, obj in ipairs(worldobjects) do
		if obj:getContainer() then
			containerObj = obj
			break
		end
	end
	if not containerObj then
		return
	end

	-- Player Shop Submenu
	local pOption = context:addOption("Player Shop", worldobjects, nil)
	local pMenu = ISContextMenu:getNew(context)
	context:addSubMenu(pOption, pMenu)
	pMenu:addOption("Register Shop", worldobjects, onShopAction, playerObj, "REGISTER", "PLAYER")
	pMenu:addOption("UnRegister Shop", worldobjects, onShopAction, playerObj, "UNREGISTER", "PLAYER")

	-- NPC Shop Submenu (Admin Only)
	if isAdmin then
		local nOption = context:addOption("NPC Shop", worldobjects, nil)
		local nMenu = ISContextMenu:getNew(context)
		context:addSubMenu(nOption, nMenu)
		nMenu:addOption("Register Shop", worldobjects, onShopAction, playerObj, "REGISTER", "SYSTEM")
		nMenu:addOption("UnRegister Shop", worldobjects, onShopAction, playerObj, "UNREGISTER", "SYSTEM")
	end
end

return doShopContextMenu
