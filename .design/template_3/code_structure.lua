-- ============================================================================
-- TEMPLATE 3: LUA CLIENT UI CODE STRUCTURE
-- Single-file views with no modular components (for now)
-- ============================================================================

-- ============================================================================
-- FILE 1: shop_view_owner.lua
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("Entity/ISUI/Controls/ISTableLayout")
require("Entity/ISUI/Controls/ISItemSlot")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@class JASM_ShopView_Owner : ISPanel
local JASM_ShopView_Owner = ISPanel:derive("JASM_ShopView_Owner")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function JASM_ShopView_Owner:initialise()
	ISPanel.initialise(self)
end

function JASM_ShopView_Owner:new(x, y, width, height, player, entity)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.player = player
	o.entity = entity
	
	-- Internal state for form
	o.selectedItem = nil
	o.activeTrades = {}
	o.draftTrade = {
		offer = {itemType = nil, quantity = 1},
		request = {itemType = nil, quantity = 1}
	}
	
	return o
end

-- ============================================================================
-- LAYOUT CREATION
-- ============================================================================

function JASM_ShopView_Owner:createChildren()
	-- Root layout: 35/65 split (inventory | form)
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0)
	
	-- Define columns: 35% inventory, 65% form
	local colInventory = self.layout:addColumn(0.35)
	local colForm = self.layout:addColumnFill()
	local mainRow = self.layout:addRowFill()
	
	self:addChild(self.layout)
	
	-- ========================================================================
	-- COLUMN 1: INVENTORY LIST (35%)
	-- ========================================================================
	
	self.itemListBox = ISScrollingListBox:new(0, 0, self.width * 0.35, self.height)
	self.itemListBox:initialise()
	self.itemListBox:instantiate()
	self.itemListBox.drawBorder = true
	self.itemListBox.onmousedown = function(...)
		self:onItemSelected(...)
	end
	
	if mainRow then
		self.layout:setElement(colInventory:index(), mainRow:index(), self.itemListBox)
	end
	
	self:refreshInventoryList()
	
	-- ========================================================================
	-- COLUMN 2: FORM PANEL (65%)
	-- ========================================================================
	
	self.formPanel = ISPanel:new(0, 0, self.width * 0.65, self.height)
	self.formPanel:initialise()
	
	if mainRow then
		self.layout:setElement(colForm:index(), mainRow:index(), self.formPanel)
	end
	
	-- Nested layout for form (vertical stack)
	self.formLayout = ISTableLayout:new(0, 0, self.formPanel.width, self.formPanel.height)
	self.formLayout:initialise()
	self.formLayout:createTable(0, 0)
	
	local formCol = self.formLayout:addColumnFill()
	
	-- Header
	local rowHeader = self.formLayout:addRow()
	if rowHeader then rowHeader.minimumHeight = 30 end
	
	-- Selected item label
	local rowSelection = self.formLayout:addRow()
	if rowSelection then rowSelection.minimumHeight = 20 end
	
	-- ========================================================================
	-- OFFER SECTION
	-- ========================================================================
	
	local rowOfferLabel = self.formLayout:addRow()
	if rowOfferLabel then rowOfferLabel.minimumHeight = 25 end
	
	local rowOfferInput = self.formLayout:addRow()
	if rowOfferInput then rowOfferInput.minimumHeight = 50 end
	
	-- ========================================================================
	-- REQUEST SECTION
	-- ========================================================================
	
	local rowRequestLabel = self.formLayout:addRow()
	if rowRequestLabel then rowRequestLabel.minimumHeight = 25 end
	
	local rowRequestInput = self.formLayout:addRow()
	if rowRequestInput then rowRequestInput.minimumHeight = 50 end
	
	-- ========================================================================
	-- SUMMARY & VALIDATION
	-- ========================================================================
	
	local rowSummary = self.formLayout:addRow()
	if rowSummary then rowSummary.minimumHeight = 50 end
	
	local rowValidation = self.formLayout:addRow()
	if rowValidation then rowValidation.minimumHeight = 25 end
	
	local rowAddButton = self.formLayout:addRow()
	if rowAddButton then rowAddButton.minimumHeight = 30 end
	
	-- ========================================================================
	-- ACTIVE TRADES LIST
	-- ========================================================================
	
	local rowTradesLabel = self.formLayout:addRow()
	if rowTradesLabel then rowTradesLabel.minimumHeight = 25 end
	
	local rowTradesList = self.formLayout:addRowFill()
	
	-- ========================================================================
	-- FOOTER BUTTONS
	-- ========================================================================
	
	local rowFooter = self.formLayout:addRow()
	if rowFooter then rowFooter.minimumHeight = 35 end
	
	self.formPanel:addChild(self.formLayout)
	
	-- ========================================================================
	-- POPULATE FORM ELEMENTS
	-- ========================================================================
	
	local idxHeader = rowHeader and rowHeader:index() or 0
	local idxSelection = rowSelection and rowSelection:index() or 1
	local idxOfferLabel = rowOfferLabel and rowOfferLabel:index() or 2
	local idxOfferInput = rowOfferInput and rowOfferInput:index() or 3
	local idxRequestLabel = rowRequestLabel and rowRequestLabel:index() or 4
	local idxRequestInput = rowRequestInput and rowRequestInput:index() or 5
	local idxSummary = rowSummary and rowSummary:index() or 6
	local idxValidation = rowValidation and rowValidation:index() or 7
	local idxAddButton = rowAddButton and rowAddButton:index() or 8
	local idxTradesLabel = rowTradesLabel and rowTradesLabel:index() or 9
	local idxTradesList = rowTradesList and rowTradesList:index() or 10
	local idxFooter = rowFooter and rowFooter:index() or 11
	
	-- Header
	self.formHeader = ISLabel:new(10, 0, 25, "Build Trade for Selected Item", 1, 1, 1, 1, UIFont.Medium, true)
	self.formLayout:setElement(formCol:index(), idxHeader, self.formHeader)
	
	-- Selection label
	self.selectionLabel = ISLabel:new(10, 0, 20, "Select an item", 1, 1, 1, 1, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxSelection, self.selectionLabel)
	
	-- OFFER SECTION LABEL
	self.offerLabel = ISLabel:new(10, 0, 20, "OFFER (What shop gives)", 0.2, 0.6, 0.9, 1.0, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxOfferLabel, self.offerLabel)
	
	-- OFFER INPUTS (quantity + display)
	local offerInputPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 45)
	offerInputPanel:initialise()
	
	self.offerQtyInput = ISTextEntryBox:new("1", 10, 5, 60, 25)
	self.offerQtyInput:initialise()
	self.offerQtyInput:instantiate()
	self.offerQtyInput:setOnlyNumbers(true)
	offerInputPanel:addChild(self.offerQtyInput)
	
	self.offerDisplay = ISLabel:new(80, 5, 300, "Water Bottle - You have 12 available", 1, 1, 1, 1, UIFont.Small, false)
	offerInputPanel:addChild(self.offerDisplay)
	
	self.formLayout:setElement(formCol:index(), idxOfferInput, offerInputPanel)
	
	-- REQUEST SECTION LABEL
	self.requestLabel = ISLabel:new(10, 0, 20, "REQUEST (What shop wants)", 0.9, 0.3, 0.2, 1.0, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxRequestLabel, self.requestLabel)
	
	-- REQUEST INPUTS (quantity + item type)
	local requestInputPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 45)
	requestInputPanel:initialise()
	
	self.requestQtyInput = ISTextEntryBox:new("100", 10, 5, 60, 25)
	self.requestQtyInput:initialise()
	self.requestQtyInput:instantiate()
	self.requestQtyInput:setOnlyNumbers(true)
	requestInputPanel:addChild(self.requestQtyInput)
	
	self.requestItemInput = ISTextEntryBox:new("Base.Nails", 80, 5, 150, 25)
	self.requestItemInput:initialise()
	self.requestItemInput:instantiate()
	requestInputPanel:addChild(self.requestItemInput)
	
	self.formLayout:setElement(formCol:index(), idxRequestInput, requestInputPanel)
	
	-- SUMMARY CARD
	self.summaryCard = ISLabel:new(10, 0, 300, "1× Water → 100× Nails", 1, 1, 1, 1, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxSummary, self.summaryCard)
	
	-- VALIDATION FEEDBACK
	self.validationLabel = ISLabel:new(10, 0, 300, "", 1, 0, 0, 1, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxValidation, self.validationLabel)
	
	-- ADD BUTTON
	self.addTradeButton = ISButton:new(10, 0, 100, 25, "ADD TRADE", self, function()
		self:addTrade()
	end)
	self.addTradeButton:initialise()
	self.addTradeButton:instantiate()
	self.formLayout:setElement(formCol:index(), idxAddButton, self.addTradeButton)
	
	-- TRADES LIST LABEL
	self.tradesListLabel = ISLabel:new(10, 0, 20, "Active Trades", 1, 1, 1, 1, UIFont.Small, true)
	self.formLayout:setElement(formCol:index(), idxTradesLabel, self.tradesListLabel)
	
	-- TRADES LIST
	self.tradesList = ISScrollingListBox:new(10, 0, self.formPanel.width - 40, 100)
	self.tradesList:initialise()
	self.tradesList:instantiate()
	self.tradesList.drawBorder = true
	self.formLayout:setElement(formCol:index(), idxTradesList, self.tradesList)
	
	-- FOOTER BUTTONS
	local footerPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 30)
	footerPanel:initialise()
	
	self.saveButton = ISButton:new(10, 0, 100, 25, "SAVE ALL", self, function()
		self:saveAll()
	end)
	self.saveButton:initialise()
	self.saveButton:instantiate()
	footerPanel:addChild(self.saveButton)
	
	self.cancelButton = ISButton:new(120, 0, 100, 25, "CANCEL", self, function()
		self:cancel()
	end)
	self.cancelButton:initialise()
	self.cancelButton:instantiate()
	footerPanel:addChild(self.cancelButton)
	
	self.formLayout:setElement(formCol:index(), idxFooter, footerPanel)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function JASM_ShopView_Owner:onItemSelected(_item)
	self.selectedItem = _item
	
	if _item then
		local itemName = _item.item:getName()
		local count = self:getInventoryCount(_item.type)
		self.selectionLabel:setName(itemName .. " - Stock: " .. count)
		self.offerDisplay:setName(itemName .. " - You have " .. count .. " available")
		
		-- Clear form for new trade
		self.offerQtyInput:setText("1")
		self.requestQtyInput:setText("1")
		self.requestItemInput:setText("")
		
		-- Load active trades for this item
		self:refreshTradesList(_item.type)
	end
