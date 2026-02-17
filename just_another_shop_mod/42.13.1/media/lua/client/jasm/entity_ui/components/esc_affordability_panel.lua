-- ============================================================================
-- ESC_AffordabilityPanel
-- Multi-line affordability status display
-- Shows: "You need: X items"
--        "You have: Y items ✓" (green if sufficient, red if not)
--        "Available: Z trades max"
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISLabel")

---@class ESC_AffordabilityPanel : ISPanel
---@field needsLabel ISLabel What is needed
---@field haveLabel ISLabel What player has
---@field availableLabel ISLabel How many trades left
---@field needsQty number Required quantity
---@field playerHasQty number Player's current quantity
---@field maxTrades number Maximum times trade can complete
---@field canAfford boolean Whether player has enough
local ESC_AffordabilityPanel = ISPanel:derive("ESC_AffordabilityPanel")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ESC_AffordabilityPanel:initialise()
	ISPanel.initialise(self)
end

function ESC_AffordabilityPanel:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.needsQty = 0
	o.playerHasQty = 0
	o.maxTrades = 0
	o.canAfford = false
	o.needsItemName = "-"
	o.haveItemName = "-"
	
	return o
end

-- ============================================================================
-- COMPONENT CREATION
-- ============================================================================

function ESC_AffordabilityPanel:createChildren()
	-- "You need:" line
	self.needsLabel = ISLabel:new(
		10, 5, 300,
		"You need: -",
		1.0, 1.0, 1.0, 1.0,
		UIFont.Small, false
	)
	self:addChild(self.needsLabel)
	
	-- "You have:" line
	self.haveLabel = ISLabel:new(
		10, 25, 300,
		"You have: -",
		1.0, 1.0, 1.0, 1.0,
		UIFont.Small, false
	)
	self:addChild(self.haveLabel)
	
	-- "Available:" line
	self.availableLabel = ISLabel:new(
		10, 45, 300,
		"Available: -",
		0.8, 0.8, 0.8, 1.0,
		UIFont.Small, false
	)
	self:addChild(self.availableLabel)
end

-- ============================================================================
-- STATE UPDATE
-- ============================================================================

function ESC_AffordabilityPanel:setNeeds(itemType, quantity)
	self.needsQty = quantity
	self.needsItemName = itemType
	
	-- Get item display name
	local itemScript = getScriptManager():getItem(itemType)
	local displayName = itemType
	if itemScript then
		displayName = itemScript:getDisplayName()
	end
	
	self.needsLabel:setName("You need: " .. quantity .. "× " .. displayName)
	self:updateAffordability()
end

function ESC_AffordabilityPanel:setPlayerInventory(itemType, quantity)
	self.playerHasQty = quantity
	
	-- Get item display name
	local itemScript = getScriptManager():getItem(itemType)
	local displayName = itemType
	if itemScript then
		displayName = itemScript:getDisplayName()
	end
	
	-- Determine color based on whether player can afford
	self.canAfford = (quantity >= self.needsQty)
	
	if self.canAfford then
		self.haveLabel:setName("You have: " .. quantity .. "× " .. displayName .. " ✓")
		self.haveLabel:setColor(0.2, 0.8, 0.2, 1.0)  -- Green
	else
		self.haveLabel:setName("You have: " .. quantity .. "× " .. displayName)
		self.haveLabel:setColor(1.0, 0.3, 0.3, 1.0)  -- Red
	end
	
	self:updateAffordability()
end

function ESC_AffordabilityPanel:setMaxTrades(maxTrades)
	self.maxTrades = maxTrades
	
	self.availableLabel:setName("Available: " .. maxTrades .. " trades max")
	if maxTrades == 0 then
		self.availableLabel:setColor(1.0, 0.3, 0.3, 1.0)  -- Red if zero
	else
		self.availableLabel:setColor(0.8, 0.8, 0.8, 1.0)  -- Gray otherwise
	end
end

function ESC_AffordabilityPanel:updateAffordability()
	-- Recalculate overall affordability
	self.canAfford = (self.playerHasQty >= self.needsQty)
end

-- ============================================================================
-- GETTERS
-- ============================================================================

function ESC_AffordabilityPanel:canAffordTrade()
	return self.canAfford
end

function ESC_AffordabilityPanel:getNeedsQty()
	return self.needsQty
end

function ESC_AffordabilityPanel:getPlayerHasQty()
	return self.playerHasQty
end

function ESC_AffordabilityPanel:getMaxTrades()
	return self.maxTrades
end

function ESC_AffordabilityPanel:getMissingQty()
	if self.playerHasQty >= self.needsQty then
		return 0
	end
	return self.needsQty - self.playerHasQty
end

-- ============================================================================
-- RENDERING
-- ============================================================================

function ESC_AffordabilityPanel:render()
	-- Draw semi-transparent background
	self:drawRectStatic(0, 0, self.width, self.height, 0.2, 0.2, 0.2, 0.5)
	
	-- Draw border (green if can afford, red if cannot)
	if self.canAfford then
		self:drawRectBorderStatic(0, 0, self.width, self.height, 0.2, 0.8, 0.2, 0.5)
	else
		self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 0.3, 0.3, 0.5)
	end
end

-- ============================================================================
-- LAYOUT
-- ============================================================================

function ESC_AffordabilityPanel:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	if self.needsLabel then
		self.needsLabel:setWidth(_preferredWidth - 20)
	end
	if self.haveLabel then
		self.haveLabel:setWidth(_preferredWidth - 20)
	end
	if self.availableLabel then
		self.availableLabel:setWidth(_preferredWidth - 20)
	end
end

return ESC_AffordabilityPanel
