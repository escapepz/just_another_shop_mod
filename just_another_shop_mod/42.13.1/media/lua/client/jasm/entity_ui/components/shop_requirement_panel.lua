require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("build_ui_skeleton/ISTableLayout")

local ShopSectionHeader = require("jasm/entity_ui/components/shop_section_header")
local CustomerOptionItem = require("jasm/entity_ui/components/shop_customer_option_item")

--- A panel that manages requirement paths (CUSTOMER OPTIONS).
---@class ShopRequirementPanel : ISPanel
---@field requirementPaths OwnerRequirementPath[]
---@field maxPaths integer
---@field inventory any
---@field onUnsavedChanges fun(target: any)
---@field onError fun(target: any, msg: string)
---@field onClearError fun(target: any)
---@field target any
---@field xuiSkin any
---@field tableLayout ISTableLayout|nil
---@field pathsTable ISTableLayout|nil
---@field addRow ISTableLayoutRow|nil
local ShopRequirementPanel = ISPanel:derive("ShopRequirementPanel")

function ShopRequirementPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopRequirementPanel:createChildren()
    ISPanel.createChildren(self)

    local INPUT_H = 26

    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if not self.tableLayout then
        return
    end
    self:addChild(self.tableLayout)

    self.tableLayout:addColumnFill()

    -- 1. Header
    local headRow = self.tableLayout:addRow()
    if headRow then
        self.header = ShopSectionHeader:new(
            0,
            0,
            self.width,
            40,
            "CUSTOMER OPTIONS (REQUIRE ONE OF)",
            self.xuiSkin
        )
        ---@diagnostic disable-next-line: unnecessary-if
        if self.header then
            self.header:initialise()
            self.header:instantiate()
            self.tableLayout:setElement(0, headRow:index(), self.header)
        end
    end

    -- 2. Paths List
    local listRow = self.tableLayout:addRow()
    if listRow then
        ---@diagnostic disable-next-line: inject-field
        listRow.marginTop = 6
        local pathListH = 210
        ---@type ISTableLayout|nil
        self.pathsTable = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, pathListH)
        if self.pathsTable then
            self.pathsTable:addColumnFill()
            self.tableLayout:setElement(0, listRow:index(), self.pathsTable)
        end
    end

    -- 3. Add Row
    self.addRow = self.tableLayout:addRow()
    if self.addRow then
        ---@diagnostic disable-next-line: inject-field
        self.addRow.marginTop = 8
        ---@type ISTableLayout|nil
        local addPathLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, INPUT_H)
        if addPathLayout then
            local cQ = addPathLayout:addColumn()
            cQ.minimumWidth = 55
            addPathLayout:addColumnFill()
            local cA = addPathLayout:addColumn()
            cA.minimumWidth = 50

            local ar = addPathLayout:addRowFill()
            if ar then
                ---@type ISTextEntryBox|nil
                self.newPathQtyInput = self:xuiBuild(nil, ISTextEntryBox, "1", 0, 0, 55, INPUT_H)
                if self.newPathQtyInput then
                    ---@diagnostic disable-next-line: undefined-field
                    self.newPathQtyInput:setPlaceholderText("Qty")
                    addPathLayout:setElement(0, ar:index(), self.newPathQtyInput)
                end

                ---@type ISTextEntryBox|nil
                self.newPathDbgInput = self:xuiBuild(nil, ISTextEntryBox, "", 0, 0, 10, INPUT_H)
                if self.newPathDbgInput then
                    ---@diagnostic disable-next-line: inject-field
                    self.newPathDbgInput.calculateLayout = function(_self, _w, _h)
                        _self:setWidth(_w)
                    end
                    self.newPathDbgInput:setPlaceholderText("e.g. Base.Gold")
                    addPathLayout:setElement(1, ar:index(), self.newPathDbgInput)
                end

                ---@type ISButton|nil
                self.addPathBtn = self:xuiBuild(
                    nil,
                    ISButton,
                    0,
                    0,
                    50,
                    INPUT_H,
                    "Add",
                    self,
                    self.onAddPathClicked
                )
                if self.addPathBtn then
                    addPathLayout:setElement(2, ar:index(), self.addPathBtn)
                end
            end
            self.tableLayout:setElement(0, self.addRow:index(), addPathLayout)
        end
    end

    self:refreshList()
