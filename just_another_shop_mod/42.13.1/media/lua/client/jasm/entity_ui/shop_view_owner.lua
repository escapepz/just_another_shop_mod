-- ============================================================================
-- shop_view_owner.lua (Implementation)
-- Template 3: Owner View - Bundle Transaction Manager
-- ============================================================================
-- Layout: 35/65 split
-- Left (35%): Item inventory list
-- Right (65%): Transaction builder with OFFER + REQUEST sections
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("ISUI/ISScrollingListBox")
require("Entity/ISUI/Controls/ISTableLayout")

-- Custom components
local ESC_QuantityInput = require("jasm/entity_ui/components/esc_quantity_input")
local ESC_ItemInput = require("jasm/entity_ui/components/esc_item_input")
local ESC_TradeCard = require("jasm/entity_ui/components/esc_trade_card")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@class JASM_ShopView_Owner : ISPanel
---@field player IsoPlayer Player instance
---@field entity IsoObject Shop entity
---@field layout ISTableLayout Root layout (35/65 split)
---@field itemListBox ISScrollingListBox Inventory item list
---@field formPanel ISPanel Transaction builder (right column)
---@field formLayout ISTableLayout Details vertical layout
---@field selectedItem table Currently selected inventory item
---@field activeTrades table[] Active trades for selected item
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
	
	-- State
	o.selectedItem = nil
	o.activeTrades = {}
	
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
	
	-- Columns: 35% inventory, 65% form
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
	
	self.itemListBox.onmousedown = function(item)
		self:onItemSelected(item)
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
	
	-- ========================================================================
	-- SECTION 1: Header
	-- ========================================================================
	
	local rowHeader = self.formLayout:addRow()
	if rowHeader then rowHeader.minimumHeight = 30 end
	
	self.formHeader = ISLabel:new(10, 0, 25, "Build Trade for Selected Item", 1, 1, 1, 1, UIFont.Medium, true)
	local idxHeader = rowHeader and rowHeader:index() or 0
	self.formLayout:setElement(formCol:index(), idxHeader, self.formHeader)
	
	-- ========================================================================
	-- SECTION 2: Selection Label
	-- ========================================================================
	
	local rowSelection = self.formLayout:addRow()
	if rowSelection then rowSelection.minimumHeight = 20 end
	
	self.selectionLabel = ISLabel:new(10, 0, 20, "Select an item", 1, 1, 1, 1, UIFont.Small, true)
	local idxSelection = rowSelection and rowSelection:index() or 1
	self.formLayout:setElement(formCol:index(), idxSelection, self.selectionLabel)
	
	-- ========================================================================
	-- SECTION 3: OFFER Section Label
	-- ========================================================================
	
	local rowOfferLabel = self.formLayout:addRow()
	if rowOfferLabel then rowOfferLabel.minimumHeight = 25 end
	
	self.offerLabel = ISLabel:new(10, 0, 20, "OFFER (What shop gives)", 0.2, 0.6, 0.9, 1.0, UIFont.Small, true)
	local idxOfferLabel = rowOfferLabel and rowOfferLabel:index() or 2
	self.formLayout:setElement(formCol:index(), idxOfferLabel, self.offerLabel)
	
	-- ========================================================================
	-- SECTION 4: OFFER Input
	-- ========================================================================
	
	local rowOfferInput = self.formLayout:addRow()
	if rowOfferInput then rowOfferInput.minimumHeight = 60 end
	
	local offerPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 55)
	offerPanel:initialise()
	
	self.offerQtyInput = ESC_QuantityInput:new(0, 0, self.formPanel.width - 40, 55, "1", 1)
	self.offerQtyInput:initialise()
	self.offerQtyInput:createChildren()
	
	self.offerQtyInput.onQuantityChanged = function(self)
		-- Validate and update summary
		JASM_ShopView_Owner:updateSummaryCard()
		JASM_ShopView_Owner:validateAddButton()
	end
	
	offerPanel:addChild(self.offerQtyInput)
	
	local idxOfferInput = rowOfferInput and rowOfferInput:index() or 3
	self.formLayout:setElement(formCol:index(), idxOfferInput, offerPanel)
	
	-- ========================================================================
	-- SECTION 5: REQUEST Section Label
	-- ========================================================================
	
	local rowRequestLabel = self.formLayout:addRow()
	if rowRequestLabel then rowRequestLabel.minimumHeight = 25 end
	
	self.requestLabel = ISLabel:new(10, 0, 20, "REQUEST (What shop wants)", 0.9, 0.3, 0.2, 1.0, UIFont.Small, true)
	local idxRequestLabel = rowRequestLabel and rowRequestLabel:index() or 4
	self.formLayout:setElement(formCol:index(), idxRequestLabel, self.requestLabel)
	
	-- ========================================================================
	-- SECTION 6: REQUEST Quantity Input
	-- ========================================================================
	
	local rowRequestQty = self.formLayout:addRow()
	if rowRequestQty then rowRequestQty.minimumHeight = 60 end
	
	local requestQtyPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 55)
	requestQtyPanel:initialise()
	
	self.requestQtyInput = ESC_QuantityInput:new(0, 0, self.formPanel.width - 40, 55, "1", 999)
	self.requestQtyInput:initialise()
	self.requestQtyInput:createChildren()
	
	self.requestQtyInput.onQuantityChanged = function(self)
		JASM_ShopView_Owner:updateSummaryCard()
		JASM_ShopView_Owner:validateAddButton()
	end
	
	requestQtyPanel:addChild(self.requestQtyInput)
	
	local idxRequestQty = rowRequestQty and rowRequestQty:index() or 5
	self.formLayout:setElement(formCol:index(), idxRequestQty, requestQtyPanel)
	
	-- ========================================================================
	-- SECTION 7: REQUEST Item Type Input
	-- ========================================================================
	
	local rowRequestItem = self.formLayout:addRow()
	if rowRequestItem then rowRequestItem.minimumHeight = 65 end
	
	local requestItemLabel = ISLabel:new(10, 0, 20, "Item Type:", 1, 1, 1, 1, UIFont.Small, true)
	
	local requestItemPanel = ISPanel:new(0, 0, self.formPanel.width - 20, 60)
	requestItemPanel:initialise()
	requestItemPanel:addChild(requestItemLabel)
	
	self.requestItemInput = ESC_ItemInput:new(10, 20, self.formPanel.width - 50, 65, "Base.Nails")
	self.requestItemInput:initialise()
	self.requestItemInput:createChildren()
	
	self.requestItemInput.onItemChanged = function(self, script)
		JASM_ShopView_Owner:updateSummaryCard()
		JASM_ShopView_Owner:validateAddButton()
	end
	
	requestItemPanel:addChild(self.requestItemInput)
	
	local idxRequestItem = rowRequestItem and rowRequestItem:index() or 6
	self.formLayout:setElement(formCol:index(), idxRequestItem, requestItemPanel)
	
	-- ========================================================================
	-- SECTION 8: Summary Card
	-- ========================================================================
	
	local rowSummary = self.formLayout:addRow()
	if rowSummary then rowSummary.minimumHeight = 55 end
	
	self.summaryCard = ESC_TradeCard:new(10, 0, self.formPanel.width - 40, 50, {
		offer = {itemType = nil, quantity = 1},
		request = {itemType = nil, quantity = 1}
	})
	self.summaryCard:initialise()
	
	local idxSummary = rowSummary and rowSummary:index() or 7
	self.formLayout:setElement(formCol:index(), idxSummary, self.summaryCard)
	
	-- ========================================================================
	-- SECTION 9: Validation Feedback
	-- ========================================================================
	
	local rowValidation = self.formLayout:addRow()
	if rowValidation then rowValidation.minimumHeight = 25 end
	
	self.validationLabel = ISLabel:new(10, 0, 300, "", 1.0, 0.3, 0.3, 1.0, UIFont.Small, false)
	
	local idxValidation = rowValidation and rowValidation:index() or 8
	self.formLayout:setElement(formCol:index(), idxValidation, self.validationLabel)
	
	-- ========================================================================
	-- SECTION 10: Add Trade Button
	-- ========================================================================
	
	local rowAddButton = self.formLayout:addRow()
	if rowAddButton then rowAddButton.minimumHeight = 30 end
	
	self.addTradeButton = ISButton:new(10, 0, 120, 25, "ADD TRADE", self, function()
		self:addTrade()
	end)
	self.addTradeButton:initialise()
	self.addTradeButton:instantiate()
	self.addTradeButton:setEnable(false)
	
	local idxAddButton = rowAddButton and rowAddButton:index() or 9
	self.formLayout:setElement(formCol:index(), idxAddButton, self.addTradeButton)
	
	-- ========================================================================
	-- SECTION 11: Active Trades List Label
	-- ========================================================================
	
	local rowTradesLabel = self.formLayout:addRow()
	if rowTradesLabel then rowTradesLabel.minimumHeight = 20 end
	
	self.tradesListLabel = ISLabel:new(10, 0, 20, "Active Trades for Selected Item", 1, 1, 1, 1, UIFont.Small, true)
	
	local idxTradesLabel = rowTradesLabel and rowTradesLabel:index() or 10
	self.formLayout:setElement(formCol:index(), idxTradesLabel, self.tradesListLabel)
	
	-- ========================================================================
	-- SECTION 12: Active Trades List
	-- ========================================================================
	
	local rowTradesList = self.formLayout:addRowFill()
	
	self.tradesList = ISScrollingListBox:new(10, 0, self.formPanel.width - 40, 100)
	self.tradesList:initialise()
	self.tradesList:instantiate()
	self.tradesList.drawBorder = true
	
	self.tradesList.onmousedown = function(item)
		if item and item.tradeIndex then
			self:deleteTrade(item.tradeIndex)
		end
	end
	
	local idxTradesList = rowTradesList and rowTradesList:index() or 11
	self.formLayout:setElement(formCol:index(), idxTradesList, self.tradesList)
	
	-- ========================================================================
	-- SECTION 13: Footer Buttons
	-- ========================================================================
	
	local rowFooter = self.formLayout:addRow()
	if rowFooter then rowFooter.minimumHeight = 35 end
	
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
	
	local idxFooter = rowFooter and rowFooter:index() or 12
	self.formLayout:setElement(formCol:index(), idxFooter, footerPanel)
	
	-- ========================================================================
	-- Add form layout to panel
	-- ========================================================================
	
	self.formPanel:addChild(self.formLayout)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function JASM_ShopView_Owner:onItemSelected(item)
	if not item or not item.item then
		return
	end
	
	self.selectedItem = item
	
	-- Update header
	local itemName = item.item:getName()
	local count = self:getInventoryCount(item.type)
	
	self.selectionLabel:setName(itemName .. " - Stock: " .. count)
	
	-- Update offer quantity input max value
	self.offerQtyInput:setMaxValue(count)
	
	-- Clear form fields for new trade
	self.offerQtyInput:setValue("1")
	self.requestQtyInput:setValue("1")
	self.requestItemInput:setValue("Base.Nails")
	
	-- Clear summary
	self.summaryCard:setTrade({
		offer = {itemType = item.type, quantity = 1},
		request = {itemType = "Base.Nails", quantity = 1}
	})
	
	-- Load active trades for this item
	self:refreshTradesList(item.type)
	
	-- Validate
	self:validateAddButton()
