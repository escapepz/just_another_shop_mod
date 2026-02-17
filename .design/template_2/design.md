# Template 2: Barter/Listing System Design (Enhanced)

**Reference**: Based on Template 1 with significant improvements
- `.design/template_1/design.md` — Foundation concepts
- `.design/template_2/design.html` — Visual visualization

**Key Evolution**: Moving from simple static pricing to a **Dynamic Barter/Listing System** with multi-listing support, responsive grids, and item-based exchanges.

---

## 1. Architecture Overview

This template introduces a **3-tier transaction system**:
1. **Seller Mode** (Owner): Define what you're offering + what you want in exchange
2. **Inventory Display** (Customer/Owner): Real-time inventory view
3. **Transaction History** (Future): Track completed exchanges

---

## 2. Owner View: "Market Listing & Management"

The owner can manage multiple barter pairs for the same item. The UI supports drafting, adding, and managing active listings.

### **Main Container Structure**
- **Primary Layout**: `ISTableLayout` with 2 columns
  - **Left Column (50% - Fill)**: Inventory list (`ISScrollingListBox`)
  - **Right Column (50% - Fill)**: Listing management form

### **The Listing Form (Right Column)**

**Vertical Stack Structure:**

#### **Section A: Draft Input Area**
- **Row 1 (Static, ~30px)**: Header label "Draft New Listing"
- **Row 2 (Static, ~40px)**: Item Type field
  - `ISTextEntryBox`: Owner types "Base.Nails"
  - **Live Validation**: Show item icon immediately if valid
  - **Error State**: Red border + tooltip if item doesn't exist
- **Row 3 (Static, ~40px)**: Amount field
  - `ISTextEntryBox`: Numeric input "100"
  - **Constraints**: Min=1, Max=inventory capacity
- **Row 4 (Static, ~35px)**: Add Button + Status indicator
  - `ISButton`: "ADD TO LISTINGS" (primary action)
  - `ISLabel`: Shows validation feedback

#### **Section B: Active Listings (Dynamic)**
- **Row 5 (Static, ~25px)**: Header "Active Listings for Selected Item"
- **Row 6 (Fill, scrollable)**: `ISScrollingListBox` showing current barters
  - **Listing Item Format**: `[Item Icon] Item Name × Count [Delete]`
  - **Interaction**: Click to select, Delete button removes listing
  - **Empty State**: "No listings yet. Add one above."
- **Row 7 (Spring/Spacer)**: Empty fill to push footer down

#### **Section C: Footer Actions**
- **Row 8 (Static, ~35px)**: Action buttons
  - `ISButton`: "SAVE ALL" (commits changes to modData)
  - `ISButton`: "CANCEL" (reverts unsaved changes)

### **Data Structure for Multiple Listings**

```lua
-- Old (Template 1):
modData.shopPrices = {
  ["Base.Water"] = { exchangeFor = "Base.Nails", count = 50 }
}

-- New (Template 2):
modData.shopListings = {
  ["Base.Water"] = {
    {exchangeFor = "Base.Nails", count = 50, id = "listing_001"},
    {exchangeFor = "Base.Hammer", count = 1, id = "listing_002"}
  }
}
```

---

## 3. Customer View: "Dynamic Barter Discovery"

Enhanced from Template 1 with responsive grid behavior and rich item details.

### **Main Container Structure**
- **Primary Layout**: `ISTableLayout` with 2 columns
  - **Left Column (60% - Fill)**: Product grid (`ISTiledIconListBox`)
  - **Right Column (40% - Fill)**: Item details panel

### **The Responsive Grid (Left Column)**

**Key Improvement**: Dynamic column count based on available width

- **Grid Configuration**:
  - `tileWidth = 80` (pixel width of each tile including padding)
  - `forceSize = true` (prevents stretching, enables wrapping)
  - `columnCount = floor(availableWidth / tileWidth)` (calculated at runtime)

- **Behavior**:
  - Window width 500px → 2 columns
  - Window width 800px → 3-4 columns
  - Window width 1200px → 5+ columns

- **Tile Structure**: 
  - `ISImage`: Item icon (64×64)
  - `ISLabel`: Item name + quantity in inventory
  - `forceSize = true` ensures consistent sizing

### **The Item Details Panel (Right Column)**

**Vertical Stack with Anchored Barter Display**

#### **Row 1 (Static, ~50px)**: Item Header
- `ISImage`: Large item icon (48×48)
- `ISLabel`: Item name (bold, larger font)
- `ISLabel`: Quantity in inventory (gray, smaller)

#### **Row 2 (Static, ~30px)**: Description
- `ISLabel`: Item description text (from game item definitions)
- **Font**: Small, gray, word-wrapped

#### **Row 3 (Fill/Spring)**: Empty spacer
- Pushes barter info and button to bottom

#### **Row 4 (Static, ~60px)**: Barter Options Stack
- **Sub-Layout**: Horizontal flow of barter entries (if multiple listings exist)
- **Layout Pattern**: `ISHorizontalStack` or vertical list
- **Each Barter Entry**:
  - `ISImage`: Exchange item icon (24×24)
  - `ISLabel`: Exchange item name
  - `ISLabel`: "×" + count (e.g., "×100")
  - **Tooltip**: Shows full exchange details on hover

#### **Row 5 (Static, ~35px)**: Action Button
- `ISButton`: "ACCEPT TRADE" (green, prominent)
- **Disabled State**: Gray out if player inventory doesn't have required items
- **Click Handler**: Opens confirmation dialog

### **Barter Details Row Component (Reusable)**

