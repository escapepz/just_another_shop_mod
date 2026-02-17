# Component Reference & Usage Guide

Quick lookup for all UI components available in the Entity UI framework.

---

## Core Container Components

### ISBaseEntityWindow
**Status**: ✅ Available  
**Location**: `Entity/ISUI/ISBaseEntityWindow`  
**Current Usage**: `shop_view.lua` (line 1)

```lua
require("Entity/ISUI/ISBaseEntityWindow")
local JASM_ShopView = ISBaseEntityWindow:derive("JASM_ShopView")

function JASM_ShopView:new(x, y, width, height, player, entity)
  local o = ISBaseEntityWindow.new(self, x, y, width, height, player, entity, style)
  return o
end
```

**Methods**:
- `:initialise()` - Initialize window
- `:createChildren()` - Add child elements
- `:calculateLayout(w, h)` - Position children
- `:titleBarHeight()` - Get title bar height
- `:show()` - Display window
- `:addChild(child)` - Add UI element

---

### ISPanel
**Status**: ✅ Available  
**Location**: `ISUI/ISPanel`  
**Current Usage**: `shop_view_owner.lua` (line 1), `shop_view_customer.lua` (line 1)

```lua
require("ISUI/ISPanel")
local myPanel = ISPanel:new(x, y, width, height)
myPanel:initialise()
myPanel:addChild(child)
```

**Methods**:
- `:new(x, y, w, h)` - Create panel
- `:initialise()` - Initialize
- `:addChild(child)` - Add UI element
- `:setWidth(w)`, `:setHeight(h)` - Resize
- `:getWidth()`, `:getHeight()` - Get size

---

## Layout Components

### ISTableLayout
**Status**: ✅ Available  
**Location**: `Entity/ISUI/Controls/ISTableLayout`  
**Current Usage**: `shop_view_owner.lua` (line 3), `shop_view_customer.lua` (line 3)

```lua
require("Entity/ISUI/Controls/ISTableLayout")

local layout = ISTableLayout:new(0, 0, width, height)
layout:initialise()
layout:createTable(0, 0)

-- Add columns (width in pixels or fill)
local col1 = layout:addColumn(100)        -- Fixed 100px
local col2 = layout:addColumnFill()       -- Remaining space
local col3 = layout:addColumn(0.35)       -- 35% of available

-- Add rows (height in pixels or fill)
local row1 = layout:addRow()              -- Auto height
local row2 = layout:addRowFill()          -- Fill remaining

-- Place element at row/column intersection
layout:setElement(col1:index(), row1:index(), myPanel)

-- Calculate and apply layout
layout:calculateLayout(width, height)
```

**Methods**:
- `:new(x, y, w, h)` - Create layout
- `:initialise()` - Initialize
- `:createTable(rows, cols)` - Reset table
- `:addColumn(width)` - Add fixed-width column
- `:addColumnFill()` - Add flexible column
- `:addRow()` - Add fixed-height row (usually 0 = auto)
- `:addRowFill()` - Add flexible row
- `:setElement(col, row, element)` - Place element
- `:calculateLayout(w, h)` - Apply layout
- `:setWidth(w)`, `:setHeight(h)` - Resize

**35/65 Split Pattern**:
```lua
local col1 = layout:addColumn(0.35)       -- 35% width
local col2 = layout:addColumnFill()       -- Remaining 65%
```

**60/40 Split Pattern**:
```lua
local col1 = layout:addColumnFill()       -- 60% (first fill gets extra)
local col2 = layout:addColumn(0.4)        -- 40% fixed
```

---

## Text Display

### ISLabel
**Status**: ✅ Available  
**Location**: `ISUI/ISLabel`  
**Current Usage**: `shop_view_owner.lua` (line 75), `shop_view_customer.lua` (line 84)

