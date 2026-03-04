require("ISUI/ISPanel")
require("ISUI/ISTextEntryBox")
require("ISUI/ISComboBox")
require("ISUI/ISButton")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

--- Panel that contains the search box, sort options, and optionally view mode toggle.
--- Set `self.slim = true` before initialise() to build a single-row
--- search + sort panel with no category combo or view-toggle button.
---@class ShopSearchFilterPanel : ISPanel
---@field searchBox ISTextEntryBox
---@field sortCombo ISComboBox
---@field categoryCombo ISComboBox|nil
---@field viewBtn ISButton|nil
---@field tableLayout ISTableLayout
---@field xuiSkin any
---@field target any
---@field slim boolean   -- if true: search + sort only (no category combo, no view toggle)
---@field onSearch function
---@field onSort function
---@field onViewToggle function|nil
local ShopSearchFilterPanel = ISPanel:derive("ShopSearchFilterPanel")

--- Helper to build, initialise and instantiate a component in one go.
function ShopSearchFilterPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        ---@diagnostic disable-next-line: unnecessary-if
        if o.initialise then
            o:initialise()
        end
        ---@diagnostic disable-next-line: unnecessary-if
        if o.instantiate then
            o:instantiate()
        end
    end
    return o
end

--- Helper to build a component and immediately place it in a layout slot.
function ShopSearchFilterPanel:xuiBuildInLayout(layout, col, row, style, class, ...)
    local o = self:xuiBuild(style, class, ...)
    if o and layout then
        layout:setElement(col, row, o)
    end
    return o
end

-- ============================================================
-- SLIM MODE  (search + sort only, single row)
-- ============================================================