```lua
-- Visual representation:
┌────────────────────────────────────────────┐
│ Barter Option 1:                           │
│ [Icon] Nails × 100                         │
│                                            │
│ Barter Option 2:                           │
│ [Icon] Hammer × 1                          │
│                                            │
│ [ACCEPT TRADE Button]                      │
└────────────────────────────────────────────┘
```

---

## 4. Visual Hierarchy & Color Coding

### **Owner View Color Scheme**
| Element | Color | Purpose |
|---------|-------|---------|
| Draft Section | #2c3e50 (Dark Blue) | Input area |
| Active Listings | #34495e (Medium Blue) | Display area |
| Valid Item Indicator | #27ae60 (Green) | Validation success |
| Invalid Item | #e74c3c (Red) | Validation error |
| Buttons | #3498db (Blue primary), #95a5a6 (Gray secondary) | Actions |

### **Customer View Color Scheme**
| Element | Color | Purpose |
|---------|-------|---------|
| Grid Background | #1a1a1a (Very Dark) | Neutral container |
| Selected Tile | #f39c12 (Orange) | Active selection |
| Details Panel | #2c3e50 (Dark Blue) | Context panel |
| Barter Text | #f1c40f (Gold) | Highlighted exchange |
| Accept Button | #27ae60 (Green) | Primary action |

---

## 5. Implementation Requirements

### **Required Lua Components**
1. **BarterManager** — Handles listing creation, validation, deletion
2. **InventoryRenderer** — Real-time inventory display
3. **BarteredItemPanel** — Details panel with dynamic barter rows
4. **ListingValidator** — Validates item types, enforces constraints
5. **DataPersistence** — Saves/loads modData structure

### **Key Improvements Over Template 1**

| Feature | Template 1 | Template 2 | Benefit |
|---------|-----------|-----------|---------|
| Pricing Model | Single price per item | Multiple barter pairs | Flexibility for complex trades |
| Grid Responsiveness | Fixed 2-3 columns | Dynamic calculation | Scales with window size |
| Item Validation | None mentioned | Real-time icon lookup | Immediate visual feedback |
| Listing Management | Static pricing | Add/Delete/Edit listings | Runtime inventory management |
| UI Complexity | Basic 2-column split | 3-section form with sub-layouts | Professional, organized UX |
| Error Handling | Not specified | Validation with feedback | User-friendly error messages |

### **Design Principles (Enhanced from Template 1)**

| Principle | Rule | Implementation |
|-----------|------|-----------------|
| **Sizing** | Never use `self.width / 2`. Use `addColumnFill()` or `addColumn(0.5)` | Calculated at render time |
| **Nesting** | Parent calls `calculateLayout()` on child panels, never internal self-triggering | Prevents cascade updates |
| **Anchoring** | Spring rows (Fill without height) push buttons to bottom | Use `addRow(0)` with no min height |
| **Responsiveness** | Grid `tileWidth` drives column count, not hardcoded values | Dynamic `floor(width / tileWidth)` |
| **Validation** | Show feedback immediately on input, don't wait for button click | Real-time item lookup |
| **Scrolling** | Lists that grow beyond fixed height use `ISScrollingListBox` | Prevents UI overflow |

---

## 6. State Management

### **Owner Session State**
```lua
ownerUI = {
  selectedItemInInventory = nil,  -- Which item owner clicked
  draftListing = {                -- Currently being edited
    exchangeFor = "Base.Nails",
    count = 100
  },
  activeListings = {},            -- {id, exchangeFor, count}
  validationError = nil           -- Feedback message
}
```

### **Customer Session State**
```lua
customerUI = {
  selectedItemInShop = nil,       -- Which item customer clicked
  availableBarterOptions = {},    -- List of possible exchanges
  playerCanAfford = true          -- Inventory check result
}
```

---

## 7. Event Flow Diagrams

### **Owner: Add Listing Flow**
1. Owner types "Base.Nails" → `ItemValidator.isValidItem()` → Show icon if valid
2. Owner enters "100" → `ListingValidator.checkCapacity()` → Show constraints
3. Owner clicks ADD → `BarterManager.addListing()` → List updates
4. Owner clicks SAVE ALL → Persist to `modData.shopListings`

### **Customer: Browse & Trade Flow**
1. Customer clicks item in grid → `loadItemDetails()` → Show all barter options
2. Each barter option displays with exchange icon + amount
3. Customer clicks ACCEPT → `TransactionValidator.canAfford()` → Proceed or show error
4. Trade completes → Remove items from both inventories, refresh UI

---

## 8. Responsive Behavior (Window Resizing)

**When customer maximizes window:**
- 60% Fill column expands
- Grid recalculates: `newColumnCount = floor(expandedWidth / tileWidth)`
- Tiles reflow into additional columns
- Details panel stays fixed width (40%)

**When owner adjusts window:**
- 50/50 split remains proportional
- Inventory list scrolls independently
- Form fields stay aligned (2-column inner layout)

---

## 9. Migration Path from Template 1

If you have existing Template 1 code:

1. Keep `ISTableLayout` 2-column structure
2. Replace single-listing system with multi-listing array
3. Add sub-layout panels for "Draft" and "Active Listings" sections
4. Enhance grid with `tileWidth` and dynamic column calculation
5. Add item validation with icon lookup
6. Implement new data structure: `modData.shopListings` instead of `modData.shopPrices`

---

## 10. Future Enhancements (Beyond Template 2)

- **Trade History**: Log completed exchanges with timestamps
- **Filters**: Search/sort listings by item type or exchange ratio
- **Favorites**: Customer can mark favorite shops
- **Price Trending**: Display most common exchange rates
- **NPC Integration**: Allow NPCs to have their own shops with AI pricing