```lua
-- ISLabel:new(x, y, height, title, r, g, b, a, font, bold)
local label = ISLabel:new(10, 0, 20, "My Label", 1, 1, 1, 1, UIFont.Small, true)

-- Color components (0.0 to 1.0)
label:setColor(1.0, 0.0, 0.0, 1.0)  -- Red, fully opaque

-- Font options
-- UIFont.Small
-- UIFont.Medium
-- UIFont.Large
-- UIFont.XLarge

-- Update text
label:setName("New text")
```

**Common Color Values**:
```lua
WHITE      = {1.0, 1.0, 1.0, 1.0}
BLACK      = {0.0, 0.0, 0.0, 1.0}
RED        = {1.0, 0.0, 0.0, 1.0}
GREEN      = {0.0, 1.0, 0.0, 1.0}
BLUE       = {0.0, 0.0, 1.0, 1.0}
YELLOW     = {1.0, 1.0, 0.0, 1.0}
ORANGE     = {1.0, 0.5, 0.0, 1.0}
GRAY       = {0.5, 0.5, 0.5, 1.0}

-- For validation:
VALID      = {0.2, 0.8, 0.2, 1.0}    -- Green
INVALID    = {1.0, 0.3, 0.3, 1.0}    -- Red
WARNING    = {1.0, 0.8, 0.0, 1.0}    -- Orange
DISABLED   = {0.5, 0.5, 0.5, 1.0}    -- Gray
```

---

## Input Components

### ISTextEntryBox
**Status**: ✅ Available  
**Location**: `ISUI/ISTextEntryBox`  
**Current Usage**: `shop_view_owner.lua` (line 92), `shop_view_customer.lua` - not used

```lua
-- ISTextEntryBox:new(text, x, y, width, height)
local input = ISTextEntryBox:new("1", 0, 0, 80, 25)
input:initialise()
input:instantiate()

-- Numeric-only input
input:setOnlyNumbers(true)

-- Get/set text
local value = input:getText()
input:setText("100")

-- Number conversion
local qty = tonumber(input:getText()) or 1
```

**Methods**:
- `:getText()` - Get current text
- `:setText(text)` - Set text
- `:setOnlyNumbers(bool)` - Restrict to numbers only
- `:initialise()` - Initialize
- `:instantiate()` - Prepare for rendering

**For Quantity Input**:
```lua
local qtyInput = ISTextEntryBox:new("1", 0, 0, 60, 25)
qtyInput:initialise()
qtyInput:instantiate()
qtyInput:setOnlyNumbers(true)
```

**For Item Type Input**:
```lua
local itemInput = ISTextEntryBox:new("Base.Nails", 0, 0, 150, 25)
itemInput:initialise()
itemInput:instantiate()
-- No :setOnlyNumbers() - allow dots for type names like "Base.Item"
```

---

## Buttons

### ISButton
**Status**: ✅ Available  
**Location**: `ISUI/ISButton`  
**Current Usage**: `shop_view_owner.lua` (line 98), `shop_view_customer.lua` (line 87)

```lua
-- ISButton:new(x, y, width, height, title, target, callback)
local button = ISButton:new(10, 0, 100, 25, "CLICK ME", self, function()
  self:onButtonClicked()
end)
button:initialise()
button:instantiate()

-- Enable/disable
button:setEnable(true)
button:setEnable(false)

-- Get enabled state
if button:isEnable() then
  -- ...
end
```

**Methods**:
- `:setEnable(bool)` - Enable/disable
- `:isEnable()` - Check if enabled
- `:initialise()` - Initialize
- `:instantiate()` - Prepare for rendering

---

## List Components

### ISScrollingListBox
**Status**: ✅ Available  
**Location**: `ISUI/ISScrollingListBox`  
**Current Usage**: `shop_view_owner.lua` (line 26), `shop_view_customer.lua` - not used yet