function ShopSearchFilterPanel:createChildren()
    ISPanel.createChildren(self)

    -- 1. MASTER LAYOUT (2 Vertical Slots)
    ---@type ISTableLayout
    self.tableLayout =
        self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height, nil, nil, nil)
    self:addChild(self.tableLayout)
    self.tableLayout:addColumnFill()
    local row0 = self.tableLayout:addRow() -- Row 0: Search / Filter line
    if row0 then
        row0.minimumHeight = 24
    end
    local row1 = self.tableLayout:addRow() -- Row 1: Sort / Meta line
    if row1 then
        row1.minimumHeight = 24
    end

    -- 2. TOP ROW: Search box
    ---@type ISTextEntryBox
    self.searchBox = self:xuiBuild(nil, ISTextEntryBox, "", 0, 0, 10, 24)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.searchBox then
        ---@diagnostic disable-next-line: inject-field
        self.searchBox.calculateLayout = function(_self, _w, _h)
            _self:setWidth(_w)
            -- No height sync: keep fixed 24px
        end
        self.searchBox:setPlaceholderText("Search items...")
        self.searchBox.onTextChange = function()
            ---@diagnostic disable-next-line: unnecessary-if
            if self.onSearch then
                self.onSearch(self.target, self.searchBox:getText())
            end
        end
        self.searchBox:setClearButton(true)

        -- BOTH modes use topLayout for consistent double-padding (y indent)
        ---@type ISTableLayout|nil
        local topLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10, nil, nil, nil)
        if topLayout then
            topLayout:addColumnFill() -- Search column (always exists)
            if not self.slim then
                topLayout:addColumn().minimumWidth = 140 -- Category combo
                topLayout:addColumn().minimumWidth = 32 -- View toggle button
            end

            local tr = topLayout:addRow()
            if tr then
                tr.minimumHeight = 24
            end

            topLayout:setElement(0, 0, self.searchBox)

            if not self.slim then
                -- Category Combo
                ---@type ISComboBox
                self.categoryCombo = self:xuiBuild(
                    nil,
                    ISComboBox,
                    0,
                    0,
                    10,
                    24,
                    self,
                    function() end
                )
                ---@diagnostic disable-next-line: unnecessary-if
                if self.categoryCombo then
                    ---@diagnostic disable-next-line: inject-field
                    self.categoryCombo.calculateLayout = function(_self, _w, _h)
                        _self:setWidth(_w)
                    end
                    ---@diagnostic disable-next-line: inject-field
                    self.categoryCombo.doRepaintStencil = true
                    self.categoryCombo:addOption("Shop Stock")
                    self.categoryCombo:addOption("Required Items")
                    topLayout:setElement(1, 0, self.categoryCombo)
                end

                -- View Toggle Button (≡ / ::)
                ---@type ISButton
                self.viewBtn = self:xuiBuild(nil, ISButton, 0, 0, 28, 24, "≡", self, function()
                    local newMode = self.viewMode == "grid" and "list" or "grid"
                    self:onToggleMode(newMode)
                end)
                topLayout:setElement(2, 0, self.viewBtn)
            end

            self.tableLayout:setElement(0, 0, topLayout)
        end
    end

    -- 3. BOTTOM ROW: Sort Label + Sort Combo
    ---@type ISTableLayout|nil
    local bottomLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10, nil, nil, nil)
    if bottomLayout then
        bottomLayout:addColumnFill() -- Spacer
        bottomLayout:addColumn().minimumWidth = 60 -- "Sort by:" label
        bottomLayout:addColumn().minimumWidth = 172 -- Sort combo
        local br = bottomLayout:addRow()
        if br then
            br.minimumHeight = 24
        end
        self.tableLayout:setElement(0, 1, bottomLayout)

        local sortLabel = ISLabel:new(0, 0, 24, "Sort by:", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
        bottomLayout:setElement(1, 0, sortLabel)

        ---@type ISComboBox
        self.sortCombo = self:xuiBuild(nil, ISComboBox, 0, 0, 10, 24, self, self.onSelectSort)
        ---@diagnostic disable-next-line: unnecessary-if
        if self.sortCombo then
            ---@diagnostic disable-next-line: inject-field
            self.sortCombo.calculateLayout = function(_self, _w, _h)
                _self:setWidth(_w)
            end
            ---@diagnostic disable-next-line: inject-field
            self.sortCombo.doRepaintStencil = true
            self.sortCombo:addOption("Alphabetical (A-Z)")
            self.sortCombo:addOption("High Stock")
            self.sortCombo:addOption("Low Stock")
            bottomLayout:setElement(2, 0, self.sortCombo)
        end
    end

    -- Initial State
    if self.slim then
        self:onToggleMode("list")
    else
        self:onToggleMode("grid")
    end
end

-- ============================================================
-- SHARED CALLBACKS
-- ============================================================

--- Callback when the view mode is toggled via buttons.
---@param mode string "grid" or "list".
function ShopSearchFilterPanel:onToggleMode(mode)
    logger:debug("ShopSearchFilterPanel:onToggleMode() mode: " .. tostring(mode))
    self.viewMode = mode

    ---@diagnostic disable-next-line: unnecessary-if
    if self.viewBtn then
        if mode == "grid" then
            self.viewBtn:setTitle("≡")
        else
            self.viewBtn:setTitle("::")
        end
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.onViewToggle then
        self.onViewToggle(self.target, mode)
    end
end

--- Callback when a sort option is selected from the combo box.
function ShopSearchFilterPanel:onSelectSort()
    logger:debug("ShopSearchFilterPanel:onSelectSort() called")
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onSort then
        self.onSort(self.target, self.sortCombo:getOptionText(self.sortCombo.selected))
    end
end

function ShopSearchFilterPanel:calculateLayout(width, height)
    self:setWidth(width)
    self:setHeight(height)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
    end
end

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

--- Create a new instance of ShopSearchFilterPanel.
---@param x number
---@param y number
---@param width number
---@param height number
---@param target any
---@param xuiSkin any
---@param slim boolean|nil  Pass true for search+sort only (no category/view toggle)
---@return ShopSearchFilterPanel
function ShopSearchFilterPanel:new(x, y, width, height, target, xuiSkin, slim)
    logger:debug("ShopSearchFilterPanel:new() called slim=" .. tostring(slim))
    ---@type ShopSearchFilterPanel
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.xuiSkin = xuiSkin
    o.slim = slim == true
    o.background = true
    o.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1 }
    o.viewMode = "grid"
    return o
end

return ShopSearchFilterPanel