end

function JASM_ShopView_Owner:addTrade()
	local offerQty = tonumber(self.offerQtyInput:getText()) or 1
	local requestQty = tonumber(self.requestQtyInput:getText()) or 1
	local requestType = self.requestItemInput:getText()
	
	-- Validate
	if not self:validateTrade(offerQty, requestType) then
		return
	end
	
	-- Add to list
	table.insert(self.activeTrades, {
		offer = {itemType = self.selectedItem.type, quantity = offerQty},
		request = {itemType = requestType, quantity = requestQty}
	})
	
	-- Refresh UI
	self:refreshTradesList(self.selectedItem.type)
	self.offerQtyInput:setText("1")
	self.requestQtyInput:setText("1")
	self.requestItemInput:setText("")
end

function JASM_ShopView_Owner:saveAll()
	if not self.selectedItem or #self.activeTrades == 0 then
		return
	end
	
	local args = {
		x = self.entity:getX(),
		y = self.entity:getY(),
		z = self.entity:getZ(),
		index = self.entity:getObjectIndex(),
		action = "SET_TRADES",
		itemType = self.selectedItem.type,
		trades = self.activeTrades
	}
	
	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
end

function JASM_ShopView_Owner:cancel()
	self.activeTrades = {}
	self.selectedItem = nil
