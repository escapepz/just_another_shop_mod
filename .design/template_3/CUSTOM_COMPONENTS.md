# Custom Components (ESC Prefix)

5 custom components designed for Template 3 UI. All files in `.design/template_3/`, ready to integrate into actual Lua views.

---

## Component Inventory

| Component | File | Purpose | Complexity |
|-----------|------|---------|-----------|
| **ESC_TradeCard** | ESC_TradeCard.lua | Visual transaction display | Medium |
| **ESC_QuantityInput** | ESC_QuantityInput.lua | Numeric input with validation | Low |
| **ESC_ItemInput** | ESC_ItemInput.lua | Item type input with validation | Low |
| **ESC_TradeSelector** | ESC_TradeSelector.lua | Radio button replacement | Low |
| **ESC_AffordabilityPanel** | ESC_AffordabilityPanel.lua | Multi-line status display | Low |

---

## 1. ESC_TradeCard

**Purpose**: Visual transaction display showing both sides of a trade  
**Visual**: `[Icon] 1× Water → [Icon] 100× Nails`  
**Used In**: Owner view (summary card) + Customer view (trade selector)

### Usage

```lua
require("path/to/ESC_TradeCard")

local trade = {
  offer = {itemType = "Base.Water", quantity = 1},
  request = {itemType = "Base.Nails", quantity = 100}
}

local card = ESC_TradeCard:new(10, 10, 300, 50, trade)
card:initialise()
parent:addChild(card)

-- Handle clicks
card.onTradeCardClick = function(target, selectedTrade)
  print("Trade selected:", selectedTrade.offer.quantity)
end
card.callbackTarget = self
```

### Methods

```lua
:new(x, y, width, height, trade)           -- Create card
:setTrade(trade)                           -- Update trade data
:getTrade()                                -- Get current trade
:setSelected(bool)                         -- Highlight card
:isSelected()                              -- Check if selected
:setShowArrow(bool)                        -- Show/hide arrow
:render()                                  -- Draw card
:calculateLayout(w, h)                     -- Update layout
```

### Styling

