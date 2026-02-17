# Template 3: Lua Client UI Implementation Guide

**Status**: Design specification for single-file views (no modular components yet)  
**Target Files**: 
- `shop_view_owner.lua` - Owner management interface
- `shop_view_customer.lua` - Customer trading interface

---

## Available Components (Entity UI Framework)

### Already Implemented
- ✅ **ISBaseEntityWindow** - Base window container
- ✅ **ISPanel** - Generic container panel
- ✅ **ISTableLayout** - Grid-based layout system
- ✅ **ISLabel** - Text display
- ✅ **ISButton** - Clickable buttons
- ✅ **ISTextEntryBox** - Text input fields
- ✅ **ISScrollingListBox** - Scrollable item lists
- ✅ **ISTiledIconListBox** - Grid-based tile display
- ✅ **ISItemSlot** - Drag-drop item container
- ✅ **ISSpinner** / ISComboBox (likely) - Number/dropdown inputs

### NOT YET IMPLEMENTED - Need Custom Code
- ❌ **ISRadioButton** - Radio button selection (for trade selection)
- ❌ **ISCheckBox** - Checkbox inputs
- ❌ **ISTabPanel** - Tabbed interface
- ❌ **Custom Spinbox** - Numeric increment/decrement
- ❌ **Trade Card Component** - Visual arrow-based transaction display
- ❌ **Validation Tooltip** - Hover tooltips for errors

---

## Architecture: Two Single-File Views

### File 1: `shop_view_owner.lua` (Owner Management)

**Current State**: Uses 50/50 split with item list + price panel  
**Needed Changes**:
1. Change to 35/65 column split
2. Expand from simple "SET PRICE" to full transaction builder
3. Add OFFER + REQUEST sections
4. Add trade list with delete functionality
5. Add validation indicators

**Layout Hierarchy**:
```
JASM_ShopView_Owner (ISPanel)
├── layout (ISTableLayout) - 35/65 split
│   ├── colInventory (35%)
│   │   └── itemListBox (ISScrollingListBox) - Available shop items
│   └── colForm (65%)
│       └── formLayout (ISTableLayout) - Vertical stack
│           ├── headerLabel - "Build Trade for Selected Item"
│           ├── selectionLabel - "Water Bottle - Stock: 12"
│           │
│           ├── [OFFER SECTION]
│           │   ├── offerLabel - "OFFER (Blue background)"
│           │   ├── offerQtyInput (ISTextEntryBox) - Quantity spinner*
│           │   ├── offerDisplay - Shows item + "You have X available"
│           │   └── offerValidation - Green/red indicator
│           │
│           ├── [REQUEST SECTION]
│           │   ├── requestLabel - "REQUEST (Red background)"
│           │   ├── requestQtyInput (ISTextEntryBox) - Quantity
│           │   ├── requestItemInput (ISTextEntryBox) - Item type name
│           │   ├── requestIcon (rendered item texture)
│           │   └── requestValidation - Green/red indicator
│           │
│           ├── summaryCard - "1x Water → 100x Nails" (visual)
│           ├── addButton - "ADD TRADE" (enabled/disabled based on validation)
│           │
│           ├── activeTradeslabel - "Active Trades for [Item]"
│           ├── tradesList (ISScrollingListBox)
│           │   └── Each item: "[Icon] 1x → [Icon] 100x [Delete ×]"
│           │
│           └── footerButtons
│               ├── saveButton - "SAVE ALL"
│               └── cancelButton - "CANCEL"
```

