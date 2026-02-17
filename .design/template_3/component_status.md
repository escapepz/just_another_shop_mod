# Component Availability Status

## Summary
All **essential** components are available. Some **optional** UI improvements require workarounds.

---

## Critical Components (✅ All Available)

| Component | File | Status | Notes |
|-----------|------|--------|-------|
| **ISBaseEntityWindow** | Entity/ISUI/ISBaseEntityWindow | ✅ | Base container - used in shop_view.lua |
| **ISPanel** | ISUI/ISPanel | ✅ | Generic container - used in owner/customer views |
| **ISTableLayout** | Entity/ISUI/Controls/ISTableLayout | ✅ | Grid layout - powers 35/65 and 60/40 splits |
| **ISLabel** | ISLabel | ✅ | Text display - already used throughout |
| **ISButton** | ISButton | ✅ | Clickable buttons - already used for SET PRICE, EXCHANGE |
| **ISTextEntryBox** | ISTextEntryBox | ✅ | Text input - used for quantity/item type entry |
| **ISScrollingListBox** | ISUI/ISScrollingListBox | ✅ | Item list - used for inventory, trades, products |
| **ISTiledIconListBox** | Entity/ISUI/CraftRecipe/ISTiledIconListBox | ✅ | Grid tiles - used for product display |
| **ISItemSlot** | Entity/ISUI/Controls/ISItemSlot | ✅ | Drag-drop items - used for currency selection |

---

## Optional Components (❌ Missing - Need Workarounds)

| Component | Used For | Workaround | Complexity |
|-----------|----------|-----------|-----------|
| **ISRadioButton** | Trade selection in customer view | Use ISScrollingListBox with highlight | Low |
| **ISCheckBox** | Multi-select scenarios | Use ISButton with toggle state | Low |
| **ISSpinner** | Numeric ±1/±10 buttons | Use ISTextEntryBox + validation | Low |
| **ISSlider** | Range selection | Use ISTextEntryBox numeric only | Low |
| **ISComboBox** | Item type dropdown | Use ISTextEntryBox + validation | Low |
| **ISTabPanel** | View switching (not needed) | Use visible/hidden panels | N/A |
| **Tooltip Component** | Hover error messages | Use colored ISLabel feedback text | Low |
| **Icon Renderer** | Custom trade card visualization | Use view:drawTextureScaled() | Medium |

---

## Architecture Components (Existing Code)

### From shop_view.lua
```lua
-- Already working:
✅ ISBaseEntityWindow inheritance
✅ createEntityHeader() for title bar
✅ View routing (owner vs customer)
✅ Entity/player access
✅ Minimum window sizing
✅ Layout calculation pipeline
```

### From shop_view_owner.lua (Current)
```lua
-- Already working:
✅ ISPanel base
✅ ISTableLayout 2-column layout
✅ ISScrollingListBox for items
✅ ISLabel for display text
✅ ISTextEntryBox for quantity
✅ ISButton for "SET PRICE"
✅ ISItemSlot for currency selection
✅ Module structure with new/initialise/createChildren

-- Need to expand:
❌ Multi-section form layout (only has 1 section)
❌ Real-time validation display
❌ Trade list management
❌ Summary card visualization
```

### From shop_view_customer.lua (Current)
```lua
-- Already working:
✅ ISPanel base
✅ ISTableLayout 2-column layout
✅ ISTiledIconListBox for products
✅ ISLabel for product name/price
✅ ISButton for "EXCHANGE"
✅ Basic affordability check
✅ Module structure

-- Need to expand:
❌ Trade selector (multiple options)
❌ Affordability display panel
❌ maxCompletions calculation
❌ Error message feedback
```

---

## Build Instructions by Component

### Level 1: Core Layout (No Changes Needed)
Already handles:
- Window sizing and positioning
- Column/row grid management
- Child panel nesting
- Layout recalculation

**Use existing code**:
```lua
local layout = ISTableLayout:new(0, 0, width, height)
layout:initialise()
layout:createTable(0, 0)

local col1 = layout:addColumn(0.35)     -- 35% width
local col2 = layout:addColumnFill()     -- 65% width
local row = layout:addRowFill()

layout:setElement(col1:index(), row:index(), leftPanel)
layout:setElement(col2:index(), row:index(), rightPanel)
```

### Level 2: Input Fields (Minor Wrapper Needed)
**Quantity input** - Use existing ISTextEntryBox:
```lua
local qtyInput = ISTextEntryBox:new("1", 0, 0, 60, 25)
qtyInput:initialise()
qtyInput:instantiate()
qtyInput:setOnlyNumbers(true)

-- Add validation in callback
qtyInput.onChange = function(self)
  local qty = tonumber(self:getText()) or 1
  if qty > maxAvailable then
    -- Show validation error
  end
end
```

