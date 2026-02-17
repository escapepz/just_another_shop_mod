Ref from the template_1:

- .design\template_1\design.md
- .design\template_1\shop_ui_design.html

That makes total sense. You're moving from a simple "price" to a **Barter/Listing System**. This changes the UI from a simple static panel to a dynamic transaction display.

Here is the updated design template based on your item-to-item exchange requirement.

---

## 1. Owner View: "Market Listing & Management"

Since you want to support multiple listings for the same item type, the layout needs to handle "Drafting" a price and then "Adding" it to a list.

### **The Multi-Listing Logic**

- **Left Column (Inventory)**: Stays the same—it shows what is currently inside the container.
- **Right Column (The Listing Form)**:
- **The "Draft" Section**:
- **Item Type (String Entry)**: A text box for `"Base.Nails"`. (This replaces the old currency slot for now).
- **Amount (Int Entry)**: How many are required for the exchange.
- **Add Button**: A button that sends the command to save this specific Barter Pair.

- **The "Active Listings" Section**: A small scrollable list below the inputs showing what prices are already set for the selected item (e.g., "100x Nails", "1x Box of Nails"). This allows the owner to see and potentially delete specific listings.

---

## 2. Customer View: "Dynamic Barter Discovery"

This is where we solve the "Responsive Grid" and the "Itemized Price" display.

### **The Responsive Grid (ISTiledIconListBox)**

To handle the transition from 2 columns to 3+ columns when the window maximizes:

- **The Logic**: Instead of a fixed column count, the grid uses a `columnWidth` setting.
- **Layout Behavior**: As the 60% Fill area expands, the code calculates `floor(availableWidth / tileWidth)`. The layout engine will automatically wrap "Item 3" up to the first row if there is enough pixel room.

### **The Barter Details Panel**

The "Price" label is replaced by a **Barter Row**:

- **Icon + Label Combo**: Using an `ISImage` (the exchange item) + `ISLabel` (the name/amount).
- **Visual Flow**:

    > **Price:** [Small Icon] **Nails** x100

- **Future Proofing**: By using an "Exchange Item Type" string, your code can check if the string is a valid Item ID. If it's not (e.g., "virtual_money"), you can swap the icon for a "Gold Coin" texture instead of a world item texture.

---

## 3. Revised Layout Table (Item-to-Item)

| UI Element        | Layout Type        | Interaction                                                                                                                   |
| ----------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **Price Entry**   | `ISTextEntryBox`   | Owner types "Base.Nails". The UI should try to find the icon for this string immediately to give visual feedback.             |
| **Grid Tiles**    | `Flow Layout`      | Set `forceSize = true` on tiles so they don't stretch; they just rearrange into more columns as the 60% width grows.          |
| **Details Price** | `Horizontal Stack` | `Icon (32x32)` -> `Name (Text)` -> `Amount (Text)`. This prevents text and icons from overlapping when the item name is long. |

### **The "Listing" Logic Gap**

In your current Lua code, `modData.shopPrices` is a simple table (`prices[itemType] = priceInfo`). To support **Multiple Listings** for one item (e.g., Nails OR Water), you will need to change that data structure to a list:
`prices[itemType] = { {type="Base.Nails", count=100}, {type="Base.Hammer", count=1} }`
