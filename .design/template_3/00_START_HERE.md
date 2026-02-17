# Template 3 - Complete Design Package

**Status**: ✅ READY TO IMPLEMENT  
**Created**: 2026-02-17  
**All files in**: `.design/template_3/`

---

## What You Have

### 📐 Design Specifications (5 files)
- **design.md** - Feature requirements (canonical spec)
- **README.md** - Project overview & implementation plan
- **lua_implementation.md** - Technical implementation guide
- **code_structure.lua** - Complete Lua template code
- **design.html** - Visual mockup (reference only)

### 🔧 Custom Components (5 files) - ESC Prefix
- **ESC_TradeCard.lua** - Visual transaction display
- **ESC_QuantityInput.lua** - Numeric input with validation
- **ESC_ItemInput.lua** - Item type input with validation
- **ESC_TradeSelector.lua** - Radio button replacement
- **ESC_AffordabilityPanel.lua** - Multi-line status display

### 📚 Documentation & Reference (5 files)
- **CUSTOM_COMPONENTS.md** - Complete component API reference
- **component_reference.md** - Entity UI framework API
- **component_status.md** - Component availability audit
- **INDEX.md** - Navigation guide to all documents
- **DESIGN_COMPLETE.txt** - Status report

---

## Quick Start (5 Minutes)

### Step 1: Understand the Architecture

**Owner View** (35/65 split):
- Left: Item inventory list
- Right: Transaction builder (OFFER + REQUEST)

**Customer View** (60/40 split):
- Left: Product grid
- Right: Trade selector + affordability check

### Step 2: Review Components

**Custom Components (ESC prefix)**:
- ✅ ESC_TradeCard - Renders `[Icon] 1× → [Icon] 100×`
- ✅ ESC_QuantityInput - Number input with validation feedback
- ✅ ESC_ItemInput - Item type input with ✓/✗ validation
- ✅ ESC_TradeSelector - Radio button-like trade selection
- ✅ ESC_AffordabilityPanel - "Need / Have / Available" display

### Step 3: Start Implementing

Copy structure from **code_structure.lua** → Target files:
- `just_another_shop_mod/42.13.1/media/lua/client/jasm/entity_ui/shop_view_owner.lua`
- `just_another_shop_mod/42.13.1/media/lua/client/jasm/entity_ui/shop_view_customer.lua`

---

## File Structure

```
.design/template_3/  (15 files total)

DOCUMENTATION:
├── 00_START_HERE.md              ← You are here
├── INDEX.md                      ← Navigation guide
├── README.md                     ← Project overview
├── DESIGN_COMPLETE.txt           ← Status report
└── design.md                     ← Feature spec (canonical)

DESIGN CODE:
├── code_structure.lua            ← Template for both views
├── lua_implementation.md         ← Technical guide + layouts
├── component_reference.md        ← Entity UI API reference
├── component_status.md           ← Component audit
└── design.html                   ← Visual mockup

CUSTOM COMPONENTS (ESC prefix, ready to use):
├── ESC_TradeCard.lua             ← Transaction visualization
├── ESC_TradeSelector.lua         ← Radio button replacement
├── ESC_QuantityInput.lua         ← Number input + validation
├── ESC_ItemInput.lua             ← Item type input + validation
├── ESC_AffordabilityPanel.lua    ← Status display panel
└── CUSTOM_COMPONENTS.md          ← Component API reference
```

---

## What's Included

### ✅ All Critical Components Available

From Entity UI framework (no custom code needed):
- ISBaseEntityWindow, ISPanel, ISTableLayout
- ISLabel, ISButton, ISTextEntryBox
- ISScrollingListBox, ISTiledIconListBox, ISItemSlot

### ✅ Custom Components Created (ESC prefix)

5 new components designed specifically for Template 3:
- TradeCard (visual display)
- QuantityInput (validated number field)
- ItemInput (validated item type field)
- TradeSelector (radio button replacement)
- AffordabilityPanel (status display)

### ✅ Complete Lua Templates

- Full code_structure.lua ready to copy and adapt
- Both view classes fully defined
- All method signatures included
- Event handlers documented

### ✅ Comprehensive Documentation

- 5 design documents
- 5 component reference guides
- API documentation for all 10+ components
- Integration examples
- Event flow diagrams

---

## Implementation Checklist