end

function JASM_ShopView_Owner:addTrade()
	if not self.selectedItem then
		self.validationLabel:setName("No item selected")
		self.validationLabel:setColor(1.0, 0.3, 0.3, 1.0)
		return
	end
	
	-- Get form values
	local offerQty = self.offerQtyInput:getValue()
	local requestQty = self.requestQtyInput:getValue()
	local requestType = self.requestItemInput:getValue()
	
	-- Validate
	if not self.offerQtyInput:isValidValue() then
		return
	end
	if not self.requestQtyInput:isValidValue() then
		return
	end
	if not self.requestItemInput:isValidValue() then
		return
	end
	
	-- Create trade
	local trade = {
		id = "trade_" .. os.time() .. "_" .. math.random(10000),
		offer = {itemType = self.selectedItem.type, quantity = offerQty},
		request = {itemType = requestType, quantity = requestQty}
	}
	
	-- Check for duplicate
	for _, existing in ipairs(self.activeTrades) do
		if existing.offer.itemType == trade.offer.itemType and
		   existing.offer.quantity == trade.offer.quantity and
		   existing.request.itemType == trade.request.itemType and
		   existing.request.quantity == trade.request.quantity then
			self.validationLabel:setName("⚠ This trade already exists")
			self.validationLabel:setColor(1.0, 0.8, 0.0, 1.0)
			return
		end
	end
	
	-- Add to list
	table.insert(self.activeTrades, trade)
	
	-- Update UI
	self:refreshTradesList(self.selectedItem.type)
	
	-- Clear form for next trade
	self.offerQtyInput:setValue("1")
	self.requestQtyInput:setValue("1")
	self.requestItemInput:setValue("Base.Nails")
	self.validationLabel:setName("")
	
	-- Validate new button state
	self:validateAddButton()