**Key Methods**:
```lua
function JASM_ShopView_Owner:createChildren()
  -- Implement full structure above
end

function JASM_ShopView_Owner:onItemSelected(item)
  -- Set offerDisplay from selected inventory item
  -- Clear REQUEST section
  -- Refresh active trades list for this item
end

function JASM_ShopView_Owner:onOfferQuantityChanged(qty)
  -- Update "You have X available" text
  -- Validate offer doesn't exceed inventory
  -- Recalculate summary card
end

function JASM_ShopView_Owner:onRequestItemChanged(itemType)
  -- Validate item exists in game (getScriptManager():getItem(itemType))
  -- Render item icon if valid, show error if not
  -- Recalculate summary card
end

function JASM_ShopView_Owner:onRequestQuantityChanged(qty)
  -- Update summary card
  -- Validate quantity is positive
end

function JASM_ShopView_Owner:addTrade()
  -- Validate: offer <= inventory, request item valid
  -- Add to activeTrades table
  -- Refresh trades list
  -- Clear form for next entry
end

function JASM_ShopView_Owner:deleteTrade(tradeIndex)
  -- Remove from activeTrades
  -- Refresh list
end

function JASM_ShopView_Owner:saveAll()
  -- Persist activeTrades to modData.shopTrades[itemType]
  -- Send to server command
  -- Close or show confirmation
end

function JASM_ShopView_Owner:validateAddButton()
  -- Return true if: offer <= stock AND request item valid AND both quantities > 0
  -- Disable button if any validation fails
  -- Show tooltip reason if disabled
end

function JASM_ShopView_Owner:calculateLayout(w, h)
  -- Already implemented, ensure 35/65 split respected
end
```

**Validation Rules**:
| Field | Validation | Feedback |
|-------|-----------|----------|
| Offer Qty | Must be > 0 AND <= inventory | "Exceeds stock (have X)" in red |
| Request Qty | Must be > 0 | Numeric validation only |
| Request Item | Must exist in game | Red border + "Item not found" |
| Duplicate | Same offer/request pair | Warning text, prevent add |

---

### File 2: `shop_view_customer.lua` (Customer Trading)

**Current State**: Uses 60/40 split with product grid + details  
**Needed Changes**:
1. Keep grid layout (60/40 good)
2. Add trade selection interface (radio buttons or cards)
3. Add affordability checking
4. Show "max available trades" based on stock

**Layout Hierarchy**:
```
JASM_ShopView_Customer (ISPanel)
├── layout (ISTableLayout) - 60/40 split
│   ├── colGrid (60%)
│   │   └── productGrid (ISTiledIconListBox) - Shop items
│   └── colDetails (40%)
│       └── detailsLayout (ISTableLayout) - Vertical stack
│           ├── headerPanel
│           │   ├── productIcon (rendered texture)
│           │   ├── productName - "Water Bottle"
│           │   └── shopStock - "Shop Stock: 12 units"
│           │
│           ├── description - "Essential for survival..."
│           │
│           ├── [TRADE SELECTION - NEW]
│           │   ├── tradesLabel - "Available Trades:"
│           │   └── tradesList (ISScrollingListBox or custom)
│           │       └── Each trade option:
│           │           ├── radioButton*
│           │           ├── tradeDisplay - "1x → 100x Nails"
│           │           └── (Highlighted if selected)
│           │
│           ├── [AFFORDABILITY CHECK - NEW]
│           │   ├── needsLabel - "You need: 100x Nails"
│           │   ├── haveLabel - "You have: 87x Nails ✓" (green if can afford)
│           │   └── availableLabel - "Available: 12 trades max"
│           │
│           ├── actionButton - "ACCEPT TRADE: Give 1x, Get 100x"
│           └── errorLabel - Red text for failures
```

**Key Methods**:
```lua
function JASM_ShopView_Customer:createChildren()
  -- Implement full structure above
end

function JASM_ShopView_Customer:onProductSelected(product)
  -- Load all trades for this product
  -- Set default to first trade
  -- Show product info
  -- Refresh affordability
end

function JASM_ShopView_Customer:onTradeSelected(tradeIndex)
  -- Set selectedTrade to this index
  -- Update affordability display
  -- Update action button text
end

function JASM_ShopView_Customer:updateAffordability()
  -- Get selected trade's request items
  -- Check player inventory for each item
  -- If player has all: show green checkmark, enable button
  -- If player missing: show red "Insufficient", disable button
  -- Calculate maxCompletions = floor(shopStock / offerQty)
  -- Display "Available: X trades max"
end

function JASM_ShopView_Customer:onAcceptTrade()
  -- Get selected trade
  -- Double-check player has items
  -- Double-check shop has items
  -- Send command to server: "BUY" action
  -- Clear selection, refresh products
end

function JASM_ShopView_Customer:calculateLayout(w, h)
  -- Keep 60/40 split
end
```