```lua
local listBox = ISScrollingListBox:new(0, 0, width, height)
listBox:initialise()
listBox:instantiate()
listBox.drawBorder = true

-- Add items
listBox:addItem("Item 1", {data = "value1"})
listBox:addItem("Item 2", {data = "value2"})

-- Handle selection
listBox.onmousedown = function(item)
  print("Selected:", item.data)
  -- item contains what you passed to addItem()
end

-- Clear all items
listBox:clear()

-- Select item programmatically
listBox:setItemAndEnsureVisible(item)

-- Get selected item
local item = listBox:getSelectedItem()

-- Scroll to item
listBox:ensureVisible(item)
```

**For Owner's Trade List**:
```lua
tradesList:addItem(
  "1× Water → 100× Nails",
  {trade = tradeObject, index = tradeIndex}
)
```

**For Customer's Trade Selector**:
```lua
tradeSelector:addItem(
  "1× → 100× Nails",
  {trade = tradeObject, index = tradeIndex}
)
tradeSelector.onmousedown = function(item)
  self:onTradeSelected(item)
end
```

---

### ISTiledIconListBox
**Status**: ✅ Available  
**Location**: `Entity/ISUI/CraftRecipe/ISTiledIconListBox`  
**Current Usage**: `shop_view_customer.lua` (line 28)

```lua
require("Entity/ISUI/CraftRecipe/ISTiledIconListBox")

local dataList = ArrayList.new()
local grid = ISTiledIconListBox:new(0, 0, width, height, dataList)
grid:initialise()
grid:instantiate()

-- Add data
dataList:add({type = "Base.Water"})
dataList:add({type = "Base.Nails"})

-- Render each tile
grid.onRenderTile = function(tile, data, x, y, w, h, mouseover)
  -- data = the object from dataList
  local itemScript = getScriptManager():getItem(data.type)
  if itemScript then
    local tex = itemScript:getNormalTexture()
    grid:drawTextureScaled(tex, x, y, w, h, 1, 1, 1, 1)
  end
  if mouseover then
    grid:drawRectBorderStatic(x, y, w, h, 1, 1, 1, 1)
  end
end

-- Handle click
grid.onClickTile = function(data)
  self:onProductSelected(data)
end

-- Recalculate tile layout
grid:calculateTiles()
```

---

## Item Selection

### ISItemSlot
**Status**: ✅ Available  
**Location**: `Entity/ISUI/Controls/ISItemSlot`  
**Current Usage**: `shop_view_owner.lua` (line 81)

```lua
require("Entity/ISUI/Controls/ISItemSlot")

local slot = ISItemSlot:new(0, 0, 48, 48, nil)  -- 48x48 default size
slot:initialise()
slot:instantiate()

-- Set an item by script
local itemScript = getScriptManager():getItem("Base.Nails")
slot:setStoredScriptItem(itemScript)

-- Handle item dropped
slot.onItemSelected = function(slot, items)
  local item = items[1]
  if item then
    slot:setStoredScriptItem(item:getScriptItem())
  end
end

-- Get stored item
local storedItem = slot.storedScriptItem
if storedItem then
  local fullName = storedItem:getFullName()
end
```

---

## Game API Integration

### Getting Item Information
```lua
local scriptMgr = getScriptManager()

-- Get item by type
local itemScript = scriptMgr:getItem("Base.Nails")

if itemScript then
  local displayName = itemScript:getDisplayName()
  local texture = itemScript:getNormalTexture()
  local fullName = itemScript:getFullName()
end
```

### Container Access
```lua
local entity = self.entity
local container = entity:getContainer()

if container then
  -- Get item count by type
  local count = container:getItemCount("Base.Water")
  
  -- Get all items
  local items = container:getItems()
  for i = 0, items:size() - 1 do
    local item = items:get(i)
    local type = item:getFullType()
    local count = item:getCount()
  end
end
```

### Player Inventory
```lua
local player = self.player
local playerInv = player:getInventory()

-- Get item count
local hasNails = playerInv:getItemCount("Base.Nails")

-- Check if player has enough
if hasNails >= requiredAmount then
  -- Can trade
end
```

---

## Drawing Utilities

