local ZUL = require("ZUL")
local pz_utils = require("pz_utils_shared")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("ShopServer")

local function OnClientCommand(module, command, player, args)
	if module ~= "JASM_ShopManager" or command ~= "ManageShop" then
		return
	end

	local square = getSquare(args.x, args.y, args.z)
	if not square then
		return
	end

	local containerObj = square:getObjects():get(args.index)
	if not containerObj or not containerObj:getContainer() then
		return
	end

	local modData = containerObj:getModData()

	if args.action == "REGISTER" then
		modData.isShop = true
		modData.shopType = args.shopType
		modData.shopOwnerID = player:getUsername()

		logger:info("Shop Registered", { type = args.shopType, owner = modData.shopOwnerID })
	elseif args.action == "UNREGISTER" then
		modData.isShop = nil
		modData.shopType = nil
		modData.shopOwnerID = nil

		logger:info("Shop Unregistered", { x = args.x, y = args.y })
	end

	-- Persist and Sync to all clients
	containerObj:transmitModData()

	-- Optional: Explicit sync notification back to the player
	KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "UpdateSuccess", { action = args.action })
end

return OnClientCommand
