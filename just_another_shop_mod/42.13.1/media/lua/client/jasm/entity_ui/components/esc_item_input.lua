-- ============================================================================
-- ESC_ItemInput
-- Item type input field with real-time validation
-- Shows: item icon (green checkmark if valid, red X if invalid)
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISTextEntryBox")
require("ISUI/ISLabel")

---@class ESC_ItemInput : ISPanel
---@field textInput ISTextEntryBox Text entry for item type
---@field iconPanel ISPanel Shows validation icon
---@field feedbackLabel ISLabel Error message
---@field itemScript ISBaseScriptItem Current item script
---@field isValid boolean Whether item exists in game
---@field onItemChanged function Callback
local ESC_ItemInput = ISPanel:derive("ESC_ItemInput")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ESC_ItemInput:initialise()
	ISPanel.initialise(self)
end

function ESC_ItemInput:new(x, y, width, height, initialItemType)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.initialItemType = initialItemType or "Base.Nails"
	o.itemScript = nil
	o.isValid = false
	o.lastValidItem = nil
	
	return o
end

-- ============================================================================
-- COMPONENT CREATION
-- ============================================================================

function ESC_ItemInput:createChildren()
	-- Text input field (70% width)
	self.textInput = ISTextEntryBox:new(self.initialItemType, 0, 0, self.width * 0.7, 25)
	self.textInput:initialise()
	self.textInput:instantiate()
	self:addChild(self.textInput)
	
	-- Icon display area (20% width) - shows ✓ or ✗
	self.iconPanel = ISPanel:new(self.width * 0.7 + 3, 0, 25, 25)
	self.iconPanel:initialise()
	self:addChild(self.iconPanel)
	
	-- Error message label (positioned below input)
	self.feedbackLabel = ISLabel:new(
		0, 30, self.width,
		"",
		1.0, 0.3, 0.3, 1.0,
		UIFont.Small, false
	)
	self:addChild(self.feedbackLabel)
	
	-- Initial validation
	self:validate()
end

-- ============================================================================
-- ITEM VALIDATION
-- ============================================================================

function ESC_ItemInput:getValue()
	return self.textInput:getText()
end

function ESC_ItemInput:setValue(value)
	self.textInput:setText(value)
	self:validate()
end

function ESC_ItemInput:validate()
	local itemType = self:getValue()
	
	-- Empty input
	if itemType == "" or itemType == nil then
		self:setInvalid("Enter item type (e.g., Base.Nails)")
		return false
	end
	
	-- Check if item exists in game
	local itemScript = getScriptManager():getItem(itemType)
	if not itemScript then
		self:setInvalid("Item not found: " .. itemType)
		return false
	end
	
	-- Valid item found
	self:setValid(itemScript)
	return true
end

function ESC_ItemInput:setValid(itemScript)
	self.isValid = true
	self.itemScript = itemScript
	self.lastValidItem = itemScript
	self.feedbackLabel:setName("")  -- Clear error message
	self.feedbackLabel:setColor(0.2, 0.8, 0.2, 1.0)
	
	if self.onItemChanged then
		self.onItemChanged(self, itemScript)
	end
end

function ESC_ItemInput:setInvalid(message)
	self.isValid = false
	self.itemScript = nil
	self.feedbackLabel:setName(message)
	self.feedbackLabel:setColor(1.0, 0.3, 0.3, 1.0)
end

function ESC_ItemInput:isValidValue()
	return self.isValid
end

function ESC_ItemInput:getItemScript()
	return self.itemScript
end

function ESC_ItemInput:getLastValidItem()
	return self.lastValidItem
end

-- ============================================================================
-- RENDERING
-- ============================================================================

function ESC_ItemInput:render()
	-- Background
	self:drawRectStatic(0, 0, self.width, 25, 0.15, 0.15, 0.15, 1.0)
	
	-- Border (green if valid, red if invalid)
	if self.isValid then
		self:drawRectBorderStatic(0, 0, self.width, 25, 0.2, 0.8, 0.2, 1.0)
	else
		self:drawRectBorderStatic(0, 0, self.width, 25, 1.0, 0.3, 0.3, 1.0)
	end
	
	-- Render validation icon in icon panel
	self:renderValidationIcon()
end

function ESC_ItemInput:renderValidationIcon()
	local iconX = self.width * 0.7 + 3
	
	if self.isValid then
		-- Green checkmark
		self:drawRectStatic(iconX, 0, 25, 25, 0.2, 0.8, 0.2, 0.2)
		self:drawText("✓", iconX + 5, 5, 0.2, 0.8, 0.2, 1.0)
		
		-- Also draw item icon if available
		if self.itemScript then
			local tex = self.itemScript:getNormalTexture()
			if tex then
				self:drawTextureScaled(tex, iconX + 28, 0, 25, 25, 1.0, 1.0, 1.0, 1.0)
			end
		end
	else
		-- Red X
		self:drawRectStatic(iconX, 0, 25, 25, 1.0, 0.3, 0.3, 0.2)
		self:drawText("✗", iconX + 5, 5, 1.0, 0.3, 0.3, 1.0)
	end
end

-- ============================================================================
-- LAYOUT
-- ============================================================================

function ESC_ItemInput:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	if self.textInput then
		self.textInput:setWidth(math.floor(_preferredWidth * 0.7))
		self.textInput:setHeight(25)
	end
	
	if self.iconPanel then
		self.iconPanel:setX(math.floor(_preferredWidth * 0.7) + 3)
		self.iconPanel:setY(0)
		self.iconPanel:setWidth(25)
		self.iconPanel:setHeight(25)
	end
	
	if self.feedbackLabel then
		self.feedbackLabel:setX(0)
		self.feedbackLabel:setY(30)
		self.feedbackLabel:setWidth(_preferredWidth)
	end
end

return ESC_ItemInput
