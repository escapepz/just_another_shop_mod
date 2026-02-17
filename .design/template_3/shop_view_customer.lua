-- ============================================================================
-- shop_view_customer.lua (Implementation)
-- Template 3: Customer View - Advanced Trade Discovery
-- ============================================================================
-- Layout: 60/40 split
-- Left (60%): Product grid (ISTiledIconListBox)
-- Right (40%): Details panel with trade selector + affordability
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("Entity/ISUI/CraftRecipe/ISTiledIconListBox")
require("Entity/ISUI/Controls/ISTableLayout")

-- Custom components
require("path/to/ESC_TradeSelector")
require("path/to/ESC_AffordabilityPanel")
require("path/to/ESC_TradeCard")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@class JASM_ShopView_Customer : ISPanel
---@field player IsoPlayer Player instance
---@field entity IsoObject Shop entity
---@field layout ISTableLayout Root layout (60/40 split)
---@field productGrid ISTiledIconListBox Product grid
---@field detailsPanel ISPanel Details panel (right column)
---@field detailsLayout ISTableLayout Details vertical layout
---@field selectedProduct table Currently selected product
---@field availableTrades table[] All trades for selected product
---@field selectedTradeIndex number Currently selected trade (1-based)
local JASM_ShopView_Customer = ISPanel:derive("JASM_ShopView_Customer")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function JASM_ShopView_Customer:initialise()
	ISPanel.initialise(self)
end

function JASM_ShopView_Customer:new(x, y, width, height, player, entity)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.player = player
	o.entity = entity
	
	-- State
	o.selectedProduct = nil
	o.availableTrades = {}
	o.selectedTradeIndex = 1
	
	-- Product data
	o.dataList = ArrayList.new()
	
	return o
end

-- ============================================================================
-- LAYOUT CREATION
-- ============================================================================

