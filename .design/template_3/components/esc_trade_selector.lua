-- ============================================================================
-- ESC_TradeSelector
-- Radio button-like component for selecting from multiple trade options
-- Visual: ○ 1× Water → 100× Nails
-- ============================================================================

require("ISUI/ISPanel")

---@class ESC_TradeSelector : ISPanel
---@field trades table[] Array of trade objects
---@field selectedIndex number Currently selected trade (1-based)
---@field tradeHeight number Height of each trade item
---@field onTradeSelected function Callback when trade selected
---@field callbackTarget any Callback target
local ESC_TradeSelector = ISPanel:derive("ESC_TradeSelector")

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local TRADE_HEIGHT = 40
local RADIO_SIZE = 16
local PADDING = 5

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ESC_TradeSelector:initialise()
	ISPanel.initialise(self)
end

function ESC_TradeSelector:new(x, y, width, height, trades)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.trades = trades or {}
	o.selectedIndex = 1
	o.tradeHeight = TRADE_HEIGHT
	o.hoveredIndex = nil
	
	return o
end

-- ============================================================================
-- TRADE MANAGEMENT
-- ============================================================================

function ESC_TradeSelector:setTrades(trades)
	self.trades = trades or {}
	self.selectedIndex = 1
end

function ESC_TradeSelector:addTrade(trade)
	table.insert(self.trades, trade)
end

function ESC_TradeSelector:getTrade(index)
	if index < 1 or index > #self.trades then
		return nil
	end
	return self.trades[index]
end

function ESC_TradeSelector:selectTrade(index)
	if index >= 1 and index <= #self.trades then
		self.selectedIndex = index
		if self.onTradeSelected then
			self.onTradeSelected(self.callbackTarget, self.trades[index], index)
		end
	end
end

function ESC_TradeSelector:getSelectedTrade()
	return self.trades[self.selectedIndex]
end

function ESC_TradeSelector:getSelectedIndex()
	return self.selectedIndex
end

function ESC_TradeSelector:getTradeCount()
	return #self.trades
end

-- ============================================================================
-- RENDERING
-- ============================================================================

function ESC_TradeSelector:render()
	-- Draw background
	self:drawRectStatic(0, 0, self.width, self.height, 0.15, 0.15, 0.15, 1.0)
	self:drawRectBorderStatic(0, 0, self.width, self.height, 0.4, 0.4, 0.4, 1.0)
	
	-- Draw each trade option
	for i, trade in ipairs(self.trades) do
		local y = (i - 1) * self.tradeHeight
		
		if y > self.height then
			break  -- Don't render below visible area
		end
		
		self:renderTradeItem(trade, i, y)
	end
end

function ESC_TradeSelector:renderTradeItem(trade, index, y)
	local isSelected = (index == self.selectedIndex)
	local isHovered = (index == self.hoveredIndex)
	
	-- Background highlight
	if isSelected then
		self:drawRectStatic(0, y, self.width, self.tradeHeight, 1.0, 0.6, 0.0, 0.2)  -- Orange
		self:drawRectBorderStatic(0, y, self.width, self.tradeHeight, 1.0, 0.6, 0.0, 1.0)
	elseif isHovered then
		self:drawRectStatic(0, y, self.width, self.tradeHeight, 1.0, 1.0, 1.0, 0.1)
	end
	
	-- Radio button circle
	local radioX = PADDING
	local radioY = y + (self.tradeHeight - RADIO_SIZE) / 2
	
	-- Draw circle
	self:drawRectBorderStatic(radioX, radioY, RADIO_SIZE, RADIO_SIZE, 1.0, 1.0, 1.0, 1.0)
	
	-- Draw filled circle if selected
	if isSelected then
		self:drawRectStatic(
			radioX + 4, radioY + 4,
			RADIO_SIZE - 8, RADIO_SIZE - 8,
			1.0, 0.6, 0.0, 1.0  -- Orange fill
		)
	end
	
	-- Draw trade content
	self:renderTradeContent(trade, radioX + RADIO_SIZE + 10, y)
end

function ESC_TradeSelector:renderTradeContent(trade, x, y)
	local contentY = y + (self.tradeHeight - 20) / 2
	
	-- Offer item and quantity
	self:renderTradeIcon(trade.offer.itemType, x, y + 5)
	self:drawText(
		trade.offer.quantity .. "×",
		x + 35, contentY,
		1.0, 1.0, 1.0, 1.0
	)
	
	-- Arrow
	self:drawText(
		"→",
		x + 55, contentY,
		1.0, 0.6, 0.0, 1.0  -- Orange
	)
	
	-- Request item and quantity
	self:renderTradeIcon(trade.request.itemType, x + 75, y + 5)
	self:drawText(
		trade.request.quantity .. "×",
		x + 110, contentY,
		1.0, 1.0, 1.0, 1.0
	)
	
	-- Request item name
	local reqScript = getScriptManager():getItem(trade.request.itemType)
	local reqName = trade.request.itemType
	if reqScript then
		reqName = reqScript:getDisplayName()
	end
	
	self:drawText(
		reqName,
		x + 150, contentY,
		1.0, 1.0, 0.6, 1.0  -- Yellow
	)
end

function ESC_TradeSelector:renderTradeIcon(itemType, x, y)
	if not itemType then
		self:drawRectStatic(x, y, 25, 25, 0.3, 0.3, 0.3, 1.0)
		return
	end
	
	local itemScript = getScriptManager():getItem(itemType)
	if itemScript then
		local tex = itemScript:getNormalTexture()
		if tex then
			self:drawTextureScaled(tex, x, y, 25, 25, 1.0, 1.0, 1.0, 1.0)
		else
			self:drawRectStatic(x, y, 25, 25, 0.5, 0.5, 0.5, 1.0)
		end
	else
		self:drawRectStatic(x, y, 25, 25, 0.8, 0.3, 0.3, 1.0)  -- Red for invalid
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function ESC_TradeSelector:onMouseMove(dx, dy)
	-- Calculate which trade is hovered
	local mouseY = self:getMouseY()
	if mouseY >= 0 and mouseY < self.height then
		self.hoveredIndex = math.floor(mouseY / self.tradeHeight) + 1
		if self.hoveredIndex > #self.trades then
			self.hoveredIndex = nil
		end
	else
		self.hoveredIndex = nil
	end
end

function ESC_TradeSelector:onMouseDown(x, y)
	local tradeIndex = math.floor(y / self.tradeHeight) + 1
	if tradeIndex >= 1 and tradeIndex <= #self.trades then
		self:selectTrade(tradeIndex)
		return true
	end
	return false
end

function ESC_TradeSelector:onMouseExit(x, y)
	self.hoveredIndex = nil
end

-- ============================================================================
-- LAYOUT
-- ============================================================================

function ESC_TradeSelector:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
end

return ESC_TradeSelector
