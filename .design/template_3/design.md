# Template 3: Unit-Based Barter System Design (Advanced)

**Reference**: Building on Template 2 with fundamental architectural shift
- `.design/template_2/design.md` — Foundation (simple pricing model)
- `.design/template_2/design.html` — Visual reference
- `.design/template_3/design.html` — Full visualization with trading mechanics

**Key Evolution**: From **single-direction pricing** (shop gives 1 item, customer pays fixed price) to a **bidirectional transaction system** where both OFFER (what shop gives) and REQUEST (what shop gets) are independently configurable.

---

## 1. Core Philosophy: Unit-Based Trading

Your shop operates on **bundles and trades**, not fixed prices. If the owner has 12 water bottles:
- They can offer `1x bottle for 100x nails`
- They can offer `2x bottles for 1x baseball bat`
- They can offer `3x bottles for 50x ammo`

This is fundamentally different from Template 2, which treated "what you give" as fixed (1 bottle) and only varied "what you receive" (100 nails, 1 hammer, etc.).

### **Transaction Pair Concept**
```
┌─────────────────────────────────────┐
│ OFFER (What shop gives)             │
│ [Quantity] × [Item Type]            │
│                                     │
│ REQUEST (What shop wants)           │
│ [Quantity] × [Item Type]            │
│                                     │
│ [ADD TRADE] Button                  │
└─────────────────────────────────────┘
```

---

## 2. Owner View: "Bundle Transaction Manager"

### **Layout Structure (35/65 Column Split)**

Changed from 50/50 to accommodate:
- **Left Column (35%)**: Inventory list (same as Template 2)
- **Right Column (65%)**: Narrower, focused transaction builder with vertical stacking

### **Right Column Structure (Vertical Stack)**

#### **Section A: Header**
- Small label: "Build Trade for Selected Item"
- Current selection indicator (e.g., "Water Bottle - Stock: 12")

#### **Section B: OFFER Builder (What Shop Gives)**
- **Row 1 (Static, ~40px)**: "OFFER" label with visual emphasis
- **Row 2 (Static, ~45px)**: 
  - **Left Input**: `[Spinbox/Textbox]` for quantity (range: 1 to inventory total)
  - **Right Display**: Item name + available stock indicator
  - **Icon**: Auto-populated from selected inventory item
  - **Live Feedback**: "You have 12 available" in gray text
  
#### **Section C: REQUEST Builder (What Shop Wants)**
- **Row 3 (Static, ~40px)**: "REQUEST" label with visual emphasis
- **Row 4 (Static, ~45px)**:
  - **Left Input**: `[Spinbox]` for quantity (range: 1 to 999)
  - **Right Input**: `[TextBox]` for item type (e.g., "Base.Nails")
  - **Icon Preview**: Shows item icon if valid, or placeholder if not
  - **Validation**: Green border if item exists, red if not
  
#### **Section D: Offer/Request Summary**
- **Row 5 (Static, ~50px)**: Visual "Trade Card"
  ```
  [Bottle Icon] 1x Water  →  [Nails Icon] 100x Nails
  ```
  - Displays both sides of transaction visually
  - Updates in real-time as user types

#### **Section E: Action Button**
- **Row 6 (Static, ~35px)**: "ADD TRADE" button
  - **Primary**: Green, enabled when validation passes
  - **Disabled**: Gray, if REQUEST item is invalid or OFFER exceeds inventory
  - **Tooltip**: Shows reason for disabled state

#### **Section F: Active Trades (For Selected Item)**
- **Row 7 (Static, ~25px)**: "Active Trades for [Item Name]" header
- **Row 8 (Fill, scrollable)**: `ISScrollingListBox` showing all trades
  - **Each Trade Item Display**:
    ```
    [Bottle Icon] 1x  →  [Nails Icon] 100x  [Delete]
    [Bottle Icon] 2x  →  [Bat Icon] 1x      [Delete]
    ```
  - Arrow icon visually separates offer from request
  - Hover highlights for interaction
  - Delete button removes trade

#### **Section G: Footer Actions**
- **Row 9 (Static, ~35px)**: "SAVE ALL" + "CANCEL" buttons

### **Data Structure: Transaction Pairs**