**Item type input** - Use existing ISTextEntryBox:
```lua
local itemInput = ISTextEntryBox:new("Base.Nails", 0, 0, 150, 25)
itemInput:initialise()
itemInput:instantiate()

-- Validate on blur/enter
itemInput.onTextChange = function(self)
  local itemType = self:getText()
  local scriptItem = getScriptManager():getItem(itemType)
  if scriptItem then
    validationLabel:setName("✓")
    validationLabel:setColor(0, 1, 0, 1)  -- Green
  else
    validationLabel:setName("Item not found")
    validationLabel:setColor(1, 0, 0, 1)  -- Red
  end
end
```

### Level 3: Trade Selection (Workaround Required)
**Radio button replacement** - Use ISScrollingListBox:
```lua
local tradesList = ISScrollingListBox:new(0, 0, width, height)
tradesList:initialise()
tradesList:instantiate()

-- Each trade becomes a list item with custom rendering
for i, trade in ipairs(availableTrades) do
  tradesList:addItem(
    string.format("%dx → %dx %s",
      trade.offer.quantity,
      trade.request.quantity,
      trade.request.itemType),
    {trade = trade, index = i}
  )
end

tradesList.onmousedown = function(item)
  selectedTrade = item.trade
  selectedTradeIndex = item.index
  updateAffordability()
  -- Visual highlight handled by ISScrollingListBox
end
```

### Level 4: Trade Card / Summary (Custom Draw Required)
**Arrow-based transaction display**:
```lua
function renderTradeCard(view, trade, x, y, width, height)
  -- Draw offer icon
  local offerScript = getScriptManager():getItem(trade.offer.itemType)
  if offerScript then
    local tex = offerScript:getNormalTexture()
    view:drawTextureScaled(tex, x, y, 32, 32, 1, 1, 1, 1)
  end
  
  -- Draw offer quantity
  view:drawText(
    trade.offer.quantity .. "×",
    x + 40, y + 8,
    1, 1, 1, 1
  )
  
  -- Draw arrow
  view:drawText(
    "→",
    x + 70, y + 8,
    1, 0.6, 0, 1  -- Orange
  )
  
  -- Draw request icon
  local requestScript = getScriptManager():getItem(trade.request.itemType)
  if requestScript then
    local tex = requestScript:getNormalTexture()
    view:drawTextureScaled(tex, x + 100, y, 32, 32, 1, 1, 1, 1)
  end
  
  -- Draw request quantity
  view:drawText(
    trade.request.quantity .. "×",
    x + 140, y + 8,
    1, 1, 1, 1
  )
end
```

### Level 5: Validation Feedback (Label-Based)
**Real-time error display**:
```lua
local validationLabel = ISLabel:new(10, 0, 20, "", 1, 0, 0, 1, UIFont.Small, true)

function updateValidation()
  local offerQty = tonumber(offerInput:getText()) or 0
  local requestType = requestInput:getText()
  
  if offerQty > inventoryCount then
    validationLabel:setName("⚠ Exceeds stock (" .. inventoryCount .. " available)")
    validationLabel:setColor(1, 0, 0, 1)
    addTradeButton:setEnable(false)
  elseif not getScriptManager():getItem(requestType) then
    validationLabel:setName("⚠ Item not found")
    validationLabel:setColor(1, 0, 0, 1)
    addTradeButton:setEnable(false)
  else
    validationLabel:setName("")
    addTradeButton:setEnable(true)
  end
end
```

---

## Implementation Roadmap

### Phase 1: Foundation (Currently Done)
- [x] Window/layout structure
- [x] Header with entity info
- [x] Basic routing (owner vs customer)
- [x] 50/50 or 60/40 column splits

### Phase 2: Owner View (Needs Work)
- [ ] Change to 35/65 split
- [ ] Add OFFER section
- [ ] Add REQUEST section
- [ ] Implement validation
- [ ] Add summary card
- [ ] Add trade list
- [ ] Implement addTrade/deleteTrade

### Phase 3: Customer View (Needs Work)
- [ ] Keep 60/40 split
- [ ] Add trade selector
- [ ] Add affordability display
- [ ] Implement trade selection
- [ ] Add maxCompletions logic

### Phase 4: Polish (Optional)
- [ ] Styled validation indicators
- [ ] Hover tooltips
- [ ] Keyboard navigation
- [ ] Animation effects

---

## Legacy Code Reference

**Location**: `.tmp/codebase/projectzomboid_lua_codebase.xml`

### Expected Content
- ISBaseEntityWindow structure
- ISTableLayout usage patterns
- ISScrollingListBox callbacks
- Color definitions and theming
- Drawing/rendering API calls

### Use Cases
1. Reference ISTableLayout column/row operations
2. Find ISScrollingListBox item rendering patterns
3. Understand texture drawing with view:drawTextureScaled()
4. Reference color constant definitions (COLORS table)
5. Find validation pattern examples

---

## Notes

✅ = Ready to use in code
❌ = Need workaround or custom implementation
⚠️ = Available but may need adaptation

**Bottom line**: You have everything needed to build the full Template 3 UI. The missing components are nice-to-have UI improvements, not blockers.
