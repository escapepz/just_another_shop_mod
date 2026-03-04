require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("ISUI/ISTextEntryBox")
require("Entity/ISUI/Controls/ISTableLayout")

local ShopSectionHeader =
    require("just_another_shop_mod/entity_ui/components/shop/shared/shop_section_header")
local CustomerOptionItem =
    require("just_another_shop_mod/entity_ui/components/shop/owner/shop_customer_option_item")
local ShopAddRequirementRow =
    require("just_another_shop_mod/entity_ui/components/shop/owner/shop_add_requirement_row")

--- A panel that manages requirement paths (CUSTOMER OPTIONS).
---@class ShopRequirementPanel : ISPanel
---@field requirementPaths OwnerRequirementPath[]
---@field maxPaths integer
---@field inventory any
---@field onUnsavedChanges fun(target: any)
---@field onError fun(target: any, msg: string)
---@field onClearError fun(target: any)
---@field target any
---@field addComp ShopAddRequirementRow|nil
---@field addPathRow ISTableLayoutRow|nil
---@field xuiSkin any
---@field tableLayout ISTableLayout|nil
---@field pathsTable ISTableLayout|nil
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
        listRow.minimumHeight = pathListH
        ---@type ISTableLayout|nil
        self.pathsTable = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, pathListH)
        if self.pathsTable then
            self.pathsTable:addColumnFill()
            self.tableLayout:setElement(0, listRow:index(), self.pathsTable)
        end
    end
    -- 3. Prepare the "Add Path" component
    self.addComp = self:xuiBuild(
        nil,
        ShopAddRequirementRow,
        0,
        0,
        self.width,
        40,
        self,
        self.onAddPathClicked,
        self.xuiSkin
    )
    self.addPathRow = nil

    self:refreshList()
end

function ShopRequirementPanel:onAddPathClicked(requestQty, itemType)
    if not itemType or itemType == "" then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Type cannot be empty")
        end
        return
    end

    local itemScript = ScriptManager.instance:getItem(itemType)
    if not itemScript then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Invalid item type: " .. itemType)
        end
        return
    end

    requestQty = math.max(1, math.floor(tonumber(requestQty) or 1))

    if #self.requirementPaths >= self.maxPaths then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onError then
            self.onError(self.target, "Maximum " .. self.maxPaths .. " requirement paths allowed")
        end
        return
    end

    local path = {
        itemType = itemType,
        requestQty = requestQty,
        name = itemScript:getDisplayName() or itemType,
        icon = itemScript:getIcon(),
    }
    table.insert(self.requirementPaths, path)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onUnsavedChanges then
        self.onUnsavedChanges(self.target)
    end

    if self.addComp then
        self.addComp:clearInputs()
    end
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

-- refreshList adds items and potentially the "add path" row to the pathsTable.
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
            item:initialise()
            item:instantiate()
            local row = self.pathsTable:addRow()
            if row then
                row.minimumHeight = 40
                self.pathsTable:setElement(0, row:index(), item)
            end
        end
    end

    if #self.requirementPaths < self.maxPaths and self.addComp then
        self.addPathRow = self.pathsTable:addRow()
        if self.addPathRow then
            self.addPathRow.minimumHeight = 40
            self.pathsTable:setElement(0, self.addPathRow:index(), self.addComp)
        end
    else
        self.addPathRow = nil
    end

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

    if self.addComp then
        self.addComp:calculateLayout(width, 40)
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