```lua
-- Old Template 2:
modData.shopListings = {
  ["Base.Water"] = {
    {exchangeFor = "Base.Nails", count = 100},
    {exchangeFor = "Base.Hammer", count = 1}
  }
}

-- New Template 3 (Unit-Based):
modData.shopTrades = {
  ["Base.Water"] = {
    {
      id = "trade_001",
      offer = {itemType = "Base.Water", quantity = 1},
      request = {itemType = "Base.Nails", quantity = 100},
      maxRepeats = 12  -- Calculated from inventory
    },
    {
      id = "trade_002",
      offer = {itemType = "Base.Water", quantity = 2},
      request = {itemType = "Base.Hammer", quantity = 1},
      maxRepeats = 6   -- Inventory ÷ offer quantity
    }
  }
}
```

### **Validation Rules**

| Rule | Check | Action |
|------|-------|--------|
| **Stock Limit** | Offer quantity > inventory | Disable button, show "Exceeds stock" |
| **Item Validity** | Request item doesn't exist in game | Red border on input, show error icon |
| **Duplicate Trade** | Same offer/request pair already exists | Show warning, prevent duplicate |
| **Valid Quantity** | Both quantities are positive integers | Enable button |

---

## 3. Customer View: "Advanced Trade Discovery"

### **Layout (Same 60/40 split as Template 2)**

The customer experience improves because now they see **multiple ways to get items** with different price points.

#### **Details Panel (Right Column)**

**Key Addition**: Trade selection interface when multiple trades exist

- **Row 1**: Item header (icon + name + inventory qty)
- **Row 2**: Item description
- **Row 3 (NEW)**: Trade selector (if multiple trades available)
  ```
  ┌─────────────────────────────────────┐
  │ Available Trades:                   │
  │ ○ 1x  →  100x Nails                 │ (Selected)
  │ ○ 2x  →  1x Baseball Bat            │
  │ ○ 3x  →  50x Ammo                   │
  └─────────────────────────────────────┘
  ```
  - Radio buttons or clickable cards
  - Shows both offer and request visually
  - Highlights which trade is selected
  
- **Row 4**: Affordability check
  ```
  Selected Trade: 1x Water for 100x Nails
  You have: 87x Nails  ✓ (GREEN)
  Available: 12 trades max
  ```
  
- **Row 5**: Action button
  - Text: "ACCEPT: Give 1x Water, Get 100x Nails"
  - Disabled if player doesn't have required items

### **Customer-Side Trade Validation**

When customer selects a trade:
1. **Check Inventory**: Does player have 100 nails?
2. **Check Stock**: Does shop have (12 ÷ 1) = 12 possible trades?
3. **Show Availability**: "Can complete this trade up to 12 times"

---

## 4. Visual Improvements

### **Transaction Arrow Icon**
Instead of text-heavy listings, use an arrow visual:
- `[Icon] Qty` `→` `[Icon] Qty`
- Instantly clear what's being traded
- Saves space, increases readability

### **Color Coding**
| Element | Color | Purpose |
|---------|-------|---------|
| OFFER Section | #3498db (Blue) | What shop gives (output) |
| REQUEST Section | #e74c3c (Red) | What shop wants (input) |
| Arrow Icon | #f39c12 (Orange) | Visual transaction separator |
| Valid Item | #27ae60 (Green) | Validation success |
| Invalid Item | #e74c3c (Red) | Validation error |

---

## 5. Comparison: Template 2 vs. Template 3

| Aspect | Template 2 | Template 3 | Benefit |
|--------|-----------|-----------|---------|
| **Trading Model** | Single offer, multiple requests | Bidirectional pairs (offer + request) | Real barter system, not just pricing |
| **Owner Input** | Type request item + amount | Quantity + item for both sides | Clear, symmetrical interface |
| **Column Ratio** | 50/50 | 35/65 | Narrower, less overwhelming form |
| **Data Structure** | `{exchangeFor, count}` | `{offer, request, maxRepeats}` | Tracks inventory limits dynamically |
| **Customer View** | Single action per item | Choose from multiple trades | More choice, better UX |
| **Validation** | Basic item check | Stock limits + affordability check | Prevents impossible trades |
| **Visual Clarity** | Text-based listings | Arrow icon trade cards | Instant visual understanding |

---

## 6. State Management

### **Owner Session**
```lua
ownerUI = {
  selectedItemInInventory = "Base.Water",
  
  draftTrade = {
    offer = {
      itemType = "Base.Water",
      quantity = 1,
      maxAvailable = 12
    },
    request = {
      itemType = "Base.Nails",
      quantity = 100,
      isValid = true
    },
    validationError = nil
  },
  
  activeTrades = {},  -- All trades for selected item
  isDirty = false     -- Has unsaved changes
}
```

