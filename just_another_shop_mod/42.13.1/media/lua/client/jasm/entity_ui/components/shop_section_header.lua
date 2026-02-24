require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("build_ui_skeleton/ISTableLayout")

--- A reusable styled section header with an orange bottom-border line.
---@class ShopSectionHeader : ISPanel
---@field title string
---@field xuiSkin any
local ShopSectionHeader = ISPanel:derive("ShopSectionHeader")

function ShopSectionHeader:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopSectionHeader:createChildren()
    ISPanel.createChildren(self)
    self:initLayout()
    self:addHeaderRow()
    self:addLineRow()
end

function ShopSectionHeader:initLayout()
    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if self.tableLayout then
        self:addChild(self.tableLayout)
        self.tableLayout:addColumnFill()
    end
end

function ShopSectionHeader:addHeaderRow()
    if not self.tableLayout then
        return
    end
    local headRow = self.tableLayout:addRow()
    if headRow then
        ---@diagnostic disable-next-line: inject-field
        headRow.marginTop = 11 -- R_PAD (16) - 5
        --- h1 color: #f39c12, font size ~18px
        ---@type ISLabel|nil
        self.headerLabel = self:xuiBuild(
            nil,
            ISLabel,
            0,
            0,
            28,
            self.title or "",
            0.95,
            0.61,
            0.07,
            1,
            UIFont.Medium,
            true
        )
        if self.headerLabel then
            self.tableLayout:setElement(0, headRow:index(), self.headerLabel)
        end
    end
end

function ShopSectionHeader:addLineRow()
    if not self.tableLayout then
        return
    end
    -- Header bottom-border line (#f39c12)
    local hr1Row = self.tableLayout:addRow()
    if hr1Row then
        ---@diagnostic disable-next-line: inject-field
        hr1Row.marginTop = 2
        ---@diagnostic disable-next-line: inject-field
        hr1Row.marginBottom = 16 -- R_PAD
        ---@type ISPanel|nil
        local headerLine = self:xuiBuild(nil, ISPanel, 0, 0, self.width, 2)
        if headerLine then
            ---@diagnostic disable-next-line: inject-field
            headerLine.calculateLayout = function(_self, _w, _h)
                _self:setWidth(_w)
            end
            headerLine.background = true
            headerLine.backgroundColor = { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }
            self.tableLayout:setElement(0, hr1Row:index(), headerLine)
        end
    end
end

function ShopSectionHeader:setTitle(title)
    self.title = title
    if self.headerLabel then
        self.headerLabel:setName(title or "")
    end
end

function ShopSectionHeader:calculateLayout(width, height)
    self:setWidth(width)
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
        self:setHeight(self.tableLayout:getHeight())
    end
end

function ShopSectionHeader:new(x, y, w, h, title, xuiSkin)
    ---@type ShopSectionHeader
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.title = title
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopSectionHeader
