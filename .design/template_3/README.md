# Template 3: Unit-Based Barter System - Complete Design & Implementation Plan

## Overview

Template 3 implements a **bidirectional transaction system** where both OFFER (what shop gives) and REQUEST (what shop gets) are independently configurable. This is a significant evolution from Template 2's single-direction pricing model.

**Location**: `.design/template_3/`

---

## Design Documents

### 1. **design.md** (Canonical)
The original visual/conceptual design specification. Covers:
- Core philosophy of unit-based trading
- Owner view layout (35/65 split)
- Customer view layout (60/40 split)  
- Data structures and validation rules
- State management and event flows
- Comparison with Template 2

**When to use**: For understanding the feature requirements and design philosophy

### 2. **lua_implementation.md**
Detailed Lua implementation guide with:
- Component availability status (✅ available vs ❌ missing)
- Component workarounds for missing UI elements
- Detailed layout hierarchies for both views
- Method signatures and responsibilities
- Data structure examples
- Color scheme definitions
- Implementation checklist

**When to use**: For building the actual Lua code

### 3. **component_status.md**
Comprehensive component audit showing:
- All critical components are available ✅
- Optional components with workarounds ❌
- Build instructions for each component level
- Implementation roadmap (Phase 1-4)
- Legacy code reference tips

**When to use**: For troubleshooting component availability and understanding workarounds

### 4. **code_structure.lua**
Complete Lua template code showing:
- Full createChildren() implementations for both views
- Event handler method signatures
- Helper method implementations
- Layout calculation patterns
- Real code structure (not pseudocode)

**When to use**: As the starting point for actual implementation

---

## File Structure

```
.design/template_3/
├── README.md                    ← You are here
├── design.md                    ← Visual/feature design (canonical)
├── lua_implementation.md        ← Implementation guide with component details
├── component_status.md          ← Component audit & workarounds
├── code_structure.lua           ← Template code ready to implement
└── design.html                  ← Original HTML mockup (reference only)
```

---

## Implementation Plan

### Target Files
- **`just_another_shop_mod/42.13.1/media/lua/client/jasm/entity_ui/shop_view_owner.lua`**
  - Current: 50/50 split, simple price entry
  - Target: 35/65 split, full transaction builder
  
- **`just_another_shop_mod/42.13.1/media/lua/client/jasm/entity_ui/shop_view_customer.lua`**
  - Current: 60/40 split, product grid + basic details
  - Target: 60/40 split, product grid + trade selector + affordability check

### No Modular Components
As requested, both views are **single-file implementations**:
- All UI elements defined in `createChildren()` of each view
- No separate component classes (for now)
- State management inline with view logic
- Layout defined using ISTableLayout (no custom layout manager)

---

## Component Availability Summary

### ✅ All Critical Components Available
- ISBaseEntityWindow (window container)
- ISPanel (generic container)
- ISTableLayout (grid layout - 35/65 & 60/40 splits)
- ISLabel (text display)
- ISButton (clickable buttons)
- ISTextEntryBox (text inputs with :setOnlyNumbers())
- ISScrollingListBox (scrollable lists)
- ISTiledIconListBox (grid tiles)
- ISItemSlot (drag-drop items)

### ❌ Missing Components (With Workarounds)
| Missing | Workaround | Difficulty |
|---------|-----------|-----------|
| ISRadioButton | Use ISScrollingListBox with highlighted selection | Low |
| ISSpinner | Use ISTextEntryBox + numeric validation | Low |
| Tooltips | Use colored ISLabel feedback text | Low |
| Trade Card Renderer | Custom draw() method with textures + text | Medium |

**Bottom Line**: You have everything needed. Missing components are nice-to-have polish, not blockers.

---

## Layout Architecture

### Owner View (35/65 Split)
```
┌─────────────────────────────────────┐
│ HEADER: "Build Trade for Selected Item"
├──────────────┬──────────────────────┤
│              │ Selected: Water - 12 │
│ Inventory    ├──────────────────────┤
│   • Water    │ OFFER: 1×            │
│   • Nails    │ REQUEST: 100× Nails  │
│   • Hammer   ├──────────────────────┤
│              │ Summary: 1× → 100×   │
│              │ Add Trade Button     │
│              ├──────────────────────┤
│              │ Active Trades:       │
│              │ • 1× → 100×          │
│              │ • 2× → 1×            │
│              ├──────────────────────┤
│              │ [SAVE] [CANCEL]      │
└──────────────┴──────────────────────┘
```

### Customer View (60/40 Split)
```
┌──────────────────────────┬──────────┐
│                          │ Water    │
│ Product Grid             │ Stock: ¶ │
│  🧊 🍖 ⚕️              ├──────────┤
│  🔨 🪵 🧱              │ Trades:  │
│                          │ • 1× →¶ │
│                          │ • 2× →¶ │
│                          ├──────────┤
│                          │ Need: ¶  │
│                          │ Have: ✓  │
│                          ├──────────┤
│                          │[ACCEPT]  │
└──────────────────────────┴──────────┘
```