end

-- ============================================================================
-- HELPER METHODS
-- ============================================================================

function JASM_ShopView_Owner:validateTrade(offerQty, requestType)
	if not self.selectedItem then
		self.validationLabel:setName("No item selected")
		self.validationLabel:setColor(1, 0, 0, 1)
		return false
	end
	
	local inventory = self:getInventoryCount(self.selectedItem.type)
	if offerQty > inventory then
		self.validationLabel:setName("Exceeds stock (" .. inventory .. " available)")
		self.validationLabel:setColor(1, 0, 0, 1)
		return false
	end
	
	if not getScriptManager():getItem(requestType) then
		self.validationLabel:setName("Item not found: " .. requestType)
		self.validationLabel:setColor(1, 0, 0, 1)
		return false
	end
	
	self.validationLabel:setName("")
	return true
end

function JASM_ShopView_Owner:getInventoryCount(itemType)
	local container = self.entity:getContainer()
	if not container then return 0 end
	return container:getItemCount(itemType)
end

function JASM_ShopView_Owner:refreshInventoryList()
	self.itemListBox:clear()
	local container = self.entity:getContainer()
	if not container then return end
	
	local items = container:getItems()
	local itemTypes = {}
	
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local type = item:getFullType()
		if not itemTypes[type] then
			itemTypes[type] = item
			self.itemListBox:addItem(item:getName(), {item = item, type = type})
		end
	end