- **Selected**: Orange highlight + border
- **Hovered**: Light white border
- **Arrow**: Orange color (#FF6600)
- **Invalid Item**: Red box with "!"
- **Missing Item**: Gray box with "?"

---

## 2. ESC_QuantityInput

**Purpose**: Numeric input field with real-time validation feedback  
**Shows**: "You have 12 available" or "Exceeds stock (12 max)"  
**Used In**: Owner view (OFFER qty + REQUEST qty inputs)

### Usage

```lua
require("path/to/ESC_QuantityInput")

local qtyInput = ESC_QuantityInput:new(10, 10, 200, 50, "1", 12)
qtyInput:initialise()
qtyInput:createChildren()
parent:addChild(qtyInput)

-- Handle changes
qtyInput.onQuantityChanged = function(self)
  print("Qty changed to:", self:getValue())
end

-- Update max value
qtyInput:setMaxValue(20)

-- Get value
local qty = qtyInput:getValue()

-- Check validity
if qtyInput:isValidValue() then
  -- Valid
end
```

### Methods

```lua
:new(x, y, width, height, initialValue, maxValue)
:getValue()                                -- Get numeric value
:setValue(value)                           -- Set value
:setMaxValue(max)                          -- Update max allowed
:validate()                                -- Re-validate current value
:isValidValue()                            -- Check if valid
:getFeedback()                             -- Get error message
```

### Validation Rules

- **Empty**: "Enter quantity"
- **Exceeds Max**: "Exceeds stock (X max)"
- **Valid**: "You have X available" (green)

### Colors

- **Valid**: Green border + green text
- **Invalid**: Red border + red text

---

## 3. ESC_ItemInput

**Purpose**: Item type input field with real-time game item validation  
**Shows**: ✓ (green) if valid, ✗ (red) if invalid  
**Used In**: Owner view (REQUEST item type input)

### Usage

```lua
require("path/to/ESC_ItemInput")

local itemInput = ESC_ItemInput:new(10, 10, 300, 60, "Base.Nails")
itemInput:initialise()
itemInput:createChildren()
parent:addChild(itemInput)

-- Handle item selection
itemInput.onItemChanged = function(self, itemScript)
  if itemScript then
    print("Valid item:", itemScript:getDisplayName())
  end
end

-- Get value
local itemType = itemInput:getValue()

-- Get script (if valid)
local script = itemInput:getItemScript()

-- Check validity
if itemInput:isValidValue() then
  -- Item exists in game
end

-- Get last valid item (for fallback)
local lastValid = itemInput:getLastValidItem()
```

### Methods

```lua
:new(x, y, width, height, initialItemType)
:getValue()                                -- Get item type string
:setValue(value)                           -- Set item type
:validate()                                -- Check if item exists
:isValidValue()                            -- Check if valid
:getItemScript()                           -- Get script object
:getLastValidItem()                        -- Get last valid script
```

### Validation Rules

- **Empty**: "Enter item type (e.g., Base.Nails)"
- **Not Found**: "Item not found: BaseXXX"
- **Valid**: Shows item icon + green border

### Layout

- **60%**: Text input field
- **20%**: Validation icon (✓/✗)
- **Below**: Error message label (if any)

---

## 4. ESC_TradeSelector

**Purpose**: Radio button-like selection from multiple trades  
**Visual**: ○ 1× → 100× Nails (with radio button)  
**Used In**: Customer view (trade selection interface)

### Usage

```lua
require("path/to/ESC_TradeSelector")

local trades = {
  {offer = {itemType = "Base.Water", quantity = 1}, request = {itemType = "Base.Nails", quantity = 100}},
  {offer = {itemType = "Base.Water", quantity = 2}, request = {itemType = "Base.Hammer", quantity = 1}},
  {offer = {itemType = "Base.Water", quantity = 3}, request = {itemType = "Base.Ammo", quantity = 50}}
}

local selector = ESC_TradeSelector:new(10, 10, 400, 150, trades)
selector:initialise()
parent:addChild(selector)

-- Handle selection
selector.onTradeSelected = function(target, trade, index)
  print("Selected trade index:", index)
  print("Give:", trade.offer.quantity, "Get:", trade.request.quantity)
end
selector.callbackTarget = self

-- Get selected
local trade = selector:getSelectedTrade()
local index = selector:getSelectedIndex()

-- Programmatic selection
selector:selectTrade(2)  -- Select 2nd trade
```

### Methods

```lua
:new(x, y, width, height, trades)
:setTrades(trades)                         -- Set all trades
:addTrade(trade)                           -- Add single trade
:getTrade(index)                           -- Get by index
:selectTrade(index)                        -- Select trade
:getSelectedTrade()                        -- Get selected
:getSelectedIndex()                        -- Get index
:getTradeCount()                           -- Count trades
:render()                                  -- Draw selector
:calculateLayout(w, h)                     -- Update layout
```

### Visual Elements

- **Radio Circle**: 16×16 px, white border
- **Selected**: Orange filled circle inside
- **Hovered**: Light white background highlight
- **Icons**: 25×25 px for offer/request items
- **Arrow**: Orange → separator

---

## 5. ESC_AffordabilityPanel

**Purpose**: Multi-line affordability status display  
**Shows**: What player needs, has, and can afford  
**Used In**: Customer view (affordability check display)

### Usage

```lua
require("path/to/ESC_AffordabilityPanel")

local affordPanel = ESC_AffordabilityPanel:new(10, 10, 400, 70)
affordPanel:initialise()
affordPanel:createChildren()
parent:addChild(affordPanel)

-- Update status
affordPanel:setNeeds("Base.Nails", 100)           -- What is needed
affordPanel:setPlayerInventory("Base.Nails", 87) -- What player has
affordPanel:setMaxTrades(12)                      -- Possible completions

-- Check if player can afford
if affordPanel:canAffordTrade() then
  -- Player has enough items
else
  -- Show how much is missing
  local missing = affordPanel:getMissingQty()  -- 13 (needs 100, has 87)
end

-- Get all values
local needs = affordPanel:getNeedsQty()      -- 100
local has = affordPanel:getPlayerHasQty()    -- 87
local max = affordPanel:getMaxTrades()       -- 12
```

### Methods

```lua
:new(x, y, width, height)
:setNeeds(itemType, quantity)              -- Set required items
:setPlayerInventory(itemType, quantity)    -- Set player's items
:setMaxTrades(maxTrades)                   -- Set available trades count
:canAffordTrade()                          -- Check if affordable
:getNeedsQty()                             -- Get required qty
:getPlayerHasQty()                         -- Get player qty
:getMaxTrades()                            -- Get max trades
:getMissingQty()                           -- Get shortfall (if any)
:updateAffordability()                     -- Recalculate
:calculateLayout(w, h)                     -- Update layout
```

### Display Format

```
You need: 100× Nails
You have: 87× Nails                    (red if insufficient)
Available: 12 trades max
```

### Colors

- **"You need:"**: White
- **"You have:"**: Green if sufficient (✓), red if insufficient
- **"Available:"**: Gray (red if 0 trades)
- **Border**: Green if affordable, red if not

---

## Integration Guide

### Into shop_view_owner.lua

```lua
require("path/to/ESC_QuantityInput")
require("path/to/ESC_ItemInput")
require("path/to/ESC_TradeCard")

-- In createChildren():

-- OFFER section
local offerQtyInput = ESC_QuantityInput:new(10, 30, 200, 50, "1", inventoryCount)
offerQtyInput:initialise()
offerQtyInput:createChildren()
formPanel:addChild(offerQtyInput)

-- REQUEST section
local requestItemInput = ESC_ItemInput:new(10, 90, 300, 60, "Base.Nails")
requestItemInput:initialise()
requestItemInput:createChildren()
formPanel:addChild(requestItemInput)

local requestQtyInput = ESC_QuantityInput:new(10, 155, 200, 50, "1", 999)
requestQtyInput:initialise()
requestQtyInput:createChildren()
formPanel:addChild(requestQtyInput)

-- Summary card
local summaryCard = ESC_TradeCard:new(10, 210, 350, 50, currentTrade)
summaryCard:initialise()
formPanel:addChild(summaryCard)
```

### Into shop_view_customer.lua

```lua
require("path/to/ESC_TradeSelector")
require("path/to/ESC_AffordabilityPanel")

-- In createChildren():

-- Trade selector
local tradeSelector = ESC_TradeSelector:new(10, 50, 380, 150, availableTrades)
tradeSelector:initialise()
detailsPanel:addChild(tradeSelector)

-- Affordability panel
local affordPanel = ESC_AffordabilityPanel:new(10, 210, 380, 70)
affordPanel:initialise()
affordPanel:createChildren()
detailsPanel:addChild(affordPanel)

-- In onTradeSelected():
tradeSelector.onTradeSelected = function(target, trade, index)
  affordPanel:setNeeds(trade.request.itemType, trade.request.quantity)
  affordPanel:setPlayerInventory(trade.request.itemType, playerHasQty)
  affordPanel:setMaxTrades(floor(shopStock / trade.offer.quantity))
end
```

---

## Event Flow Examples

### Owner Creating Trade

```lua
-- User selects item from inventory
onItemSelected(item)
  offerQtyInput:setMaxValue(inventoryCount)

-- User enters offer quantity
offerQtyInput.onQuantityChanged = function(self)
  updateSummaryCard()
  validateAddButton()
end

-- User enters request item
requestItemInput.onItemChanged = function(self, script)
  if script then
    updateSummaryCard()
    validateAddButton()
  end
end

-- User enters request quantity
requestQtyInput.onQuantityChanged = function(self)
  updateSummaryCard()
  validateAddButton()
end

-- Validate and add
function validateAddButton()
  if offerQtyInput:isValidValue() and
     requestItemInput:isValidValue() and
     requestQtyInput:isValidValue() then
    addButton:setEnable(true)
  else
    addButton:setEnable(false)
  end
end
```

### Customer Selecting Trade

```lua
-- User clicks trade in selector
tradeSelector.onTradeSelected = function(target, trade, index)
  selectedTrade = trade
  
  -- Update affordability display
  local needs = trade.request.quantity
  local itemType = trade.request.itemType
  local playerHas = playerInv:getItemCount(itemType)
  
  affordPanel:setNeeds(itemType, needs)
  affordPanel:setPlayerInventory(itemType, playerHas)
  
  -- Calculate max times this trade can repeat
  local shopStock = container:getItemCount(selectedProduct.type)
  local maxTrades = floor(shopStock / trade.offer.quantity)
  affordPanel:setMaxTrades(maxTrades)
  
  -- Enable/disable accept button
  if affordPanel:canAffordTrade() then
    acceptButton:setEnable(true)
  else
    acceptButton:setEnable(false)
  end
end
```

---

## Design Notes

### No External Dependencies
- All components use existing PZ framework (ISPanel, ISLabel, ISTextEntryBox)
- No additional libraries required
- Compatible with all PZ versions supporting Entity UI

### Single-File Design
- Each component is self-contained
- Can be used independently or together
- No inter-component dependencies

### Responsive Layout
- All components support dynamic width/height
- calculateLayout() called on parent resize
- Works with ISTableLayout nesting

### Game Integration
- Uses getScriptManager() for item validation
- Uses player:getInventory() for inventory checks
- Uses entity:getContainer() for shop inventory

### Color Scheme
All components use consistent colors:
- **Valid/Success**: #33FF33 (0.2, 0.8, 0.2)
- **Invalid/Error**: #FF6633 (1.0, 0.3, 0.3)
- **Warning/Interactive**: #FF9900 (1.0, 0.6, 0.0)
- **Text**: #FFFFFF (1.0, 1.0, 1.0)

---

## Status

✅ **All 5 components complete and ready to use**  
✅ **Full method documentation provided**  
✅ **Integration examples included**  
✅ **No blockers or dependencies**

Ready to integrate into actual view files in `42.13.1/media/lua/client/jasm/entity_ui/`
