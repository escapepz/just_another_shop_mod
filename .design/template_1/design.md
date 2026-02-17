Here is the suggested design template for the Shop UI, organized by the two main views.

---

## 1. Customer View: "Product Discovery" Template

The goal here is to prioritize the product grid while keeping the purchase actions anchored to the right.

- **Main Container (ISTableLayout)**: A 2-column, 1-row split.
- **Column A (60% Width - Fill)**: Contains the `ISTiledIconListBox`. This should be set to "Fill" so it expands automatically when the player stretches the window.
- **Column B (40% Width - Fixed or Fill)**: Contains the **Details Sub-Layout**.

- **Details Sub-Layout (Vertical Stack)**:
- **Row 1 (Static Height)**: Product Title (UIFont.Medium).
- **Row 2 (Static Height)**: Price Display with Icon.
- **Row 3 (Spring/Spacer)**: An empty "Fill" row to push the buy button to the bottom, preventing it from floating awkwardly in the middle.
- **Row 4 (Static Height)**: The "EXCHANGE" Button and Error Label.

---

## 2. Owner View: "Management & Pricing" Template

This layout is more complex because it requires precise alignment between the inventory list and the input fields.

- **Main Container (ISTableLayout)**: A 2-column split (50/50).
- **Left Column**: A "Fill" container for the `ISScrollingListBox`.
- **Right Column**: The **Pricing Form Sub-Layout**.

- **Pricing Form Sub-Layout (2 Columns x 4 Rows)**:
- Using a 2-column internal table ensures that the "Labels" (Currency, Amount) always line up perfectly with their "Inputs" (Slot, TextBox), regardless of window size.
- **Row 1**: Header (Spans both columns).
- **Row 2**: | Label: Currency | Input: Item Slot |
- **Row 3**: | Label: Amount | Input: Text Box |
- **Row 4**: | (Empty) | Button: Save |

---

## 3. Key Design Principles for your Lua Components

To prevent the "visual jumping" you are currently experiencing, follow these layout rules:

| Feature       | Design Rule                                                                                                                                                   |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sizing**    | Never use `self.width / 2` inside `createChildren`. Use `addColumnFill()` and let the layout engine calculate the math at runtime.                            |
| **Nesting**   | Every `ISPanel` used as a container for a sub-layout must have its `calculateLayout` called **by the parent**, never manually triggered inside its own logic. |
| **Anchoring** | Use "Spring" rows (rows with no minimum height but "Fill" enabled) to push important buttons to the bottom of the panel.                                      |