end

function JASM_ShopView_Owner:deleteTrade(tradeIndex)
	if tradeIndex >= 1 and tradeIndex <= #self.activeTrades then
		table.remove(self.activeTrades, tradeIndex)
		if self.selectedItem then
			self:refreshTradesList(self.selectedItem.type)
		end
	end
end

function JASM_ShopView_Owner:saveAll()
	if not self.selectedItem or #self.activeTrades == 0 then
		self.validationLabel:setName("No trades to save")
		self.validationLabel:setColor(1.0, 0.8, 0.0, 1.0)
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
	
	self.validationLabel:setName("✓ Trades saved")
	self.validationLabel:setColor(0.2, 0.8, 0.2, 1.0)
end

function JASM_ShopView_Owner:cancel()
	self.activeTrades = {}
	self.selectedItem = nil
	self.selectionLabel:setName("Select an item")
	self.tradesList:clear()
	self.validationLabel:setName("")
end

-- ============================================================================
-- VALIDATION & UPDATES
-- ============================================================================

function JASM_ShopView_Owner:updateSummaryCard()
	if not self.selectedItem then
		return
	end
	
	local offerQty = self.offerQtyInput:getValue()
	local requestQty = self.requestQtyInput:getValue()
	local requestType = self.requestItemInput:getValue()
	
	self.summaryCard:setTrade({
		offer = {itemType = self.selectedItem.type, quantity = offerQty},
		request = {itemType = requestType, quantity = requestQty}
	})