end

function ShopRequirementPanel:onAddPathClicked()
    if not self.newPathQtyInput or not self.newPathDbgInput then
        return
    end

    local qty = tonumber(self.newPathQtyInput:getText()) or 1
    local dbg = self.newPathDbgInput:getText()
    dbg = dbg and dbg:match("^%s*(.-)%s*$") or ""

    if dbg == "" then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Debug name cannot be empty")
        end
        return
    end

    local mapped = self.inventory and self.inventory.map and self.inventory.map[dbg]
    if not mapped then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Invalid debug name: " .. dbg)
        end
        return
    end

    if qty < 1 then
        qty = 1
    end

    if #self.requirementPaths >= self.maxPaths then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Maximum " .. self.maxPaths .. " requirement paths allowed")
        end
        return
    end

    local path = {
        dbg = dbg,
        qty = qty,
        name = mapped.name or dbg,
        icon = mapped.icon,
    }
    table.insert(self.requirementPaths, path)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onUnsavedChanges then
        self.onUnsavedChanges(self.target)
    end

    self.newPathQtyInput:setText("1")
    self.newPathDbgInput:setText("")
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onClearError then
        self.onClearError(self.target)
    end
    self:refreshList()
end

function ShopRequirementPanel:onRemovePath(path)
    for i = 1, #self.requirementPaths do
        if self.requirementPaths[i] == path then
            table.remove(self.requirementPaths, i)
            break
        end
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onUnsavedChanges then
        self.onUnsavedChanges(self.target)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onClearError then
        self.onClearError(self.target)
    end
    self:refreshList()
end

function ShopRequirementPanel:updateAddRowVisibility()
    local visible = #self.requirementPaths < self.maxPaths
    if self.addRow then
        self.addRow:setVisible(visible)
    end
end

function ShopRequirementPanel:refreshList()
    if not self.pathsTable then
        return
    end
    self.pathsTable:clearTable()
    self.pathsTable:addColumnFill()

    for i = 1, #self.requirementPaths do
        local path = self.requirementPaths[i]
        ---@type ShopCustomerOptionItem
        local item = CustomerOptionItem:new(
            0,
            0,
            self.pathsTable:getWidth(),
            40,
            path,
            self,
            self.onRemovePath,
            self.xuiSkin
        )
        ---@diagnostic disable-next-line: unnecessary-if
        if item then
            local row = self.pathsTable:addRow()
            ---@diagnostic disable-next-line: unnecessary-if
            if row then
                row.minimumHeight = 40
            end
            self.pathsTable:setElement(0, i - 1, item)
        end
    end

    self:updateAddRowVisibility()

    -- Visibility update for "Add" row logic if needed
    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:calculateLayout(self.width, self.height)
    end
end

function ShopRequirementPanel:setRequirementPaths(paths)
    self.requirementPaths = paths or {}
    self:refreshList()
end

function ShopRequirementPanel:calculateLayout(width, height)
    self:setWidth(width)
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
        self:setHeight(self.tableLayout:getHeight())
    end
end

function ShopRequirementPanel:new(
    x,
    y,
    w,
    h,
    paths,
    maxPaths,
    inventory,
    target,
    callbacks,
    xuiSkin
)
    ---@type ShopRequirementPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.requirementPaths = paths or {}
    o.maxPaths = maxPaths or 5
    o.inventory = inventory
    o.target = target
    o.onUnsavedChanges = callbacks and callbacks.onUnsavedChanges
    o.onError = callbacks and callbacks.onError
    o.onClearError = callbacks and callbacks.onClearError
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopRequirementPanel
