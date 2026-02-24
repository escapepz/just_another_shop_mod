require("ISUI/ISPanel")
require("ISUI/ISButton")
require("ISUI/ISLabel")
require("ISUI/ISImage")

local TextureUtils = require("jasm/entity_ui/utils/texture_utils")

--- Individual row item representing one "Customer Option" (requirement path).
---@class ShopCustomerOptionItem : ISPanel
---@field path OwnerRequirementPath
---@field onRemove fun(target: any, path: OwnerRequirementPath)
---@field target any
---@field xuiSkin any
---@field iconSlot ISImage
local ShopCustomerOptionItem = ISPanel:derive("ShopCustomerOptionItem")

function ShopCustomerOptionItem:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopCustomerOptionItem:createChildren()
    ISPanel.createChildren(self)

    -- 1. MASTER LAYOUT: [Icon] [Name + Qty (fill)] [Debug Path] [Remove Btn]
    ---@type ISTableLayout
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    self:addChild(self.tableLayout)

    -- Columns: Icon (32) | Info (Fill) | Debug (Muted, Auto) | Remove (60)
    self.tableLayout:addColumn().minimumWidth = 32
    self.tableLayout:addColumnFill()
    self.tableLayout:addColumn()
    self.tableLayout:addColumn().minimumWidth = 60
    self.tableLayout:addRowFill()

    -- Left orange accent (static rect, not in layout)
    ---@type ISPanel
    local accent = ISPanel:new(0, 0, 3, self.height)
    accent:initialise()
    accent.background = true
    accent.backgroundColor = { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }
    self:addChild(accent)

    -- Icon Slot
    ---@type ISImage
    self.iconSlot = ISImage:new(0, 0, 24, 24, nil)
    self.iconSlot:initialise()
    self.iconSlot:instantiate()
    self.tableLayout:setElement(0, 0, self.iconSlot)

    -- Name + Qty
    ---@type ISLabel
    self.nameLabel = ISLabel:new(0, 0, 20, "Item Name", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.tableLayout:setElement(1, 0, self.nameLabel)

    -- Debug Type (Muted)
    ---@type ISLabel
    self.debugLabel = ISLabel:new(0, 0, 20, "Base.Type", 0.33, 0.33, 0.33, 1, UIFont.Small, false)
    self.tableLayout:setElement(2, 0, self.debugLabel)

    -- Remove Button
    ---@type ISButton
    self.removeBtn = self:xuiBuild(nil, ISButton, 0, 0, 50, 24, "Remove", self, function()
        ---@diagnostic disable-next-line: unnecessary-if
        if self.onRemove then
            self.onRemove(self.target, self.path)
        end
    end)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.removeBtn then
        self.removeBtn.textColor = { r = 1.0, g = 0.27, b = 0.27, a = 1.0 }
        self.tableLayout:setElement(3, 0, self.removeBtn)
    end

    self:updatePath(self.path)
end

---@param path OwnerRequirementPath
function ShopCustomerOptionItem:updatePath(path)
    self.path = path
    if not path then
        return
    end

    -- Update Text
    local dispName = tostring(path.qty) .. "x " .. (path.name or path.dbg)
    self.nameLabel:setName(dispName)
    self.debugLabel:setName(path.dbg or "")

    -- Update Icon
    ---@diagnostic disable-next-line: unnecessary-if
    if path.dbg then
        self.iconSlot.texture = TextureUtils.getItemTexture(path.dbg)
    else
        self.iconSlot.texture = nil
    end
end

function ShopCustomerOptionItem:calculateLayout(width, height)
    self:setWidth(width)
    self:setHeight(height)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
    end
end

function ShopCustomerOptionItem:new(x, y, w, h, path, target, onRemove, xuiSkin)
    ---@type ShopCustomerOptionItem
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.path = path
    o.target = target
    o.onRemove = onRemove
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    -- matches .list-row background
    o.background = true
    o.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
    return o
end

return ShopCustomerOptionItem
