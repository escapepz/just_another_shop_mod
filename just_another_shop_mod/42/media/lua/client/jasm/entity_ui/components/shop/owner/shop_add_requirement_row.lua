require("ISUI/ISPanel")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("Entity/ISUI/Controls/ISTableLayout")

---@class ShopAddRequirementRow : ISPanel
---@field addPathLayout ISTableLayout|nil
---@field newPathQtyInput ISTextEntryBox|nil
---@field newPathTypeInput ISTextEntryBox|nil
---@field addPathBtn ISButton|nil
---@field target any
---@field onAdd fun(target: any, qty: number, itemType: string)
---@field xuiSkin any
local ShopAddRequirementRow = ISPanel:derive("ShopAddRequirementRow")

function ShopAddRequirementRow:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopAddRequirementRow:createChildren()
    ISPanel.createChildren(self)

    -- Matches ShopCustomerOptionItem accent (slightly different color for "Action" row)
    local accent = ISPanel:new(0, 0, 3, self.height)
    accent:initialise()
    accent.background = true
    accent.backgroundColor = { r = 0.27, g = 0.61, b = 1.0, a = 1.0 } -- Blue accent for "New"
    self:addChild(accent)

    -- Main layout: [Qty] [Type (fill)] [Add Btn]
    ---@type ISTableLayout
    self.addPathLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.addPathLayout then
        local cQ = self.addPathLayout:addColumn()
        cQ.minimumWidth = 55
        self.addPathLayout:addColumnFill()
        local cA = self.addPathLayout:addColumn()
        cA.minimumWidth = 60

        local ar = self.addPathLayout:addRowFill()
        if ar then
            ar.minimumHeight = self.height

            -- Padding/Margin for inputs to make them "modern" (smaller than row height)
            local inputH = 22
            local inputMargin = (self.height - inputH) / 2

            ---@type ISTextEntryBox
            self.newPathQtyInput =
                self:xuiBuild(nil, ISTextEntryBox, "1", 0, inputMargin, 55, inputH)
            ---@diagnostic disable-next-line: unnecessary-if
            if self.newPathQtyInput then
                self.newPathQtyInput:setPlaceholderText("Qty")
                ---@diagnostic disable-next-line: unnecessary-if
                -- Note: setOnlyNumbers might be version dependent, using standard PZ check if needed
                if self.newPathQtyInput.setOnlyNumbers then
                    self.newPathQtyInput:setOnlyNumbers(true)
                end
                self.addPathLayout:setElement(0, ar:index(), self.newPathQtyInput)
            end

            -- Using a larger initial width or letting layout handle it;
            -- Fill column will dictate the final size in calculateLayout
            ---@type ISTextEntryBox
            self.newPathTypeInput =
                self:xuiBuild(nil, ISTextEntryBox, "", 0, inputMargin, 200, inputH)
            ---@diagnostic disable-next-line: unnecessary-if
            if self.newPathTypeInput then
                self.newPathTypeInput:setPlaceholderText("Type e.g. Base.GoldBar")
                self.addPathLayout:setElement(1, ar:index(), self.newPathTypeInput)
            end

            ---@type ISButton
            self.addPathBtn = self:xuiBuild(
                nil,
                ISButton,
                0,
                inputMargin,
                60,
                inputH,
                "Add",
                self,
                self.onAddClicked
            )
            ---@diagnostic disable-next-line: unnecessary-if
            if self.addPathBtn then
                self.addPathBtn.textColor = { r = 0.27, g = 0.61, b = 1.0, a = 1.0 }
                self.addPathLayout:setElement(2, ar:index(), self.addPathBtn)
            end
        end
        self:addChild(self.addPathLayout)
    end
end

function ShopAddRequirementRow:onAddClicked()
    if not self.newPathQtyInput or not self.newPathTypeInput then
        return
    end

    local qty = tonumber(self.newPathQtyInput:getText()) or 1
    local itemType = self.newPathTypeInput:getText()
    itemType = itemType and itemType:match("^%s*(.-)%s*$") or ""

    if itemType ~= "" and self.onAdd then
        self.onAdd(self.target, qty, itemType)
    end
end

function ShopAddRequirementRow:clearInputs()
    if self.newPathQtyInput then
        self.newPathQtyInput:setText("1")
    end
    if self.newPathTypeInput then
        self.newPathTypeInput:setText("")
    end
end

function ShopAddRequirementRow:calculateLayout(width, height)
    self:setWidth(width)
    self:setHeight(height)
    if self.addPathLayout then
        self.addPathLayout:calculateLayout(width, height)
    end
end

function ShopAddRequirementRow:new(x, y, w, h, target, onAdd, xuiSkin)
    ---@type ShopAddRequirementRow
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.onAdd = onAdd
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()

    -- Aesthetic matching ShopCustomerOptionItem
    o.background = true
    o.backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 } -- Slightly lighter or same
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 } -- No Border

    return o
end

return ShopAddRequirementRow