### Drawing on View (ISPanel)
```lua
-- In ISPanel subclass:

function MyPanel:render()
  -- Draw texture
  self:drawTextureScaled(texture, x, y, w, h, r, g, b, a)
  
  -- Draw filled rectangle
  self:drawRectStatic(x, y, w, h, r, g, b, a)
  
  -- Draw rectangle border
  self:drawRectBorderStatic(x, y, w, h, r, g, b, a)
  
  -- Draw text
  self:drawText("My text", x, y, r, g, b, a)
end
```

---

## Color Constants

```lua
-- Available in PZ
UIFont.Small
UIFont.Medium
UIFont.Large
UIFont.XLarge
UIFont.Huge

-- Color formatting (RGBA)
local r, g, b, a = 1.0, 0.0, 0.0, 1.0  -- Red, fully opaque
local r, g, b, a = 0.5, 0.5, 0.5, 0.8  -- Gray, 80% opaque
```

---

## Component Patterns

### Form Section Pattern
```lua
-- Layout for form section
local sectionPanel = ISPanel:new(0, 0, width, 50)
sectionPanel:initialise()

-- Label
local label = ISLabel:new(10, 0, 20, "Section Title", 1, 1, 1, 1, UIFont.Small, true)
sectionPanel:addChild(label)

-- Input
local input = ISTextEntryBox:new("", 10, 25, 150, 25)
input:initialise()
input:instantiate()
sectionPanel:addChild(input)

-- Add to layout
layout:setElement(col:index(), row:index(), sectionPanel)
```

### List Pattern
```lua
-- Create list
local list = ISScrollingListBox:new(0, 0, 300, 200)
list:initialise()
list:instantiate()
list.drawBorder = true

-- Populate
for _, item in ipairs(myData) do
  list:addItem(item.name, item)
end

-- Handle selection
list.onmousedown = function(item)
  self:onItemSelected(item)
end

-- Add to parent
parent:addChild(list)
```

### Grid Pattern
```lua
-- Create grid
local dataList = ArrayList.new()
local grid = ISTiledIconListBox:new(0, 0, 300, 300, dataList)
grid:initialise()
grid:instantiate()

-- Populate
for _, data in ipairs(myData) do
  dataList:add(data)
end

-- Render tiles
grid.onRenderTile = function(tile, data, x, y, w, h, mouseover)
  -- Custom rendering here
end

-- Handle clicks
grid.onClickTile = function(data)
  self:onTileClicked(data)
end

-- Apply layout
grid:calculateTiles()

-- Add to parent
parent:addChild(grid)
```

---

## Summary Table

| Component | Status | File | Purpose |
|-----------|--------|------|---------|
| ISBaseEntityWindow | ✅ | Entity/ISUI/ISBaseEntityWindow | Window container |
| ISPanel | ✅ | ISUI/ISPanel | Generic container |
| ISTableLayout | ✅ | Entity/ISUI/Controls/ISTableLayout | Grid layout |
| ISLabel | ✅ | ISUI/ISLabel | Text display |
| ISButton | ✅ | ISUI/ISButton | Clickable button |
| ISTextEntryBox | ✅ | ISUI/ISTextEntryBox | Text input |
| ISScrollingListBox | ✅ | ISUI/ISScrollingListBox | Scrollable list |
| ISTiledIconListBox | ✅ | Entity/ISUI/CraftRecipe/ISTiledIconListBox | Icon grid |
| ISItemSlot | ✅ | Entity/ISUI/Controls/ISItemSlot | Drag-drop item |
| ISRadioButton | ❌ | N/A | Radio button (use list instead) |
| ISCheckBox | ❌ | N/A | Checkbox (use button instead) |
| ISSpinner | ❌ | N/A | Number spinner (use textbox instead) |

---

## Next Steps

1. Reference this document when building UI components
2. Check `code_structure.lua` for working examples
3. Test each component in isolation before integrating
4. Use existing code in `shop_view_owner.lua` as pattern reference
