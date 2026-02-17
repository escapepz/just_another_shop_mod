require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")
require("Entity/ISUI/Controls/ISTableLayout")
require("Entity/ISUI/Controls/ISItemSlot")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities
local JASM_ShopView_Owner = ISPanel:derive("JASM_ShopView_Owner")

function JASM_ShopView_Owner:initialise()
	ISPanel.initialise(self)
end

function JASM_ShopView_Owner:createChildren()
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0)

	local colList = self.layout:addColumnFill()
	local colPrice = self.layout:addColumnFill()
	local mainRow = self.layout:addRowFill()

	self:addChild(self.layout)

	-- Column 1: Item List
	self.itemListBox = ISScrollingListBox:new(0, 0, self.width * 0.5, self.height)
	self.itemListBox:initialise()
	self.itemListBox:instantiate()
	self.itemListBox.onmousedown = function(...)
		self:onItemSelected(...)
	end
	self.itemListBox.target = self
	self.itemListBox.drawBorder = true

	if mainRow then
		self.layout:setElement(colList:index(), mainRow:index(), self.itemListBox)

		-- Column 2: Pricing Panel (Nested Table)
		self.pricePanel = ISPanel:new(0, 0, self.width * 0.5, self.height)
		self.pricePanel:initialise()
		self.layout:setElement(colPrice:index(), mainRow:index(), self.pricePanel)

		self.priceLayout = ISTableLayout:new(0, 0, self.pricePanel.width, self.pricePanel.height)
		self.priceLayout:initialise()
		self.priceLayout:createTable(0, 0)

		local colLabels = self.priceLayout:addColumn()
		colLabels.minimumWidth = 100
		local colInputs = self.priceLayout:addColumnFill()

		local rowTitle = self.priceLayout:addRow()
		if rowTitle then
			rowTitle.minimumHeight = 40
		end
		local rowCurrency = self.priceLayout:addRow()
		if rowCurrency then
			rowCurrency.minimumHeight = 70
		end
		local rowAmount = self.priceLayout:addRow()
		if rowAmount then
			rowAmount.minimumHeight = 50
		end
		local rowSave = self.priceLayout:addRow()
		if rowSave then
			rowSave.minimumHeight = 50
		end

		self.pricePanel:addChild(self.priceLayout)

		local idxTitle = rowTitle and rowTitle:index() or 0
		local idxCurrency = rowCurrency and rowCurrency:index() or 1
		local idxAmount = rowAmount and rowAmount:index() or 2
		local idxSave = rowSave and rowSave:index() or 3

		self.selectedItemLabel = ISLabel:new(10, 0, 25, "Select an item", 1, 1, 1, 1, UIFont.Medium, true)
		self.priceLayout:setElement(0, idxTitle, self.selectedItemLabel)

		self.currencyLabel = ISLabel:new(10, 0, 25, "Currency:", 1, 1, 1, 1, UIFont.Small, true)
		self.priceLayout:setElement(0, idxCurrency, self.currencyLabel)

		self.currencySlot = ISItemSlot:new(0, 0, 48, 48, nil)
		self.currencySlot:initialise()
		self.currencySlot:instantiate()
		self.currencySlot.onItemSelected = function(...)
			self:onCurrencyDropped(...)
		end
		self.priceLayout:setElement(1, idxCurrency, self.currencySlot)

		self.amountLabel = ISLabel:new(10, 0, 25, "Price:", 1, 1, 1, 1, UIFont.Small, true)
		self.priceLayout:setElement(0, idxAmount, self.amountLabel)

		self.amountEntry = ISTextEntryBox:new("1", 0, 0, 80, 25)
		self.amountEntry:initialise()
		self.amountEntry:instantiate()
		self.amountEntry:setOnlyNumbers(true)
		self.priceLayout:setElement(1, idxAmount, self.amountEntry)

		self.saveButton = ISButton:new(10, 0, 100, 25, "SET PRICE", self, function()
			self:onSavePrice()
		end)
		self.saveButton:initialise()
		self.saveButton:instantiate()
		self.priceLayout:setElement(1, idxSave, self.saveButton)
	end

	self:refreshList()
end

function JASM_ShopView_Owner:new(x, y, width, height, player, entity)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.player = player
	o.entity = entity
	return o
end

