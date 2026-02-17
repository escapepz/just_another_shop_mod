local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

-- local JASM_ShopView = require("jasm/entity_ui/shop_view")
local JASM_ShopView_Owner = require("jasm/entity_ui/shop_view_owner")

-- guard again non crate objects
local allowedCrates = { ["Base.Wood_Crate"] = true, ["Base.Metal_Crate"] = true }

---@param worldObjects IsoObject[]
---@param playerObj IsoPlayer
---@param action string
---@param shopType string
local function onShopAction(worldObjects, playerObj, action, shopType)
	local containerObj = nil
	for _, obj in ipairs(worldObjects) do
		---@diagnostic disable-next-line: unnecessary-if
		if obj:getContainer() then
			containerObj = obj
			break
		end
	end

	-- print(playerObj)

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

---@param worldObjects IsoObject[]
---@param playerObj IsoPlayer
---@param containerObj IsoObject
local function onOpenShopUI(worldObjects, playerObj, containerObj)
	-- local shopUI = JASM_ShopView:new(100, 100, 600, 400, playerObj, containerObj)
	-- shopUI:show()
		-- Example usage:
	local shopView = JASM_ShopView_Owner:new(0, 0, 800, 600, playerObj, containerObj)
	shopView:initialise()
	shopView:createChildren()
end

---@param playerIndex integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
---@param test boolean
local function DoShopContextMenu(playerIndex, context, worldObjects, test)
	if test then
		return
	end
	local playerObj = getSpecificPlayer(playerIndex)
	local isAdmin = KUtilities.IsPlayerAdmin(playerObj)

	---@type IsoObject|nil
	local containerObj = nil
	for _, obj in ipairs(worldObjects) do
		---@diagnostic disable-next-line: unnecessary-if
		if obj:getContainer() then
			containerObj = obj
			break
		end
	end
	if not containerObj then
		return
	end

	local modData = containerObj:getModData()
	local isShop = modData.isShop
	local shopType = modData.shopType
	local objName = containerObj:getObjectName()

	local entityDisplayName = containerObj:getEntityDisplayName() or "Unknown"

	local entityFullTypeDebug = containerObj:getEntityFullTypeDebug()
	if not entityFullTypeDebug then
		return
	end

	-- print(containerObj:getObjectName()) -- Thumpable
	-- print(containerObj:getName()) -- Wood_Crate_Lvl1
	-- print(containerObj:getObjectIndex())
	-- print(containerObj:getX())
	-- print(containerObj:getY())
	-- print(containerObj:getZ())
	-- print(containerObj:getEntityDisplayName())
	-- print(containerObj:getEntityFullTypeDebug())

	-- guard again non thumpable objects
	if objName ~= "Thumpable" then
		return
	end

	-- 1. Try to capture everything before "_Lvl"
	-- 2. If "_Lvl" isn't found, the match returns nil
	-- 3. The "or fullType" kicks in and uses the original string
	local baseName = string.match(entityFullTypeDebug, "(.-)_Lvl%d+") or entityFullTypeDebug

	---@diagnostic disable-next-line: unnecessary-if
	if not allowedCrates[baseName] then
		return
	end

	-- Main JASM Menu
	local jOption = context:addOption("JASM Shop", worldObjects, nil)
	local jMenu = ISContextMenu:getNew(context)
	context:addSubMenu(jOption, jMenu)

	---@diagnostic disable-next-line: unnecessary-if
	if isShop then
		jMenu:addOption("Open Shop UI", worldObjects, onOpenShopUI, playerObj, containerObj)
	end

	-- Player Shop Submenu
	if not isShop or shopType == "PLAYER" then
		local pOption = jMenu:addOption("Player Shop", worldObjects, nil)
		local pMenu = ISContextMenu:getNew(jMenu)
		jMenu:addSubMenu(pOption, pMenu)

		if not isShop then
			pMenu:addOption(
				"Register Shop [" .. entityDisplayName .. "]",
				worldObjects,
				onShopAction,
				playerObj,
				"REGISTER",
				"PLAYER"
			)
		else
			pMenu:addOption(
				"UnRegister Shop [" .. entityDisplayName .. "]",
				worldObjects,
				onShopAction,
				playerObj,
				"UNREGISTER",
				"PLAYER"
			)
		end
	end

	-- NPC Shop Submenu (Admin Only)
	if isAdmin then
		if not isShop or shopType == "SYSTEM" then
			local nOption = jMenu:addOption("NPC Shop", worldObjects, nil)
			local nMenu = ISContextMenu:getNew(jMenu)
			jMenu:addSubMenu(nOption, nMenu)

			if not isShop then
				nMenu:addOption(
					"Register Shop  [" .. entityDisplayName .. "]",
					worldObjects,
					onShopAction,
					playerObj,
					"REGISTER",
					"SYSTEM"
				)
			else
				nMenu:addOption(
					"UnRegister Shop [" .. entityDisplayName .. "]",
					worldObjects,
					onShopAction,
					playerObj,
					"UNREGISTER",
					"SYSTEM"
				)
			end
		end
	end
end

return DoShopContextMenu
