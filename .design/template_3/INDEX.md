# Template 3 Design Documentation Index

Complete design and implementation guide for the Unit-Based Barter System UI.

## 📋 Quick Navigation

| Document | Purpose | Read Time | When |
|----------|---------|-----------|------|
| **README.md** | Overview & roadmap | 5 min | Start here |
| **design.md** | Feature spec (canonical) | 10 min | Understand requirements |
| **lua_implementation.md** | Implementation details | 15 min | Before coding |
| **code_structure.lua** | Working template code | 10 min | Start implementing |
| **component_reference.md** | API lookup | 10 min | While coding |
| **component_status.md** | Component audit | 8 min | Verify availability |

---

## 📚 Document Summaries

### 1. **README.md** - Project Overview
- Complete feature overview
- Implementation plan and timeline
- All components available (✅)
- Migration path from Template 2
- Testing checklist

**Read this first** to understand what you're building.

---

### 2. **design.md** - Feature Specification (Canonical)
The original visual design document that defines what Template 3 should be.

**Sections**:
- Core philosophy: Unit-based trading
- Owner view: 35/65 column split with transaction builder
- Customer view: 60/40 split with trade selector
- Data structures (shopTrades format)
- Validation rules
- Event flow diagrams
- Comparison with Template 2

**Reference**: Use this when users ask "why is it this way?"

---

### 3. **lua_implementation.md** - Implementation Guide
Detailed technical guide for building the Lua UI.

**Sections**:
- Component availability (✅ vs ❌)
- Component workarounds (radio buttons, spinners, tooltips)
- Layout hierarchies with ASCII diagrams
- Method signatures for both views
- Data structure examples (with code)
- Validation rule tables
- Implementation checklist
- Testing checklist

**Read this** before opening code_structure.lua

---

### 4. **code_structure.lua** - Complete Template Code
Fully working Lua code ready to implement. Not pseudocode—real, executable code structure.

**Contents**:
- Full `JASM_ShopView_Owner` class (shop_view_owner.lua)
- Full `JASM_ShopView_Customer` class (shop_view_customer.lua)
- All methods with proper signatures
- ISTableLayout patterns
- Helper methods (validation, state management)
- Event handlers (onItemSelected, onTradeSelected, etc.)

**Use as**:
- Direct template for both files
- Reference for method structure
- Pattern examples for layout construction
- Copy-paste starting point

---

### 5. **component_reference.md** - API Reference
Quick lookup for all UI components with usage examples.

**Sections**:
- Core containers (ISBaseEntityWindow, ISPanel)
- Layout (ISTableLayout with split patterns)
- Text (ISLabel)
- Input (ISTextEntryBox)
- Buttons (ISButton)
- Lists (ISScrollingListBox)
- Grids (ISTiledIconListBox)
- Item selection (ISItemSlot)
- Game API (getScriptManager, container, inventory)
- Drawing utilities
- Color constants
- Pattern examples

**Use while**: Writing actual code

---

### 6. **component_status.md** - Component Audit
Comprehensive inventory of what's available and what needs workarounds.

**Sections**:
- Critical components (all available ✅)
- Optional components (with workarounds ❌)
- Current implementation status
- Build instructions (Level 1-5)
- Implementation roadmap (Phase 1-4)
- Workaround details
- Testing checklist

**Use for**:
- Verifying component availability
- Understanding workarounds
- Planning implementation phases

---

### 7. **design.html** - Visual Mockup
Original HTML mockup showing the visual design. For reference only (not used in implementation).

---

## 🎯 Implementation Workflow

### Phase 1: Preparation (30 min)
1. **Read**: README.md (project overview)
2. **Read**: design.md (feature spec)
3. **Read**: lua_implementation.md (technical details)
4. **Verify**: All components available in component_status.md

### Phase 2: Owner View Implementation (2-3 hours)
1. **Reference**: code_structure.lua - JASM_ShopView_Owner section
2. **Copy**: Structure from code_structure.lua
3. **Use**: component_reference.md for API details
4. **Build**: Step by step following lua_implementation.md layout hierarchy
5. **Test**: Each section before moving to next

**Sections to build**:
- [ ] 35/65 layout split
- [ ] Item inventory list (left column)
- [ ] OFFER section (right column)
- [ ] REQUEST section (right column)
- [ ] Summary card (right column)
- [ ] ADD TRADE button + validation (right column)
- [ ] Active trades list (right column)
- [ ] SAVE / CANCEL buttons (right column)

### Phase 3: Customer View Implementation (2 hours)
1. **Reference**: code_structure.lua - JASM_ShopView_Customer section
2. **Build**: Following same pattern as owner view
3. **Test**: Trade selection and affordability logic

**Sections to build**:
- [ ] 60/40 layout split
- [ ] Product grid (left column)
- [ ] Trade selector (right column, NEW)
- [ ] Affordability display (right column, NEW)
- [ ] ACCEPT button + validation (right column)

### Phase 4: Integration & Testing (1 hour)
1. Test both views with actual shop data
2. Verify all validation rules work
3. Test server command transmission
4. Verify inventory updates

---

## 📊 Component Availability Summary

### ✅ All Critical Components Available
```
✅ ISBaseEntityWindow   - window container
✅ ISPanel              - generic container
✅ ISTableLayout        - grid layout (35/65 & 60/40)
✅ ISLabel              - text display
✅ ISButton             - clickable buttons
✅ ISTextEntryBox       - text inputs
✅ ISScrollingListBox   - scrollable lists
✅ ISTiledIconListBox   - icon grids
✅ ISItemSlot           - drag-drop items
```

**Result**: No blockers. Build can proceed immediately.