**Validation Rules**:
| Check | Condition | Action |
|-------|-----------|--------|
| Can Afford | Player has all request items | Green ✓, enable button |
| Cannot Afford | Player missing items | Red text, disable button |
| Stock Limit | maxCompletions = inventory / offer qty | Show "Available: X" |
| Multiple Trades | Product has 3+ trade options | Show radio/card selector |
| Single Trade | Only 1 trade available | Skip selector, auto-select |

---

## Component Workarounds (Not Yet Available)

### ❌ Radio Buttons
**Workaround**: Use `ISScrollingListBox` with highlighted items
```lua
-- Instead of: <input type="radio">
-- Use: ISScrollingListBox with onmousedown handler
tradesList.onmousedown = function(item)
  selectedTrade = item
  tradesList:setItemAndEnsureVisible(item)
  updateAffordability()
end
```

### ❌ Numeric Spinner (±1, ±10 buttons)
**Workaround**: Use `ISTextEntryBox` with `:setOnlyNumbers(true)`
```lua
-- Instead of: <input type="number" min=1 max=12 spinner>
-- Use: ISTextEntryBox with validation
qtyInput = ISTextEntryBox:new("1", 0, 0, 60, 25)
qtyInput:setOnlyNumbers(true)
-- Manual range checking in onChange handler
```

### ❌ Item Search/Autocomplete
**Workaround**: Type full item type name (e.g., "Base.Nails")
```lua
-- Instead of: <input type="search" datalist="items">
-- Use: ISTextEntryBox with manual validation
itemInput = ISTextEntryBox:new("", 0, 0, 150, 25)
-- Check on blur: getScriptManager():getItem(input:getText())
```

### ❌ Validation Tooltip
**Workaround**: Use colored labels + visual indicators
```lua
-- Instead of: <span title="Error message">
-- Use: Colored ISLabel below input
validationLabel = ISLabel:new(0, 0, 20, "Item not found", 1, 0, 0, 1, UIFont.Small, true)
```

### ❌ Trade Card / Summary Visual
**Workaround**: Render text with icons on custom panel
```lua
-- Instead of: <div class="trade-card">[Icon] 1x → [Icon] 100x</div>
-- Custom function that:
-- 1. Draws offer item texture
-- 2. Draws "1x" text
-- 3. Draws arrow icon (text or emoji)
-- 4. Draws request item texture
-- 5. Draws "100x" text
```

---

## Implementation Checklist

### shop_view_owner.lua
- [ ] Change layout to 35/65 column split
- [ ] Add OFFER section (quantity input + display)
- [ ] Add REQUEST section (quantity + item type inputs)
- [ ] Add real-time validation (green/red borders)
- [ ] Add summary card (arrow-based display)
- [ ] Add ADD TRADE button with validation
- [ ] Add Active Trades list with delete buttons
- [ ] Add SAVE ALL + CANCEL footer
- [ ] Implement onItemSelected handler
- [ ] Implement validation methods
- [ ] Implement addTrade/deleteTrade/saveAll
- [ ] Handle view refresh after server responses

### shop_view_customer.lua
- [ ] Keep 60/40 grid layout
- [ ] Add trade selector (ISScrollingListBox approach)
- [ ] Add affordability check display
- [ ] Add maxCompletions calculation
- [ ] Add action button with dynamic text
- [ ] Implement onProductSelected handler
- [ ] Implement onTradeSelected handler
- [ ] Implement updateAffordability logic
- [ ] Handle trade completion flow
- [ ] Show error messages on failure

---

## Data Structure Examples