function JASM_ShopView_Owner:createChildren()
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0) -- Start with empty table

	-- Define two 50% width columns
	local colList = self.layout:addColumnFill()
	local colPrice = self.layout:addColumnFill()

	-- One main row for the content
	local mainRow = self.layout:addRowFill()

	self.view:addChild(self.layout)

	-- Column 1: Item List
	self.itemListBox = ISScrollingListBox:new(0, 0, self.width * 0.5, self.height)
	self.itemListBox:initialise()
	self.itemListBox:instantiate()
	self.itemListBox.onmousedown = function(...)
		self:onItemSelected(...)
	end
	self.itemListBox.target = self
	self.itemListBox.drawBorder = true
	if mainRow then
		self.layout:setElement(colList:index(), mainRow:index(), self.itemListBox)

		-- Column 2: Pricing Panel
		self.pricePanel = ISPanel:new(0, 0, self.width * 0.5, self.height)
		self.pricePanel:initialise()
		self.layout:setElement(colPrice:index(), mainRow:index(), self.pricePanel)
	end

	self.priceLayout = ISTableLayout:new(0, 0, self.pricePanel.width, self.pricePanel.height)
	self.priceLayout:initialise()
	self.priceLayout:createTable(0, 0) -- Clear default rows/cols if any

	local colLabels = self.priceLayout:addColumn()
	colLabels.minimumWidth = 80

	local colInputs = self.priceLayout:addColumnFill()

	local rowTitle = self.priceLayout:addRow()
	if rowTitle then
		rowTitle.minimumHeight = 30
	end

	local rowCurrency = self.priceLayout:addRow()
	if rowCurrency then
		rowCurrency.minimumHeight = 60
	end

	local rowAmount = self.priceLayout:addRow()
	if rowAmount then
		rowAmount.minimumHeight = 40
	end

	local rowSave = self.priceLayout:addRow()
	if rowSave then
		rowSave.minimumHeight = 40
	end

	self.pricePanel:addChild(self.priceLayout)

	local idxTitle = rowTitle and rowTitle:index() or 0
	local idxCurrency = rowCurrency and rowCurrency:index() or 1
	local idxAmount = rowAmount and rowAmount:index() or 2
	local idxSave = rowSave and rowSave:index() or 3

	self.selectedItemLabel = ISLabel:new(0, 0, 25, "Select an item", 1, 1, 1, 1, UIFont.Medium, true)
	self.priceLayout:setElement(colLabels:index(), idxTitle, self.selectedItemLabel)

	-- Currency Label and Slot
	self.priceLayout:setElement(
		colLabels:index(),
		idxCurrency,
		ISLabel:new(0, 0, 25, "Currency:", 1, 1, 1, 1, UIFont.Small, true)
	)
	self.currencySlot = ISItemSlot:new(0, 0, 48, 48, nil, self, function(...)
		self:onCurrencyDropped(...)
	end)
	self.currencySlot:initialise()
	self.currencySlot:instantiate()
	self.priceLayout:setElement(colInputs:index(), idxCurrency, self.currencySlot)

	-- Amount Label and Entry
	self.priceLayout:setElement(
		colLabels:index(),
		idxAmount,
		ISLabel:new(0, 0, 25, "Amount:", 1, 1, 1, 1, UIFont.Small, true)
	)
	self.amountEntry = ISTextEntryBox:new("1", 0, 0, 100, 25)
	self.amountEntry:initialise()
	self.amountEntry:instantiate()
	self.amountEntry:setOnlyNumbers(true)
	self.priceLayout:setElement(colInputs:index(), idxAmount, self.amountEntry)

	-- Save Button
	self.saveButton = ISButton:new(0, 0, 100, 25, "SET PRICE", self, function()
		self:onSavePrice()
	end)
	self.saveButton:initialise()
	self.saveButton:instantiate()
	self.priceLayout:setElement(colInputs:index(), idxSave, self.saveButton)

	self:refreshList()
end

function JASM_ShopView_Owner:refreshList()
	self.itemListBox:clear()
	local container = self.entity:getContainer()
	if not container then
		return
	end

	local items = container:getItems()
	local itemTypes = {}
	local modData = self.entity:getModData()
	local prices = modData.shopPrices or {}

	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local type = item:getFullType()
		if not itemTypes[type] then
			itemTypes[type] = item
			local priceInfo = prices[type]
			local itemName = item:getName()
			local label = itemName
			if priceInfo then
				local currencyName = priceInfo.type
				local currencyScript = getScriptManager():getItem(priceInfo.type)
				---@diagnostic disable-next-line: unnecessary-if
				if currencyScript then
					currencyName = currencyScript:getDisplayName()
				end

				label = label .. " (For Sale: " .. priceInfo.count .. "x " .. currencyName .. ")"
			end
			self.itemListBox:addItem(label, { item = item, type = type, price = priceInfo })
		end
	end
end

function JASM_ShopView_Owner:onItemSelected(_item)
	self.selectedItem = _item
	self.selectedItemLabel:setName("Pricing: " .. _item.item:getName())

	if _item.price then
		self.amountEntry:setText(tostring(_item.price.count))
		local currencyScript = getScriptManager():getItem(_item.price.type)
		---@diagnostic disable-next-line: unnecessary-if
		if currencyScript then
			self.currencySlot:setStoredScriptItem(currencyScript)
		end
	else
		self.amountEntry:setText("1")
		self.currencySlot:setStoredScriptItem(nil)
	end
end

function JASM_ShopView_Owner:onCurrencyDropped(_slot, _items)
	local item = _items[1]
	if item then
		self.currencySlot:setStoredScriptItem(item:getScriptItem())
	end
end

function JASM_ShopView_Owner:onSavePrice()
	if not self.selectedItem then
		return
	end

	local currencyType = self.currencySlot.storedScriptItem and self.currencySlot.storedScriptItem:getFullName()
	local count = tonumber(self.amountEntry:getText()) or 1

	if not currencyType then
		return
	end

	local args = {
		x = self.entity:getX(),
		y = self.entity:getY(),
		z = self.entity:getZ(),
		index = self.entity:getObjectIndex(),
		action = "SET_PRICE",
		itemType = self.selectedItem.type,
		priceType = currencyType,
		count = count,
	}

	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
	self:refreshList()
end

function JASM_ShopView_Owner:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)

	if self.layout then
		self.layout:setWidth(_preferredWidth)
		self.layout:setHeight(_preferredHeight)
		self.layout:calculateLayout(_preferredWidth, _preferredHeight)
	end

	if self.priceLayout then
		self.priceLayout:setWidth(self.pricePanel:getWidth())
		self.priceLayout:setHeight(self.pricePanel:getHeight())
		self.priceLayout:calculateLayout(self.pricePanel:getWidth(), self.pricePanel:getHeight())
	end
end

return JASM_ShopView_Owner