end

function JASM_ShopView_Owner:refreshTradesList(itemType)
	self.tradesList:clear()
	
	for idx, trade in ipairs(self.activeTrades) do
		local label = string.format("%d× → %d× %s",
			trade.offer.quantity,
			trade.request.quantity,
			trade.request.itemType)
		
		self.tradesList:addItem(label, {trade = trade, index = idx})
	end
end

function JASM_ShopView_Owner:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	if self.layout then
		self.layout:setWidth(_preferredWidth)
		self.layout:setHeight(_preferredHeight)
		self.layout:calculateLayout(_preferredWidth, _preferredHeight)
	end
	
	if self.formLayout then
		self.formLayout:setWidth(self.formPanel:getWidth())
		self.formLayout:setHeight(self.formPanel:getHeight())
		self.formLayout:calculateLayout(self.formPanel:getWidth(), self.formPanel:getHeight())
	end
end

return JASM_ShopView_Owner


-- ============================================================================
-- FILE 2: shop_view_customer.lua
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("Entity/ISUI/CraftRecipe/ISTiledIconListBox")
require("Entity/ISUI/Controls/ISTableLayout")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@type JASM_ShopView_Customer
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
	
	o.selectedProduct = nil
	o.selectedTrade = 1
	o.availableTrades = {}
	
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
	
	local colGrid = self.layout:addColumnFill()
	local colDetails = self.layout:addColumn(0.4)
	local mainRow = self.layout:addRowFill()
	
	self:addChild(self.layout)
	
	-- ========================================================================
	-- COLUMN 1: PRODUCT GRID (60%)
	-- ========================================================================
	
	self.dataList = ArrayList.new()
	self.productGrid = ISTiledIconListBox:new(0, 0, self.width * 0.6, self.height, self.dataList)
	self.productGrid:initialise()
	self.productGrid:instantiate()
	self.productGrid.onRenderTile = function(...)
		self:onRenderProductTile(...)
	end
	self.productGrid.onClickTile = function(...)
		self:onProductSelected(...)
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
	
	-- Header
	local rowHeader = self.detailsLayout:addRow()
	if rowHeader then rowHeader.minimumHeight = 50 end
	
	-- Description
	local rowDesc = self.detailsLayout:addRow()
	if rowDesc then rowDesc.minimumHeight = 40 end
	
	-- ========================================================================
	-- TRADE SELECTOR (NEW)
	-- ========================================================================
	
	local rowTradesLabel = self.detailsLayout:addRow()
	if rowTradesLabel then rowTradesLabel.minimumHeight = 25 end
	
	local rowTradesList = self.detailsLayout:addRow()
	if rowTradesList then rowTradesList.minimumHeight = 80 end
	
	-- ========================================================================
	-- AFFORDABILITY CHECK (NEW)
	-- ========================================================================
	
	local rowAffordability = self.detailsLayout:addRow()
	if rowAffordability then rowAffordability.minimumHeight = 60 end
	
	-- ========================================================================
	-- ACTION BUTTON
	-- ========================================================================
	
	local rowButton = self.detailsLayout:addRow()
	if rowButton then rowButton.minimumHeight = 35 end
	
	-- ========================================================================
	-- ERROR LABEL
	-- ========================================================================
	
	local rowError = self.detailsLayout:addRow()
	if rowError then rowError.minimumHeight = 25 end
	
	self.detailsPanel:addChild(self.detailsLayout)
	
	-- ========================================================================
	-- POPULATE DETAILS ELEMENTS
	-- ========================================================================
	
	local idxHeader = rowHeader and rowHeader:index() or 0
	local idxDesc = rowDesc and rowDesc:index() or 1
	local idxTradesLabel = rowTradesLabel and rowTradesLabel:index() or 2
	local idxTradesList = rowTradesList and rowTradesList:index() or 3
	local idxAffordability = rowAffordability and rowAffordability:index() or 4
	local idxButton = rowButton and rowButton:index() or 5
	local idxError = rowError and rowError:index() or 6
	
	-- Header (product name + stock)
	self.productNameLabel = ISLabel:new(10, 0, 20, "Select a product", 1, 1, 1, 1, UIFont.Medium, true)
	self.detailsLayout:setElement(detailsCol:index(), idxHeader, self.productNameLabel)
	
	-- Description
	self.descriptionLabel = ISLabel:new(10, 0, 20, "", 0.8, 0.8, 0.8, 1.0, UIFont.Small, true)
	self.detailsLayout:setElement(detailsCol:index(), idxDesc, self.descriptionLabel)
	
	-- Trade selector label
	self.tradesLabel = ISLabel:new(10, 0, 20, "Available Trades:", 1, 1, 1, 1, UIFont.Small, true)
	self.detailsLayout:setElement(detailsCol:index(), idxTradesLabel, self.tradesLabel)
	
	-- Trade list (radio button replacement)
	self.tradeSelector = ISScrollingListBox:new(10, 0, self.detailsPanel.width - 40, 70)
	self.tradeSelector:initialise()
	self.tradeSelector:instantiate()
	self.tradeSelector.drawBorder = true
	self.tradeSelector.onmousedown = function(...)
		self:onTradeSelected(...)
	end
	self.detailsLayout:setElement(detailsCol:index(), idxTradesList, self.tradeSelector)
	
	-- Affordability check
	local affordPanel = ISPanel:new(0, 0, self.detailsPanel.width - 20, 55)
	affordPanel:initialise()
	
	self.needsLabel = ISLabel:new(10, 5, 200, "You need: -", 0.8, 0.8, 0.8, 1.0, UIFont.Small, false)
	affordPanel:addChild(self.needsLabel)
	
	self.haveLabel = ISLabel:new(10, 25, 200, "You have: -", 0.8, 0.8, 0.8, 1.0, UIFont.Small, false)
	affordPanel:addChild(self.haveLabel)
	
	self.availableLabel = ISLabel:new(10, 45, 200, "Available: -", 0.8, 0.8, 0.8, 1.0, UIFont.Small, false)
	affordPanel:addChild(self.availableLabel)
	
	self.detailsLayout:setElement(detailsCol:index(), idxAffordability, affordPanel)
	
	-- Action button
	self.acceptButton = ISButton:new(10, 0, 150, 30, "ACCEPT TRADE", self, function()
		self:onAcceptTrade()
	end)
	self.acceptButton:initialise()
	self.acceptButton:instantiate()
	self.acceptButton.enable = false
	self.detailsLayout:setElement(detailsCol:index(), idxButton, self.acceptButton)
	
	-- Error label
	self.errorLabel = ISLabel:new(10, 0, 200, "", 1, 0.3, 0.3, 1, UIFont.Small, false)
	self.detailsLayout:setElement(detailsCol:index(), idxError, self.errorLabel)
	
	self:refreshProducts()
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function JASM_ShopView_Customer:onRenderProductTile(_tile, _data, _x, _y, _w, _h, _mouseover)
	local itemScript = getScriptManager():getItem(_data.type)
	if itemScript then
		local tex = itemScript:getNormalTexture()
		if tex then
			self:drawTextureScaled(tex, _x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
		end
	end
	if _mouseover then
		self:drawRectBorderStatic(_x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
	end
end

function JASM_ShopView_Customer:onProductSelected(_data)
	self.selectedProduct = _data
	self.selectedTrade = 1
	
	local itemScript = getScriptManager():getItem(_data.type)
	self.productNameLabel:setName(itemScript:getDisplayName())
	
	-- Load available trades
	self:loadAvailableTrades(_data)
	
	-- Populate trade selector
	self.tradeSelector:clear()
	for i, trade in ipairs(self.availableTrades) do
		local label = string.format("%d× → %d× %s",
			trade.offer.quantity,
			trade.request.quantity,
			trade.request.itemType)
		self.tradeSelector:addItem(label, {trade = trade, index = i})
	end
	
	-- Select first trade
	if #self.availableTrades > 0 then
		self.selectedTrade = 1
		self.tradeSelector:setItemAndEnsureVisible(self.tradeSelector:getItemAt(0))
		self:updateAffordability()
	end
end

function JASM_ShopView_Customer:onTradeSelected(_item)
	self.selectedTrade = _item.index
	self:updateAffordability()
end

function JASM_ShopView_Customer:updateAffordability()
	if not self.selectedProduct or not self.availableTrades[self.selectedTrade] then
		self.needsLabel:setName("You need: -")
		self.haveLabel:setName("You have: -")
		self.availableLabel:setName("Available: -")
		self.acceptButton:setEnable(false)
		return
	end
	
	local trade = self.availableTrades[self.selectedTrade]
	local requestType = trade.request.itemType
	local requestQty = trade.request.quantity
	
	-- Check player inventory
	local playerInv = self.player:getInventory()
	local playerHas = playerInv:getItemCount(requestType)
	
	-- Calculate max completions
	local container = self.entity:getContainer()
	local shopHas = 0
	if container then
		shopHas = container:getItemCount(self.selectedProduct.type)
	end
	local maxCompletions = math.floor(shopHas / trade.offer.quantity)
	
	-- Update UI
	local requestName = requestType
	local reqScript = getScriptManager():getItem(requestType)
	if reqScript then
		requestName = reqScript:getDisplayName()
	end
	
	self.needsLabel:setName("You need: " .. requestQty .. "× " .. requestName)
	
	if playerHas >= requestQty then
		self.haveLabel:setName("You have: " .. playerHas .. "× " .. requestName .. " ✓")
		self.haveLabel:setColor(0.2, 0.8, 0.2, 1.0)
		self.acceptButton:setEnable(true)
	else
		self.haveLabel:setName("You have: " .. playerHas .. "× " .. requestName)
		self.haveLabel:setColor(1.0, 0.3, 0.3, 1.0)
		self.acceptButton:setEnable(false)
		self.errorLabel:setName("Insufficient funds (" .. playerHas .. "/" .. requestQty .. ")")
	end
	
	self.availableLabel:setName("Available: " .. maxCompletions .. " trades max")
end

function JASM_ShopView_Customer:onAcceptTrade()
	if not self.selectedProduct or not self.availableTrades[self.selectedTrade] then
		return
	end
	
	local trade = self.availableTrades[self.selectedTrade]
	
	local args = {
		x = self.entity:getX(),
		y = self.entity:getY(),
		z = self.entity:getZ(),
		index = self.entity:getObjectIndex(),
		action = "BUY",
		itemType = self.selectedProduct.type,
		tradeIndex = self.selectedTrade,
		offer = trade.offer,
		request = trade.request
	}
	
	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
end

-- ============================================================================
-- HELPER METHODS
-- ============================================================================

function JASM_ShopView_Customer:loadAvailableTrades(_product)
	self.availableTrades = {}
	
	local modData = self.entity:getModData()
	local trades = modData.shopTrades or {}
	
	if trades[_product.type] then
		for _, trade in ipairs(trades[_product.type]) do
			table.insert(self.availableTrades, trade)
		end
	end
end

function JASM_ShopView_Customer:refreshProducts()
	self.dataList:clear()
	local modData = self.entity:getModData()
	local trades = modData.shopTrades or {}
	
	for itemType, _ in pairs(trades) do
		self.dataList:add({type = itemType})
	end
	
	self.productGrid:calculateTiles()
end

function JASM_ShopView_Customer:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	if self.layout then
		self.layout:setWidth(_preferredWidth)
		self.layout:setHeight(_preferredHeight)
		self.layout:calculateLayout(_preferredWidth, _preferredHeight)
	end
	
	if self.detailsLayout then
		self.detailsLayout:setWidth(self.detailsPanel:getWidth())
		self.detailsLayout:setHeight(self.detailsPanel:getHeight())
		self.detailsLayout:calculateLayout(self.detailsPanel:getWidth(), self.detailsPanel:getHeight())
	end
end

return JASM_ShopView_Customer
