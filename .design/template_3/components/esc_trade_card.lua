-- ============================================================================
-- ESC_TradeCard
-- Visual transaction display component
-- Shows: [Icon] Qty → [Icon] Qty
-- ============================================================================

require("ISUI/ISPanel")

---@class ESC_TradeCard : ISPanel
---@field trade table {offer: {itemType, quantity}, request: {itemType, quantity}}
---@field showArrow boolean Whether to show arrow separator
---@field callbackTarget any Callback target for clicks
---@field onTradeCardClick function Callback when card clicked
local ESC_TradeCard = ISPanel:derive("ESC_TradeCard")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ESC_TradeCard:initialise()
	ISPanel.initialise(self)
end

function ESC_TradeCard:new(x, y, width, height, trade)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.trade = trade or {
		offer = {itemType = nil, quantity = 1},
		request = {itemType = nil, quantity = 1}
	}
	o.showArrow = true
	o.selected = false
	o.hovered = false
	
	return o
end

-- ============================================================================
-- RENDERING
-- ============================================================================

function ESC_TradeCard:render()
	-- Draw background
	if self.selected then
		self:drawRectStatic(0, 0, self.width, self.height, 1.0, 0.6, 0.0, 0.3)  -- Orange highlight
		self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 0.6, 0.0, 1.0)
	elseif self.hovered then
		self:drawRectStatic(0, 0, self.width, self.height, 1.0, 1.0, 1.0, 0.1)  -- Light white
		self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 1.0, 1.0, 0.5)
	end
	
	-- Draw offer item
	local offerX = 5
	self:renderItemIcon(self.trade.offer.itemType, offerX, 5)
	self:drawText(
		self.trade.offer.quantity .. "×",
		offerX + 40, 15,
		1.0, 1.0, 1.0, 1.0
	)
	
	-- Draw arrow (if enabled)
	if self.showArrow then
		self:drawText(
			"→",
			offerX + 65, 15,
			1.0, 0.6, 0.0, 1.0  -- Orange arrow
		)
	end
	
	-- Draw request item
	local requestX = offerX + 85
	self:renderItemIcon(self.trade.request.itemType, requestX, 5)
	self:drawText(
		self.trade.request.quantity .. "×",
		requestX + 40, 15,
		1.0, 1.0, 1.0, 1.0
	)
end

function ESC_TradeCard:renderItemIcon(itemType, x, y)
	if not itemType then
		-- Placeholder icon for missing item
		self:drawRectStatic(x, y, 32, 32, 0.3, 0.3, 0.3, 1.0)
		self:drawText("?", x + 12, y + 10, 1.0, 1.0, 1.0, 1.0)
		return
	end
	
	local itemScript = getScriptManager():getItem(itemType)
	if itemScript then
		local tex = itemScript:getNormalTexture()
		if tex then
			self:drawTextureScaled(tex, x, y, 32, 32, 1.0, 1.0, 1.0, 1.0)
		else
			self:drawRectStatic(x, y, 32, 32, 0.5, 0.5, 0.5, 1.0)
		end
	else
		-- Item doesn't exist (invalid)
		self:drawRectStatic(x, y, 32, 32, 0.8, 0.3, 0.3, 1.0)  -- Red
		self:drawText("!", x + 12, y + 10, 1.0, 0.0, 0.0, 1.0)
	end
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

function ESC_TradeCard:onMouseMove(dx, dy)
	ISPanel.onMouseMove(self, dx, dy)
end

function ESC_TradeCard:onMouseDown(x, y)
	if self.onTradeCardClick then
		self.onTradeCardClick(self.callbackTarget, self.trade)
	end
	return true
end

function ESC_TradeCard:onMouseEnter(x, y)
	self.hovered = true
	return true
end

function ESC_TradeCard:onMouseExit(x, y)
	self.hovered = false
	return true
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

function ESC_TradeCard:setTrade(trade)
	self.trade = trade
end

function ESC_TradeCard:getTrade()
	return self.trade
end

function ESC_TradeCard:setSelected(selected)
	self.selected = selected
end

function ESC_TradeCard:isSelected()
	return self.selected
end

function ESC_TradeCard:setShowArrow(show)
	self.showArrow = show
end

-- ============================================================================
-- LAYOUT
-- ============================================================================

function ESC_TradeCard:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
end

return ESC_TradeCard