### Owner Creating Trade
```lua
-- Form state
draftTrade = {
  selectedItem = "Base.Water",
  itemInventoryCount = 12,
  
  offer = {
    itemType = "Base.Water",
    quantity = 1,
    available = 12
  },
  
  request = {
    itemType = "Base.Nails",
    quantity = 100,
    isValid = true
  }
}

-- After ADD TRADE
activeTrades = {
  {
    id = "trade_001",
    offer = {itemType = "Base.Water", quantity = 1},
    request = {itemType = "Base.Nails", quantity = 100}
  },
  {
    id = "trade_002",
    offer = {itemType = "Base.Water", quantity = 2},
    request = {itemType = "Base.Hammer", quantity = 1}
  }
}
```

### Customer Browsing
```lua
-- Product state
selectedProduct = {
  type = "Base.Water",
  shopStock = 12
}

-- Available trades for this product
availableTrades = {
  {
    offer = {itemType = "Base.Water", quantity = 1},
    request = {itemType = "Base.Nails", quantity = 100}
  },
  {
    offer = {itemType = "Base.Water", quantity = 2},
    request = {itemType = "Base.Hammer", quantity = 1}
  }
}

-- Selected trade state
selectedTrade = 1
playerNeeds = {itemType = "Base.Nails", quantity = 100}
playerHas = 87  -- Count of Base.Nails in inventory
maxCompletions = floor(12 / 1) = 12
canAfford = (87 >= 100) = false
```

---

## Color Scheme (PZ Theme)

```lua
local COLORS = {
  -- Text
  PRIMARY = {1.0, 1.0, 1.0, 1.0},      -- White
  SECONDARY = {0.8, 0.8, 0.8, 1.0},    -- Light gray
  MUTED = {0.6, 0.6, 0.6, 1.0},        -- Dark gray
  
  -- Sections
  OFFER = {0.2, 0.6, 0.9, 1.0},        -- Blue (what shop gives)
  REQUEST = {0.9, 0.3, 0.2, 1.0},      -- Red (what shop wants)
  ARROW = {1.0, 0.6, 0.0, 1.0},        -- Orange (transaction separator)
  
  -- Status
  VALID = {0.2, 0.8, 0.2, 1.0},        -- Green (success)
  INVALID = {0.9, 0.3, 0.2, 1.0},      -- Red (error)
  DISABLED = {0.5, 0.5, 0.5, 1.0},     -- Gray (disabled)
  
  -- Backgrounds
  PANEL_BG = {0.15, 0.15, 0.15, 1.0},  -- Dark
  SECTION_BG = {0.25, 0.25, 0.25, 1.0} -- Slightly lighter
}
```

---

## Migration Notes

Current implementation has basic structure, but needs expansion:
- **shop_view_owner.lua**: Lines 118-223 define single `createChildren()` - expand with full form
- **shop_view_customer.lua**: Lines 110-193 define basic details panel - add trade selector + affordability
- Both use `ISTableLayout` which supports our 35/65 and 60/40 splits
- Both already handle `onItemSelected` callbacks - extend with validation

---

## Testing Checklist

- [ ] Owner can select item from inventory
- [ ] Owner can enter offer quantity (validation shows "Exceeds stock" if > inventory)
- [ ] Owner can enter request item type (validation shows green/red if valid/invalid)
- [ ] Summary card updates in real-time as owner types
- [ ] ADD TRADE button disabled when validation fails
- [ ] Active Trades list populated after adding
- [ ] Delete button removes trade from list
- [ ] SAVE ALL persists to server
- [ ] Customer sees product grid
- [ ] Customer can select product
- [ ] Customer sees all available trades
- [ ] Customer can select different trade
- [ ] Affordability updates when trade selected
- [ ] Action button disabled if can't afford
- [ ] Error message shows what's missing
- [ ] Trade accepted successfully
- [ ] Shop inventory updates after trade

---

## Notes for Future Enhancement

1. **Radio Button Component**: If PZ adds ISRadioButton, replace list approach
2. **Spinner Component**: If PZ adds ISSpinner, replace TextEntryBox approach
3. **Drag-Drop**: ISItemSlot already supports drag-drop for offer item selection
4. **Animated Transition**: Could animate OFFER → REQUEST flow visually
5. **Keyboard Navigation**: Tab through form fields sequentially
6. **Copy/Paste Trade**: Clone existing trade configurations