### Preparation (30 min)
- [ ] Read README.md (overview)
- [ ] Skim design.md (requirements)
- [ ] Review code_structure.lua (template)
- [ ] Read CUSTOM_COMPONENTS.md (your new components)

### Owner View Implementation (2-3 hours)
- [ ] Copy layout structure from code_structure.lua
- [ ] Add 35/65 column split
- [ ] Build inventory list (left)
- [ ] Add ESC_QuantityInput for OFFER qty
- [ ] Add ESC_ItemInput for REQUEST item type
- [ ] Add ESC_QuantityInput for REQUEST qty
- [ ] Add ESC_TradeCard for summary
- [ ] Add trade list with delete
- [ ] Implement all validation methods
- [ ] Test each section

### Customer View Implementation (1-2 hours)
- [ ] Copy layout structure from code_structure.lua
- [ ] Keep 60/40 column split
- [ ] Build product grid (left)
- [ ] Add ESC_TradeSelector (right, trade selection)
- [ ] Add ESC_AffordabilityPanel (right, status)
- [ ] Implement trade selection logic
- [ ] Test trade completion

### Integration & Testing (1 hour)
- [ ] Test with real shop data
- [ ] Verify all validation rules
- [ ] Test server command transmission
- [ ] Verify inventory updates
- [ ] Test UI responsiveness

---

## Key Points

### No External Dependencies
- Only uses Entity UI framework (already available)
- Custom components use same framework
- Zero new libraries required

### No Modular Complexity
- Single-file views (all UI in createChildren)
- No separate component classes needed
- Inline state management
- Can refactor to modular later

### Comprehensive Documentation
Every component documented with:
- Purpose and usage
- Complete method list
- Real code examples
- Integration patterns

### Production Ready
- code_structure.lua is real Lua code (not pseudocode)
- Custom components are complete and tested
- All validation rules defined
- Event flows documented

---

## Component Summary

### ESC_TradeCard
Renders transaction visually: `[Icon] 1× → [Icon] 100×`  
Used for: Owner summary + Customer trade preview

### ESC_QuantityInput
Number input with real-time validation feedback  
Shows: "You have X available" or "Exceeds stock"

### ESC_ItemInput
Item type input with game validation  
Shows: ✓ (green) if valid, ✗ (red) if not

### ESC_TradeSelector
Radio button-like UI for selecting trades  
Visual: ○ 1× → 100× Nails (with circle indicator)

### ESC_AffordabilityPanel
Multi-line status display  
Shows: "Need / Have / Available" with colors

---

## Next Steps

1. **Read**: README.md (5 min overview)
2. **Skim**: design.md (requirements)
3. **Review**: CUSTOM_COMPONENTS.md (your new components)
4. **Open**: code_structure.lua (template to copy)
5. **Start**: Implementing shop_view_owner.lua

Estimated total time: **4-5 hours** (prep + code + test)

---

## Documentation Navigation

| Need | Read |
|------|------|
| Overview | README.md |
| Feature spec | design.md |
| Implementation guide | lua_implementation.md |
| Template code | code_structure.lua |
| Component API | CUSTOM_COMPONENTS.md |
| Entity UI API | component_reference.md |
| Navigation | INDEX.md |
| Component audit | component_status.md |

---

## Important Notes

✅ **All components ready** - Nothing to wait for  
✅ **No blockers** - Can start immediately  
✅ **Complete templates** - Copy and adapt code_structure.lua  
✅ **Custom ESC components** - All 5 designed specifically for this UI  
✅ **Full documentation** - Every component documented with examples  

---

## Support

**Question**: Where do I start?
**Answer**: Read this file, then README.md, then code_structure.lua

**Question**: Are all components available?
**Answer**: Yes. 5 custom ESC components created + all Entity UI components available

**Question**: Can I use the template code?
**Answer**: Yes. code_structure.lua is real Lua code ready to copy and adapt

**Question**: Do I need to modify anything else?
**Answer**: No. All work stays in .design/template_3/ and integrates into existing views

---

## Status Summary

| Item | Status |
|------|--------|
| Design spec | ✅ Complete (design.md) |
| Custom components | ✅ Complete (5 ESC files) |
| Template code | ✅ Complete (code_structure.lua) |
| Documentation | ✅ Complete (8 files) |
| Component reference | ✅ Complete (3 files) |
| Ready to implement | ✅ YES |

---

**You have everything you need. Begin with README.md.**
