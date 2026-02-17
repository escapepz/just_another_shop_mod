require("ISUI/ISPanel")
require("Entity/ISUI/CraftRecipe/ISTiledIconListBox")
require("Entity/ISUI/Controls/ISTableLayout")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@type JASM_ShopView_Customer
local JASM_ShopView_Customer = ISPanel:derive("JASM_ShopView_Customer")

function JASM_ShopView_Customer:initialise()
	ISPanel.initialise(self)
end

function JASM_ShopView_Customer:createChildren()
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0)

	local colGrid = self.layout:addColumnFill()
	local colDetails = self.layout:addColumnFill()
	local mainRow = self.layout:addRowFill()

	self:addChild(self.layout)

	-- Column 1: Product Grid
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
	self.productGrid.callbackTarget = self

	if mainRow then
		self.layout:setElement(colGrid:index(), mainRow:index(), self.productGrid)

		-- Column 2: Details Panel
		self.detailsPanel = ISPanel:new(0, 0, self.width * 0.4, self.height)
		self.detailsPanel:initialise()
		self.layout:setElement(colDetails:index(), mainRow:index(), self.detailsPanel)
	end

	self.detailsLayout = ISTableLayout:new(0, 0, self.detailsPanel.width, self.detailsPanel.height)
	self.detailsLayout:initialise()
	self.detailsLayout:createTable(0, 0)

	local colDetailsNested = self.detailsLayout:addColumnFill()

	local rowTitle = self.detailsLayout:addRow()
	if rowTitle then
		rowTitle.minimumHeight = 40
	end

	local rowPrice = self.detailsLayout:addRow()
	if rowPrice then
		rowPrice.minimumHeight = 40
	end

	local rowButton = self.detailsLayout:addRow()
	if rowButton then
		rowButton.minimumHeight = 40
	end

	local rowError = self.detailsLayout:addRow()
	if rowError then
		rowError.minimumHeight = 40
	end

	self.detailsPanel:addChild(self.detailsLayout)

	local idxTitle = rowTitle and rowTitle:index() or 0
	local idxPrice = rowPrice and rowPrice:index() or 1
	local idxButton = rowButton and rowButton:index() or 2
	local idxError = rowError and rowError:index() or 3

	self.productNameLabel = ISLabel:new(10, 0, 20, "Select a product", 1, 1, 1, 1, UIFont.Medium, true)
	self.detailsLayout:setElement(colDetailsNested:index(), idxTitle, self.productNameLabel)

	self.priceLabel = ISLabel:new(10, 0, 20, "Price: -", 1, 1, 1, 1, UIFont.Small, true)
	self.detailsLayout:setElement(colDetailsNested:index(), idxPrice, self.priceLabel)

	self.buyButton = ISButton:new(10, 0, 120, 25, "EXCHANGE", self, function()
		self:onBuy()
	end)
	self.buyButton:initialise()
	self.buyButton:instantiate()
	self.buyButton.enable = false
	self.detailsLayout:setElement(colDetailsNested:index(), idxButton, self.buyButton)

	self.errorLabel = ISLabel:new(10, 0, 20, "", 1, 0.3, 0.3, 1, UIFont.Small, true)
	self.detailsLayout:setElement(colDetailsNested:index(), idxError, self.errorLabel)

	self:refreshProducts()
end

function JASM_ShopView_Customer:new(x, y, width, height, player, entity)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.player = player
	o.entity = entity
	return o
end

