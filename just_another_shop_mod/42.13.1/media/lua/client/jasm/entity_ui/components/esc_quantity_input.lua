-- ============================================================================
-- ESC_QuantityInput
-- Numeric input field with real-time validation feedback
-- Shows validation state: "You have X available" or "Exceeds stock (Y max)"
-- ============================================================================

require("ISUI/ISPanel")
require("ISUI/ISTextEntryBox")
require("ISUI/ISLabel")

---@class ESC_QuantityInput : ISPanel
---@field textInput ISTextEntryBox Text entry field
---@field feedbackLabel ISLabel Status feedback
---@field maxValue number Maximum allowed value
---@field onQuantityChanged function Callback
local ESC_QuantityInput = ISPanel:derive("ESC_QuantityInput")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ESC_QuantityInput:initialise()
	ISPanel.initialise(self)
end

function ESC_QuantityInput:new(x, y, width, height, initialValue, maxValue)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	
	o.initialValue = initialValue or "1"
	o.maxValue = maxValue or 999
	o.lastValidValue = tonumber(initialValue) or 1
	o.isValid = true
	o.feedbackText = ""
	
	return o
end

-- ============================================================================
-- COMPONENT CREATION
-- ============================================================================

function ESC_QuantityInput:createChildren()
	-- Text input field (60% width)
	self.textInput = ISTextEntryBox:new(self.initialValue, 0, 0, self.width * 0.6, 25)
	self.textInput:initialise()
	self.textInput:instantiate()
	self.textInput:setOnlyNumbers(true)
	self:addChild(self.textInput)
	
	-- Feedback label (40% width, positioned right of input)
	self.feedbackLabel = ISLabel:new(
		self.width * 0.6 + 5, 5, 200,
		"",
		1.0, 1.0, 1.0, 1.0,
		UIFont.Small, false
	)
	self:addChild(self.feedbackLabel)
end

-- ============================================================================
-- INPUT VALIDATION
-- ============================================================================

function ESC_QuantityInput:getValue()
	local text = self.textInput:getText()
	return tonumber(text) or 0
end

function ESC_QuantityInput:setValue(value)
	self.textInput:setText(tostring(value))
	self:validate()
end

function ESC_QuantityInput:setMaxValue(maxValue)
	self.maxValue = maxValue
	self:validate()
end

function ESC_QuantityInput:validate()
	local value = self:getValue()
	
	-- Empty or zero
	if value == 0 or self.textInput:getText() == "" then
		self:setInvalid("Enter quantity")
		return false
	end
	
	-- Exceeds max
	if value > self.maxValue then
		self:setInvalid("Exceeds stock (" .. self.maxValue .. " max)")
		return false
	end
	
	-- Valid
	self:setValid("You have " .. self.maxValue .. " available")
	return true
end

function ESC_QuantityInput:setValid(message)
	self.isValid = true
	self.feedbackText = message
	self.feedbackLabel:setName(message)
	self.feedbackLabel:setColor(0.2, 0.8, 0.2, 1.0)  -- Green
	
	if self.onQuantityChanged then
		self.onQuantityChanged(self)
	end
end

function ESC_QuantityInput:setInvalid(message)
	self.isValid = false
	self.feedbackText = message
	self.feedbackLabel:setName(message)
	self.feedbackLabel:setColor(1.0, 0.3, 0.3, 1.0)  -- Red
end

function ESC_QuantityInput:isValidValue()
	return self.isValid
end

function ESC_QuantityInput:getFeedback()
	return self.feedbackText
end

-- ============================================================================
-- RENDERING
-- ============================================================================

function ESC_QuantityInput:render()
	-- Background
	self:drawRectStatic(0, 0, self.width, self.height, 0.15, 0.15, 0.15, 1.0)
	
	-- Border (green if valid, red if invalid)
	if self.isValid then
		self:drawRectBorderStatic(0, 0, self.width, self.height, 0.2, 0.8, 0.2, 1.0)
	else
		self:drawRectBorderStatic(0, 0, self.width, self.height, 1.0, 0.3, 0.3, 1.0)
	end
end

-- ============================================================================
-- LAYOUT
-- ============================================================================

function ESC_QuantityInput:calculateLayout(_preferredWidth, _preferredHeight)
	self:setWidth(_preferredWidth)
	self:setHeight(_preferredHeight)
	
	if self.textInput then
		self.textInput:setWidth(math.floor(_preferredWidth * 0.6))
		self.textInput:setHeight(25)
	end
	
	if self.feedbackLabel then
		self.feedbackLabel:setX(math.floor(_preferredWidth * 0.6) + 5)
		self.feedbackLabel:setY(5)
	end
end

return ESC_QuantityInput
