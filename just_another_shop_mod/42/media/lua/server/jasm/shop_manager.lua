local pz_lua_commons = require("pz_lua_commons_shared")
local pz_utils = require("pz_utils_shared")

local middleclass = pz_lua_commons.kikito.middleclass
local KUtilities = pz_utils.konijima.Utilities

---@class ShopManager
---@overload fun(): ShopManager
---@field shops table<string, boolean>
---@field initialize function
---@field registerShop function
---@field unregisterShop function
local ShopManager = middleclass("ShopManager")

function ShopManager:initialize()
	self.shops = {} -- Optional local cache of shop square IDs
end

-- self.shops[id] = true is not persistent, need to use modData

---Registers a container as a shop
---@param container ItemContainer
---@param ownerID string SteamID of the owner or "SYSTEM" for NPC shops
---@param shopName string|nil Optional name for the shop
function ShopManager:registerShop(container, ownerID, shopName)
	local parent = container:getParent()
	local modData = parent:getModData()
	modData.isShop = true
	modData.shopOwnerID = ownerID
	modData.shopName = shopName or "A Shop"

	local square = parent:getSquare()
	---@diagnostic disable-next-line: unnecessary-if
	if square then
		local id = KUtilities.SquareToString(square)
		self.shops[id] = true
	end
end

---Sets the price for an item type in a shop
---@param container ItemContainer
---@param itemType string Full type of the item to sell
---@param priceType string Full type of the currency item
---@param amount integer Amount of currency required
function ShopManager:setPrice(container, itemType, priceType, amount)
	local parent = container:getParent()
	local modData = parent:getModData()
	modData.shopPrices = modData.shopPrices or {}
	modData.shopPrices[itemType] = { type = priceType, count = amount }
	parent:transmitModData()
end

---Unregisters a container as a shop
---@param container ItemContainer
function ShopManager:unregisterShop(container)
	local parent = container:getParent()
	local modData = parent:getModData()
	modData.isShop = nil
	modData.shopOwnerID = nil
	modData.shopName = nil

	local square = parent:getSquare()
	---@diagnostic disable-next-line: unnecessary-if
	if square then
		local id = KUtilities.SquareToString(square)
		self.shops[id] = nil
	end
end

return ShopManager