function JASM_ShopView_Customer:createChildren()
	-- Root layout: 60/40 split (grid | details)
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0)
	
	-- Columns: 60% grid, 40% details
	local colGrid = self.layout:addColumnFill()
	local colDetails = self.layout:addColumn(0.4)
	local mainRow = self.layout:addRowFill()
	
	self:addChild(self.layout)
	
	-- ========================================================================
	-- COLUMN 1: PRODUCT GRID (60%)
	-- ========================================================================
	
	self.productGrid = ISTiledIconListBox:new(0, 0, self.width * 0.6, self.height, self.dataList)
	self.productGrid:initialise()
	self.productGrid:instantiate()
	
	-- Tile rendering callback
	self.productGrid.onRenderTile = function(tile, data, x, y, w, h, mouseover)
		self:onRenderProductTile(tile, data, x, y, w, h, mouseover)
	end
	
	-- Tile click callback
	self.productGrid.onClickTile = function(data)
		self:onProductSelected(data)
	end
	
	if mainRow then
		self.layout:setElement(colGrid:index(), mainRow:index(), self.productGrid)
	end
	
	-- ========================================================================
	-- COLUMN 2: DETAILS PANEL (40%)
	-- ========================================================================
	
	self.detailsPanel = ISPanel:new(0, 0, self.width * 0.4, self.height)
	self.detailsPanel:initialise()
	
	if mainRow then
		self.layout:setElement(colDetails:index(), mainRow:index(), self.detailsPanel)
	end
	
	-- Nested layout for details (vertical stack)
	self.detailsLayout = ISTableLayout:new(0, 0, self.detailsPanel.width, self.detailsPanel.height)
	self.detailsLayout:initialise()
	self.detailsLayout:createTable(0, 0)
	
	local detailsCol = self.detailsLayout:addColumnFill()
	
	-- ========================================================================
	-- DETAILS SECTION: Header
	-- ========================================================================
	
	local rowHeader = self.detailsLayout:addRow()
	if rowHeader then rowHeader.minimumHeight = 50 end
	
	-- Header panel with icon + name + stock
	local headerPanel = ISPanel:new(0, 0, self.detailsPanel.width - 10, 45)
	headerPanel:initialise()
	
	self.productIcon = ISLabel:new(5, 5, 32, "", 1, 1, 1, 1, UIFont.Small, false)
	headerPanel:addChild(self.productIcon)
	
	self.productNameLabel = ISLabel:new(42, 5, 200, "Select a product", 1, 1, 1, 1, UIFont.Medium, true)
	headerPanel:addChild(self.productNameLabel)
	
	self.shopStockLabel = ISLabel:new(42, 25, 200, "Stock: -", 0.8, 0.8, 0.8, 1.0, UIFont.Small, false)
	headerPanel:addChild(self.shopStockLabel)
	
	local idxHeader = rowHeader and rowHeader:index() or 0
	self.detailsLayout:setElement(detailsCol:index(), idxHeader, headerPanel)
	
	-- ========================================================================
	-- DETAILS SECTION: Description
	-- ========================================================================
	
	local rowDesc = self.detailsLayout:addRow()
	if rowDesc then rowDesc.minimumHeight = 35 end
	
	self.descriptionLabel = ISLabel:new(10, 0, 300, "", 0.8, 0.8, 0.8, 1.0, UIFont.Small, true)
	
	local idxDesc = rowDesc and rowDesc:index() or 1
	self.detailsLayout:setElement(detailsCol:index(), idxDesc, self.descriptionLabel)
	
	-- ========================================================================
	-- DETAILS SECTION: Trade Selector Label
	-- ========================================================================
	
	local rowTradesLabel = self.detailsLayout:addRow()
	if rowTradesLabel then rowTradesLabel.minimumHeight = 20 end
	
	self.tradesLabel = ISLabel:new(10, 0, 200, "Available Trades:", 1, 1, 1, 1, UIFont.Small, true)
	
	local idxTradesLabel = rowTradesLabel and rowTradesLabel:index() or 2
	self.detailsLayout:setElement(detailsCol:index(), idxTradesLabel, self.tradesLabel)
	
	-- ========================================================================
	-- DETAILS SECTION: Trade Selector
	-- ========================================================================
	
	local rowTradesList = self.detailsLayout:addRow()
	if rowTradesList then rowTradesList.minimumHeight = 100 end
	
	self.tradeSelector = ESC_TradeSelector:new(10, 0, self.detailsPanel.width - 30, 95, {})
	self.tradeSelector:initialise()
	
	self.tradeSelector.onTradeSelected = function(target, trade, index)
		self:onTradeSelected(trade, index)
	end
	self.tradeSelector.callbackTarget = self
	
	local idxTradesList = rowTradesList and rowTradesList:index() or 3
	self.detailsLayout:setElement(detailsCol:index(), idxTradesList, self.tradeSelector)
	
	-- ========================================================================
	-- DETAILS SECTION: Affordability Panel
	-- ========================================================================
	
	local rowAffordability = self.detailsLayout:addRow()
	if rowAffordability then rowAffordability.minimumHeight = 75 end
	
	self.affordabilityPanel = ESC_AffordabilityPanel:new(10, 0, self.detailsPanel.width - 30, 70)
	self.affordabilityPanel:initialise()
	self.affordabilityPanel:createChildren()
	
	local idxAffordability = rowAffordability and rowAffordability:index() or 4
	self.detailsLayout:setElement(detailsCol:index(), idxAffordability, self.affordabilityPanel)
	
	-- ========================================================================
	-- DETAILS SECTION: Action Button
	-- ========================================================================
	
	local rowButton = self.detailsLayout:addRow()
	if rowButton then rowButton.minimumHeight = 35 end
	
	self.acceptButton = ISButton:new(10, 0, 140, 30, "ACCEPT TRADE", self, function()
		self:onAcceptTrade()
	end)
	self.acceptButton:initialise()
	self.acceptButton:instantiate()
	self.acceptButton.enable = false
	
	local idxButton = rowButton and rowButton:index() or 5
	self.detailsLayout:setElement(detailsCol:index(), idxButton, self.acceptButton)
	
	-- ========================================================================
	-- DETAILS SECTION: Error/Status Label
	-- ========================================================================
	
	local rowError = self.detailsLayout:addRow()
	if rowError then rowError.minimumHeight = 25 end
	
	self.errorLabel = ISLabel:new(10, 0, 300, "", 1.0, 0.3, 0.3, 1.0, UIFont.Small, false)
	
	local idxError = rowError and rowError:index() or 6
	self.detailsLayout:setElement(detailsCol:index(), idxError, self.errorLabel)
	
	-- ========================================================================
	-- Add details layout to panel
	-- ========================================================================
	
	self.detailsPanel:addChild(self.detailsLayout)
	
	-- Load products from shop
	self:refreshProducts()
