require("Entity/ISUI/ISBaseEntityWindow")
require("Entity/ISUI/Controls/ISWidgetEntityHeader")

local JASM_ShopView_Owner = require("jasm/entity_ui/shop_view_owner")
local JASM_ShopView_Customer = require("jasm/entity_ui/shop_view_customer")

---@class JASM_ShopView : ISBaseEntityWindow
---@field viewManager any
JASM_ShopView = ISBaseEntityWindow:derive("JASM_ShopView")

function JASM_ShopView:initialise()
	ISBaseEntityWindow.initialise(self)
end

function JASM_ShopView:createChildren()
	ISBaseEntityWindow.createChildren(self)

	local skin = XuiManager.GetDefaultSkin()
	-- Use the built-in header creation method from ISBaseEntityWindow
	self:createEntityHeader(skin, "S_WidgetEntityHeader_Std", true)

	---@type IsoObject
	local entity = self.entity
	local modData = entity:getModData()
	local isOwner = modData.shopOwnerID == self.player:getUsername()

	if modData.shopType == "SYSTEM" then
		isOwner = self.player:isAccessLevel("Admin")
	end

	if isOwner then
		---@diagnostic disable-next-line: param-type-mismatch
		self.viewManager = JASM_ShopView_Owner:new(0, 0, 100, 100, self.player, self.entity)
	else
		---@diagnostic disable-next-line: param-type-mismatch
		self.viewManager = JASM_ShopView_Customer:new(0, 0, 100, 100, self.player, self.entity)
	end

	self:addChild(self.viewManager.view)
end

function JASM_ShopView:calculateLayout(_preferredWidth, _preferredHeight)
	self:validateSizeBounds()

	local th = self:titleBarHeight()
	-- Force a rigid minimum window size (600x450)
	local width = math.floor(math.max(_preferredWidth or 600, self.minimumWidth))
	local height = math.floor(math.max(_preferredHeight or 450, self.minimumHeight))

	-- Start positioning below the title bar with a small buffer
	local currentY = th + 4
	if self.entityHeader then
		self.entityHeader:setX(0)
		self.entityHeader:setY(currentY)
		self.entityHeader:calculateLayout(width, 0)
		currentY = currentY + math.floor(math.max(20, self.entityHeader:getHeight()))
	end

	if self.viewManager then
		self.viewManager:setX(0)
		self.viewManager:setY(currentY)

		-- Tell the view manager exactly how much space it has (Total - Header)
		local viewW = width
		local viewH = height - currentY
		self.viewManager:calculateLayout(viewW, viewH)
	end

	self:setWidth(width --[[@as integer]])
	self:setHeight(height --[[@as integer]])
end

---@return JASM_ShopView
function JASM_ShopView:new(x, y, width, height, player, entity)
	local entityUiStyle = ISEntityUI.GetEntityUiStyle(entity)
	---@diagnostic disable-next-line: param-type-mismatch
	local o = ISBaseEntityWindow.new(self, x, y, width, height, player, entity, entityUiStyle)
	setmetatable(o, self)
	self.__index = self

	o.minimumWidth = 400
	o.minimumHeight = 300
	local modData = (entity --[[@as any]]):getModData()
	o.title = "Shop: " .. (modData.shopName or "Crate")

	return o
end

function JASM_ShopView:show()
	self:initialise()
	self:addToUIManager()
end

return JASM_ShopView