end

function JASM_ShopView_Owner:validateAddButton()
	if not self.selectedItem then
		self.addTradeButton:setEnable(false)
		self.validationLabel:setName("Select an item")
		self.validationLabel:setColor(1.0, 0.8, 0.0, 1.0)
		return
	end
	
	-- Check all validations
	local offerValid = self.offerQtyInput:isValidValue()
	local requestQtyValid = self.requestQtyInput:isValidValue()
	local requestItemValid = self.requestItemInput:isValidValue()
	
	if offerValid and requestQtyValid and requestItemValid then
		self.addTradeButton:setEnable(true)
		self.validationLabel:setName("")
	else
		self.addTradeButton:setEnable(false)
		if not offerValid then
			self.validationLabel:setName(self.offerQtyInput:getFeedback())
		elseif not requestQtyValid then
			self.validationLabel:setName(self.requestQtyInput:getFeedback())
		elseif not requestItemValid then
			self.validationLabel:setName(self.requestItemInput:getFeedback())
		end
		self.validationLabel:setColor(1.0, 0.3, 0.3, 1.0)
	end
end

-- ============================================================================
-- HELPER METHODS
-- ============================================================================

function JASM_ShopView_Owner:getInventoryCount(itemType)
	local container = self.entity:getContainer()
	if not container then
		return 0
	end
	return container:getItemCount(itemType)
end

function JASM_ShopView_Owner:refreshInventoryList()
	self.itemListBox:clear()
	
	local container = self.entity:getContainer()
	if not container then
		return
	end
	
	local items = container:getItems()
	local itemTypes = {}
	
	-- Group items by type
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local type = item:getFullType()
		if not itemTypes[type] then
			itemTypes[type] = item
			
			local itemName = item:getName()
			local count = self:getInventoryCount(type)
			local label = itemName .. " (" .. count .. ")"
			
			self.itemListBox:addItem(label, {
				item = item,
				type = type
			})
		end
	end
end

function JASM_ShopView_Owner:refreshTradesList(itemType)
	self.tradesList:clear()
	
	for idx, trade in ipairs(self.activeTrades) do
		local requestScript = getScriptManager():getItem(trade.request.itemType)
		local requestName = trade.request.itemType
		if requestScript then
			requestName = requestScript:getDisplayName()
		end
		
		local label = string.format("%d× → %d× %s  [×]",
			trade.offer.quantity,
			trade.request.quantity,
			requestName)
		
		self.tradesList:addItem(label, {
			trade = trade,
			tradeIndex = idx
		})
	end
end

-- ============================================================================
-- LAYOUT MANAGEMENT
-- ============================================================================

function JASM_ShopView_Owner:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	-- Update root layout
	if self.layout then
		self.layout:setWidth(_preferredWidth)
		self.layout:setHeight(_preferredHeight)
		self.layout:calculateLayout(_preferredWidth, _preferredHeight)
	end
	
	-- Update form layout
	if self.formLayout then
		self.formLayout:setWidth(self.formPanel:getWidth())
		self.formLayout:setHeight(self.formPanel:getHeight())
		self.formLayout:calculateLayout(self.formPanel:getWidth(), self.formPanel:getHeight())
	end
end

return JASM_ShopView_Owner