end

-- ============================================================================
-- PRODUCT GRID RENDERING
-- ============================================================================

function JASM_ShopView_Customer:onRenderProductTile(_tile, _data, _x, _y, _w, _h, _mouseover)
	if not _data or not _data.type then
		return
	end
	
	-- Get item script
	local itemScript = getScriptManager():getItem(_data.type)
	if itemScript then
		local tex = itemScript:getNormalTexture()
		if tex then
			self:drawTextureScaled(tex, _x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
		end
	end
	
	-- Highlight on mouseover
	if _mouseover then
		self:drawRectBorderStatic(_x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
	end
	
	-- Selected highlight
	if self.selectedProduct and self.selectedProduct.type == _data.type then
		self:drawRectBorderStatic(_x, _y, _w, _h, 1.0, 0.6, 0.0, 1.0)  -- Orange border
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function JASM_ShopView_Customer:onProductSelected(_data)
	if not _data or not _data.type then
		return
	end
	
	self.selectedProduct = _data
	self.selectedTradeIndex = 1
	
	-- Update header
	local itemScript = getScriptManager():getItem(_data.type)
	if itemScript then
		self.productNameLabel:setName(itemScript:getDisplayName())
		
		-- Try to render item icon
		local tex = itemScript:getNormalTexture()
		if tex then
			-- Store texture reference for rendering in header
			self.selectedProductTexture = tex
		end
	else
		self.productNameLabel:setName("Unknown Item")
	end
	
	-- Get shop stock
	local container = self.entity:getContainer()
	local shopStock = 0
	if container then
		shopStock = container:getItemCount(_data.type)
	end
	self.shopStockLabel:setName("Shop Stock: " .. shopStock .. " units")
	
	-- Load available trades
	self:loadAvailableTrades(_data.type)
	
	-- Update trade selector
	self.tradeSelector:setTrades(self.availableTrades)
	
	-- Auto-select first trade
	if #self.availableTrades > 0 then
		self:onTradeSelected(self.availableTrades[1], 1)
	else
		self:clearDetails()
	end
end

function JASM_ShopView_Customer:onTradeSelected(trade, index)
	if not trade then
		self:clearDetails()
		return
	end
	
	self.selectedTradeIndex = index
	
	-- Update affordability panel
	local playerInv = self.player:getInventory()
	local playerHas = playerInv:getItemCount(trade.request.itemType)
	
	self.affordabilityPanel:setNeeds(trade.request.itemType, trade.request.quantity)
	self.affordabilityPanel:setPlayerInventory(trade.request.itemType, playerHas)
	
	-- Calculate max trades
	local container = self.entity:getContainer()
	local shopHas = 0
	if container then
		shopHas = container:getItemCount(self.selectedProduct.type)
	end
	local maxTrades = math.floor(shopHas / trade.offer.quantity)
	self.affordabilityPanel:setMaxTrades(maxTrades)
	
	-- Update button state
	if self.affordabilityPanel:canAffordTrade() then
		self.acceptButton:setEnable(true)
		self.errorLabel:setName("")
	else
		self.acceptButton:setEnable(false)
		local missing = self.affordabilityPanel:getMissingQty()
		self.errorLabel:setName("Insufficient funds (need " .. missing .. " more)")
		self.errorLabel:setColor(1.0, 0.3, 0.3, 1.0)
	end
	
	-- Update button text
	local offerScript = getScriptManager():getItem(trade.offer.itemType)
	local requestScript = getScriptManager():getItem(trade.request.itemType)
	
	local offerName = trade.offer.itemType
	local requestName = trade.request.itemType
	
	if offerScript then
		offerName = offerScript:getDisplayName()
	end
	if requestScript then
		requestName = requestScript:getDisplayName()
	end
	
	local buttonText = string.format("ACCEPT: Give %d× %s",
		trade.offer.quantity, offerName)
	
	self.acceptButton:setTitle(buttonText)
end

function JASM_ShopView_Customer:onAcceptTrade()
	if not self.selectedProduct or not self.availableTrades[self.selectedTradeIndex] then
		return
	end
	
	local trade = self.availableTrades[self.selectedTradeIndex]
	
	-- Send command to server
	local args = {
		x = self.entity:getX(),
		y = self.entity:getY(),
		z = self.entity:getZ(),
		index = self.entity:getObjectIndex(),
		action = "BUY_TRADE",
		itemType = self.selectedProduct.type,
		tradeIndex = self.selectedTradeIndex,
		offer = {
			itemType = trade.offer.itemType,
			quantity = trade.offer.quantity
		},
		request = {
			itemType = trade.request.itemType,
			quantity = trade.request.quantity
		}
	}
	
	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
	
	-- Optionally clear selection after trade
	-- self:clearDetails()
	-- self:refreshProducts()
end

-- ============================================================================
-- HELPER METHODS
-- ============================================================================

function JASM_ShopView_Customer:loadAvailableTrades(itemType)
	self.availableTrades = {}
	
	local modData = self.entity:getModData()
	local shopTrades = modData.shopTrades or {}
	
	if shopTrades[itemType] then
		for _, trade in ipairs(shopTrades[itemType]) do
			table.insert(self.availableTrades, trade)
		end
	end
end

function JASM_ShopView_Customer:refreshProducts()
	self.dataList:clear()
	
	local modData = self.entity:getModData()
	local shopTrades = modData.shopTrades or {}
	
	-- Add each item that has trades available
	for itemType, trades in pairs(shopTrades) do
		if #trades > 0 then
			self.dataList:add({type = itemType})
		end
	end
	
	-- Recalculate tile layout
	if self.productGrid then
		self.productGrid:calculateTiles()
	end
end

function JASM_ShopView_Customer:clearDetails()
	self.selectedProduct = nil
	self.availableTrades = {}
	self.selectedTradeIndex = 1
	
	self.productNameLabel:setName("Select a product")
	self.shopStockLabel:setName("Stock: -")
	self.descriptionLabel:setName("")
	self.tradeSelector:setTrades({})
	self.affordabilityPanel:setNeeds("", 0)
	self.affordabilityPanel:setPlayerInventory("", 0)
	self.affordabilityPanel:setMaxTrades(0)
	self.acceptButton:setEnable(false)
	self.errorLabel:setName("")
end

-- ============================================================================
-- LAYOUT MANAGEMENT
-- ============================================================================

function JASM_ShopView_Customer:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	-- Update root layout
	if self.layout then
		self.layout:setWidth(_preferredWidth)
		self.layout:setHeight(_preferredHeight)
		self.layout:calculateLayout(_preferredWidth, _preferredHeight)
	end
	
	-- Update details layout
	if self.detailsLayout then
		self.detailsLayout:setWidth(self.detailsPanel:getWidth())
		self.detailsLayout:setHeight(self.detailsPanel:getHeight())
		self.detailsLayout:calculateLayout(self.detailsPanel:getWidth(), self.detailsPanel:getHeight())
	end
end

return JASM_ShopView_Customer