function JASM_ShopView_Customer:createChildren()
	self.layout = ISTableLayout:new(0, 0, self.width, self.height)
	self.layout:initialise()
	self.layout:createTable(0, 0)

	local colGrid = self.layout:addColumnFill()
	local colDetails = self.layout:addColumnFill()
	local mainRow = self.layout:addRowFill()

	self.view:addChild(self.layout)

	-- Column 1: Product Grid
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
	self.productGrid.callbackTarget = self
	if mainRow then
		self.layout:setElement(colGrid:index(), mainRow:index(), self.productGrid)

		-- Column 2: Details Panel
		self.detailsPanel = ISPanel:new(0, 0, self.width * 0.4, self.height)
		self.detailsPanel:initialise()
		self.layout:setElement(colDetails:index(), mainRow:index(), self.detailsPanel)
	end

	self.detailsLayout = ISTableLayout:new(0, 0, self.detailsPanel.width, self.detailsPanel.height)
	self.detailsLayout:initialise()
	self.detailsLayout:createTable(0, 0)

	local colDetails = self.detailsLayout:addColumnFill()

	local rowTitle = self.detailsLayout:addRow()
	if rowTitle then
		rowTitle.minimumHeight = 40
	end

	local rowPrice = self.detailsLayout:addRow()
	if rowPrice then
		rowPrice.minimumHeight = 40
	end

	local rowButton = self.detailsLayout:addRow()
	if rowButton then
		rowButton.minimumHeight = 40
	end

	local rowError = self.detailsLayout:addRow()
	if rowError then
		rowError.minimumHeight = 40
	end

	self.detailsPanel:addChild(self.detailsLayout)

	local idxTitle = rowTitle and rowTitle:index() or 0
	local idxPrice = rowPrice and rowPrice:index() or 1
	local idxButton = rowButton and rowButton:index() or 2
	local idxError = rowError and rowError:index() or 3

	self.productNameLabel = ISLabel:new(10, 0, 20, "Select a product", 1, 1, 1, 1, UIFont.Medium, true)
	self.detailsLayout:setElement(colDetails:index(), idxTitle, self.productNameLabel)

	self.priceLabel = ISLabel:new(10, 0, 20, "Price: -", 1, 1, 1, 1, UIFont.Small, true)
	self.detailsLayout:setElement(colDetails:index(), idxPrice, self.priceLabel)

	self.buyButton = ISButton:new(10, 0, 120, 25, "EXCHANGE", self, function()
		self:onBuy()
	end)
	self.buyButton:initialise()
	self.buyButton:instantiate()
	self.buyButton.enable = false
	self.detailsLayout:setElement(colDetails:index(), idxButton, self.buyButton)

	self.errorLabel = ISLabel:new(10, 0, 20, "", 1, 0.3, 0.3, 1, UIFont.Small, true)
	self.detailsLayout:setElement(colDetails:index(), idxError, self.errorLabel)

	self:refreshProducts()
end

function JASM_ShopView_Customer:refreshProducts()
	self.dataList:clear()
	local modData = self.entity:getModData()
	local prices = modData.shopPrices or {}
	local container = self.entity:getContainer()
	if not container then
		return
	end

	for itemType, priceInfo in pairs(prices) do
		if container:containsType(itemType) then
			self.dataList:add({ type = itemType, price = priceInfo })
		end
	end
	self.productGrid:calculateTiles()
end

function JASM_ShopView_Customer:onRenderProductTile(_tile, _data, _x, _y, _w, _h, _mouseover)
	local itemScript = getScriptManager():getItem(_data.type)
	---@diagnostic disable-next-line: unnecessary-if
	if itemScript then
		local tex = itemScript:getNormalTexture()
		---@diagnostic disable-next-line: unnecessary-if
		if tex then
			self.view:drawTextureScaled(tex, _x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
		end
	end
	if _mouseover then
		self.view:drawRectBorderStatic(_x, _y, _w, _h, 1.0, 1.0, 1.0, 1.0)
	end
end

function JASM_ShopView_Customer:onProductSelected(_data)
	self.selectedProduct = _data
	local itemScript = getScriptManager():getItem(_data.type)
	self.productNameLabel:setName(itemScript:getDisplayName())

	local currencyName = _data.price.type
	local currencyScript = getScriptManager():getItem(_data.price.type)
	---@diagnostic disable-next-line: unnecessary-if
	if currencyScript then
		currencyName = currencyScript:getDisplayName()
	end

	self.priceLabel:setName("Price: " .. _data.price.count .. "x " .. currencyName)

	self:updateBuyButton()
end

function JASM_ShopView_Customer:updateBuyButton()
	if not self.selectedProduct then
		self.buyButton.enable = false
		return
	end

	local playerInv = self.player:getInventory()
	local count = playerInv:getItemCount(self.selectedProduct.price.type)

	if count < self.selectedProduct.price.count then
		self.buyButton.enable = false
		self.errorLabel:setName("Insufficient funds (" .. count .. "/" .. self.selectedProduct.price.count .. ")")
	else
		self.buyButton.enable = true
		self.errorLabel:setName("")
	end
end

function JASM_ShopView_Customer:onBuy()
	if not self.selectedProduct then
		return
	end

	local args = {
		x = self.entity:getX(),
		y = self.entity:getY(),
		z = self.entity:getZ(),
		index = self.entity:getObjectIndex(),
		action = "BUY",
		itemType = self.selectedProduct.type,
	}

	KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
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
