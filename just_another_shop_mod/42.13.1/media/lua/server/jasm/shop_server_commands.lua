local ZUL = require("ZUL")
local pz_utils = require("pz_utils_shared")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("ShopServer")

-- Shops are protected by two main mechanisms:
-- 1. When shops are placed, shop:setIsThumpable(false) prevents zombies from targeting and damaging them.
-- 2. Block sledgehammer tool (ISDestroyCursorPatch.lua):
--    The canDestroy() function checks if an object's sprite name contains
--    either "npcshop_" or "playershop_" prefixes and blocks destruction for non-admin players.
--    Admins can still destroy shops since the patch checks if not (isAdmin()) first.
-- 3. Block Dismantle ?

---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
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

	-- used for disable zed target hit
	local thumpable = square:getThumpable(false)
	local thumpableN = square:getThumpable(true)

	local modData = containerObj:getModData()

	if args.action == "REGISTER" then
		modData.isShop = true
		modData.shopType = args.shopType
		modData.shopOwnerID = player:getUsername()

		---@diagnostic disable-next-line: unnecessary-if
		if thumpable then
			thumpable:setIsThumpable(false)
		end

		---@diagnostic disable-next-line: unnecessary-if
		if thumpableN then
			thumpableN:setIsThumpable(false)
		end

		logger:info("Shop Registered", { type = args.shopType, owner = modData.shopOwnerID })
	elseif args.action == "UNREGISTER" then
		modData.isShop = nil
		modData.shopType = nil
		modData.shopOwnerID = nil

		---@diagnostic disable-next-line: unnecessary-if
		if thumpable then
			thumpable:setIsThumpable(true)
		end

		---@diagnostic disable-next-line: unnecessary-if
		if thumpableN then
			thumpableN:setIsThumpable(true)
		end

		logger:info("Shop Unregistered", { x = args.x, y = args.y })
	elseif args.action == "SET_PRICE" then
		_G.JASM_ShopManager:setPrice(containerObj:getContainer(), args.itemType, args.priceType, args.count)
		logger:info("Price Set", {
			shop = modData.shopName,
			item = args.itemType,
			price = args.count .. "x " .. args.priceType,
		})
	elseif args.action == "BUY" then
		local shopContainer = containerObj:getContainer()
		local prices = modData.shopPrices or {}
		local priceInfo = prices[args.itemType]

		if not priceInfo then
			logger:error("Item not for sale", { item = args.itemType })
			return
		end

		local item = shopContainer:getFirstType(args.itemType)
		if not item then
			logger:error("Item out of stock", { item = args.itemType })
			return
		end

		local playerInv = player:getInventory()
		local playerFunds = playerInv:getItemCount(priceInfo.type)
		if playerFunds < priceInfo.count then
			logger:error(
				"Insufficient funds",
				{ player = player:getUsername(), has = playerFunds, needs = priceInfo.count }
			)
			return
		end

		-- Process Transaction
		for i = 1, priceInfo.count do
			local fundItem = playerInv:getFirstType(priceInfo.type)
			---@diagnostic disable-next-line: unnecessary-if
			if fundItem then
				playerInv:Remove(fundItem)
			end
		end
		shopContainer:Remove(item)
		playerInv:AddItem(item)

		-- Add payment to shop container
		for i = 1, priceInfo.count do
			shopContainer:AddItem(priceInfo.type)
		end

		logger:info("Purchase Successful", {
			player = player:getUsername(),
			item = args.itemType,
			price = priceInfo.count .. "x " .. priceInfo.type,
		})
	end

	-- Persist and Sync to all clients
	containerObj:transmitModData()

	-- Optional: Explicit sync notification back to the player
	KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "UpdateSuccess", { action = args.action })
end

return OnClientCommand