### ❌ Nice-to-Have Components (Workarounds Available)
```
❌ ISRadioButton        → Use ISScrollingListBox with highlight
❌ ISSpinner            → Use ISTextEntryBox + numeric validation
❌ Tooltips             → Use colored ISLabel feedback
❌ Custom Trade Renderer → Custom draw() method in ISPanel
```

**Result**: All workarounds simple and effective.

---

## 🔍 Key Architecture Decisions

### Single-File Design
- No separate component classes
- All UI in createChildren() of each view
- No module extraction (for now)
- Inline state management

**Benefit**: Simpler, faster implementation. Can refactor to modular later.

### Layout Strategy
- **Owner**: 35/65 split (narrower inventory, wider form)
- **Customer**: 60/40 split (wider grid, narrower details)
- **Both**: ISTableLayout (grid-based, responsive)

**Benefit**: Responsive, handles window resizing automatically.

### Validation Approach
- **Real-time**: Update as user types
- **Visual**: Green/red feedback text
- **Disabled state**: Disable button when invalid
- **Clear errors**: Show specific reason why invalid

**Benefit**: User always knows what's wrong and how to fix it.

### Data Structure
```lua
modData.shopTrades = {
  ["Base.Water"] = {
    {offer = {itemType, quantity}, request = {itemType, quantity}},
    -- more trades...
  }
}
```

**Benefit**: Supports multiple pricing options per item.

---

## 📝 File Locations

```
.design/template_3/
├── INDEX.md                     ← You are here
├── README.md                    ← Start here
├── design.md                    ← Feature spec (canonical)
├── lua_implementation.md        ← Technical implementation guide
├── code_structure.lua           ← Complete template code
├── component_reference.md       ← API reference
├── component_status.md          ← Component audit
└── design.html                  ← Visual mockup (reference only)

Implementation targets:
just_another_shop_mod/42.13.1/media/lua/client/jasm/entity_ui/
├── shop_view.lua                ← Router (no changes needed)
├── shop_view_owner.lua          ← Implement from code_structure.lua
└── shop_view_customer.lua       ← Implement from code_structure.lua

Reference:
.tmp/codebase/projectzomboid_lua_codebase.xml
└── Legacy PZ UI patterns and examples
```

---

## ✅ Verification Checklist

Before you start coding:

- [ ] Read README.md (5 min)
- [ ] Understand design.md requirements (10 min)
- [ ] Review lua_implementation.md layout diagrams (10 min)
- [ ] Verify all components available in component_status.md
- [ ] Have code_structure.lua open as reference
- [ ] Have component_reference.md bookmarked for API lookups
- [ ] Have existing shop_view_owner.lua and shop_view_customer.lua open
- [ ] Have design.md open for reference

---

## ⚡ Quick Start

1. **Right now**: Read this INDEX.md (you're doing it!)
2. **Next 5 min**: Read README.md for overview
3. **Next 10 min**: Scan design.md for feature understanding
4. **Next 10 min**: Read layout hierarchies in lua_implementation.md
5. **Start coding**: Open code_structure.lua alongside your editor

---

## 📌 Key Points

✅ **All critical components available** - No external dependencies needed  
✅ **Single-file views** - No modular components (for now)  
✅ **Complete template code** - code_structure.lua is production-ready  
✅ **Clear architecture** - 35/65 and 60/40 splits well-defined  
✅ **Comprehensive docs** - 7 documents covering every aspect  
✅ **Ready to implement** - Zero blockers, all patterns documented  

---

## 🎓 Learning Path

**If you're new to this codebase**:
1. Read README.md (overview)
2. Read design.md (requirements)
3. Read component_reference.md (learn API)
4. Look at code_structure.lua (see patterns)
5. Implement following lua_implementation.md

**If you're implementing now**:
1. Open code_structure.lua
2. Bookmark component_reference.md
3. Keep design.md nearby for validation rules
4. Reference lua_implementation.md for layout details
5. Copy patterns from code_structure.lua

**If you're debugging later**:
1. Check validation rules in design.md
2. Check method signatures in code_structure.lua
3. Check API details in component_reference.md
4. Check component availability in component_status.md

---

## 💡 Tips

- **Copy, don't rewrite**: code_structure.lua is complete and ready to use
- **Validate early**: Add validation methods before building UI
- **Test incremental**: Build one section, test it, move to next
- **Reference often**: Keep component_reference.md open while coding
- **Check existing**: Look at current shop_view_owner.lua for patterns
- **Mock data**: Use hardcoded test trades while developing

---

## ❓ FAQ

**Q: Do I need to understand all 7 documents?**  
A: No. Start with README.md, then jump to code_structure.lua. Reference others as needed.

**Q: Can I copy code_structure.lua directly?**  
A: Yes! It's meant to be a template. Copy the structure and adapt to existing code patterns.

**Q: Are all components really available?**  
A: Yes! See component_status.md for complete audit. Zero blockers.

**Q: What if I need to make changes later?**  
A: Design is modular-ready. Can refactor to components later without breaking changes.

**Q: Where do I find existing code to reference?**  
A: `42.13.1/media/lua/client/jasm/entity_ui/shop_view_owner.lua` (current implementation)

---

## 📞 Support

**Having issues?**
1. Check README.md > Testing Checklist
2. Check lua_implementation.md > Validation Rules
3. Check component_reference.md > (component name)
4. Check component_status.md > Workarounds section
5. Reference existing code in shop_view_owner.lua

**Need examples?**
- Check code_structure.lua for working patterns
- Check component_reference.md for usage examples
- Check design.md for conceptual understanding

---

**Status**: ✅ Ready to implement  
**Created**: 2026-02-17  
**Format**: Single-file views, no modular components (for now)