### **Customer Session**
```lua
customerUI = {
  selectedItemInShop = "Base.Water",
  
  availableTrades = {
    { offer = {qty=1}, request = {qty=100} },
    { offer = {qty=2}, request = {qty=1} },
    { offer = {qty=3}, request = {qty=50} }
  },
  
  selectedTrade = 1,  -- Which trade is selected
  playerCanAfford = true,
  maxCompletions = 12 -- How many times this trade can happen
}
```

---

## 7. Event Flow: Complete Trade Lifecycle

### **Owner: Create Trade Flow**
1. Owner selects "Water Bottle" from inventory (shows 12 in stock)
2. Owner sets OFFER: Quantity `1`
3. Owner sets REQUEST: Item type `Base.Nails`, Quantity `100`
4. System validates: "Base.Nails exists ✓, quantity valid ✓"
5. Visual summary shows: `[Bottle] 1x → [Nails] 100x`
6. Owner clicks "ADD TRADE" → Appended to activeTrades list
7. Owner clicks "SAVE ALL" → Persisted to modData.shopTrades
8. Active trades list updates with new entry

### **Customer: Browse & Complete Trade Flow**
1. Customer opens shop, clicks "Water Bottle" in grid
2. Details panel loads all available trades for Water
3. System displays 3 trades with radio buttons
4. Customer clicks 1st trade (1x Water for 100x Nails)
5. System checks: Player has 100 nails? Yes ✓
6. System calculates: 12 ÷ 1 = 12 possible completions
7. Affordability text shows: "You have 87x Nails ✓ Available: 12 trades"
8. Customer clicks "ACCEPT TRADE"
9. Transaction: Remove 100 nails from player, add 1 water to player, update shop inventory
10. Details panel refreshes (might show "Available: 11 trades" now)

---

## 8. Advanced Features

### **Dynamic Max Repeats Calculation**
```lua
function calculateMaxRepeats(inventoryQty, offerQty)
  return floor(inventoryQty / offerQty)
end

-- Example:
-- 12 bottles, offer 1 each → 12 possible trades
-- 12 bottles, offer 2 each → 6 possible trades
-- 12 bottles, offer 3 each → 4 possible trades
```

### **Inventory Synchronization**
- When shop stock changes (customer completes trade), max repeats recalculates
- Customer sees real-time "Available: X trades" updates
- Owner can see which trades are "exhausted" due to low stock

### **Trade Bundling**
- Support "combo" trades in future versions
- Example: "Give 1x Water + 5x Nails, Get 1x Hammer"
- Framework already handles multiple items if needed

---

## 9. Migration from Template 2 to Template 3

1. **Update Data Structure**: Convert `{exchangeFor, count}` → `{offer, request}`
2. **Change Owner Layout**: 50/50 → 35/65 column split
3. **Add OFFER Section**: New input for "how many you're giving"
4. **Add REQUEST Section**: Move validation here (was in Template 2)
5. **Update Summary Card**: Display transaction visually with arrow
6. **Update Customer View**: Add trade selector for multiple options
7. **Add Affordability Logic**: Check player inventory before allowing trade
8. **Implement maxRepeats**: Calculate and display to both owner and customer

---

## 10. Design Principles (Cumulative)

| Principle | Application |
|-----------|-------------|
| **Sizing** | 35/65 column split using `addColumn(0.35)` + `addColumnFill()` |
| **Grid Responsiveness** | Same dynamic `tileWidth` calculation as Template 2 |
| **Nesting** | Parent calls `calculateLayout()` on all child panels |
| **Anchoring** | Spring rows push buttons to footer |
| **Validation** | Real-time feedback on both OFFER and REQUEST |
| **Visual Clarity** | Arrow icons replace text-heavy listings |
| **State Separation** | ownerUI and customerUI remain independent |
| **Inventory Sync** | maxRepeats dynamically calculated from stock |

---

## 11. Future Enhancements

- **Complex Bundles**: Accept/give multiple item types in single trade
- **Conditional Pricing**: Different prices based on customer reputation
- **Trade History**: Track completed transactions with timestamps
- **Price Trending**: Show most popular trades
- **NPC Integration**: Support for shop-owned NPCs
- **Trading Limits**: Set daily/weekly trade limits per listing