---

## Data Structures

### Owner's Transaction
```lua
modData.shopTrades = {
  ["Base.Water"] = {
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
}
```

### Customer's Transaction Check
```lua
trade = availableTrades[selectedTradeIndex]
playerNeeds = trade.request  -- {itemType, quantity}
playerHas = playerInv:getItemCount(playerNeeds.itemType)
maxCompletions = floor(shopStock / trade.offer.quantity)
canAfford = playerHas >= playerNeeds.quantity
```

---

## Validation Rules

### Owner Creating Trade
| Check | Condition | Action |
|-------|-----------|--------|
| Stock Limit | Offer qty > inventory | Disable button, show error |
| Item Valid | Request item doesn't exist | Red border, show error |
| Positive Qty | Both quantities > 0 | Required for any action |
| No Duplicate | Same offer/request pair exists | Warn user, prevent add |

### Customer Completing Trade
| Check | Condition | Action |
|-------|-----------|--------|
| Can Afford | Player has request items | Enable button, show ✓ |
| Cannot Afford | Player missing items | Disable button, show red |
| Stock Available | Shop has offer items | Show "X trades max" |

---

## Quick Start Guide

### Step 1: Read Design Documents
1. **design.md** - Understand features and philosophy
2. **lua_implementation.md** - Understand implementation details
3. **component_status.md** - Verify all components available

### Step 2: Reference Implementation
- Open **code_structure.lua** alongside target Lua files
- It's a complete template, not pseudocode
- Copy structure, adapt to existing code patterns

### Step 3: Implement shop_view_owner.lua
- Change layout to 35/65 split
- Add OFFER section with quantity input
- Add REQUEST section with quantity + item type inputs
- Add real-time validation (green/red feedback)
- Add summary card visualization
- Add ADD TRADE button with validation
- Add Active Trades list with delete buttons
- Implement all event handlers

### Step 4: Implement shop_view_customer.lua
- Keep 60/40 grid layout
- Add trade selector (ISScrollingListBox approach)
- Add affordability check display
- Implement trade selection logic
- Add maxCompletions calculation

### Step 5: Test
- Verify all validation rules work
- Test trade creation flow
- Test trade completion flow
- Verify inventory syncing

---

## Key Differences from Current Implementation

### Owner View Changes
**Current**: Simple 50/50 split with item list + single price form
**New**: 
- 35/65 split (narrower form, wider inventory)
- Bidirectional (both OFFER and REQUEST inputs)
- Multi-trade support (create multiple trades per item)
- Real-time validation with visual feedback
- Trade list with delete capability

### Customer View Changes
**Current**: 60/40 split with product grid + basic details
**New**:
- Trade selector (radio button equivalent)
- Affordability check display
- maxCompletions calculation
- Enhanced error messaging

---

## Migration Path

If migrating from Template 2:
1. Convert data from `{exchangeFor, count}` → `{offer, request}`
2. Change owner layout from 50/50 → 35/65
3. Add OFFER input section
4. Add trade list UI
5. Update customer view with trade selector
6. Implement maxCompletions logic

No breaking changes to shop_view.lua (router file).

---

## Notes & Considerations

### Performance
- ISScrollingListBox handles large lists efficiently
- ISTiledIconListBox tiles itself dynamically
- ISTableLayout calculates on demand (not every frame)

### Accessibility
- All inputs keyboard-accessible
- Tab order: left column items → offer qty → request qty → request item → buttons
- Error messages clear and actionable

### Future Enhancements
- ISRadioButton component when available
- ISSpinner component for quantity (±1, ±10)
- Combo trades (multiple items per offer/request)
- Trade history/logging
- Reputation-based pricing

---

## Testing Checklist

- [ ] Layout displays correctly at multiple window sizes
- [ ] Owner can select items from inventory
- [ ] Offer quantity validates against inventory
- [ ] Request item validates against game items
- [ ] Summary card updates in real-time
- [ ] ADD TRADE button validation works
- [ ] Trades persist to modData after SAVE
- [ ] Customer can view product grid
- [ ] Customer can select multiple trades for same product
- [ ] Affordability calculates correctly
- [ ] maxCompletions shows accurate count
- [ ] Trade completion updates inventory
- [ ] Error messages are clear

---

## Support References

**Legacy Code**: `.tmp/codebase/projectzomboid_lua_codebase.xml`  
Use for:
- ISTableLayout patterns
- ISScrollingListBox callbacks
- Color definitions
- Drawing API calls

**Current Implementation**: `42.13.1/media/lua/client/jasm/entity_ui/`  
Already working:
- Module structure (require, new, initialise, createChildren)
- ISPanel inheritance pattern
- ISLabel/ISButton usage
- Container access patterns

---

## Summary

All necessary components are available. This design requires:
- **No external libraries**
- **No new component classes**
- **No breaking changes** to existing code structure
- **Single-file implementations** for owner and customer views

The design is ready to implement. Start with `code_structure.lua` as your template.
