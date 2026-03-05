---@diagnostic disable: unnecessary-if
local ShopSectionHeader =
    require("just_another_shop_mod/entity_ui/components/shop/shared/shop_section_header")
require("Entity/ISUI/Controls/ISTableLayout")
require("ISUI/ISLabel")
--- Individual row item representing the top header of the item details.
---@class ShopItemHeader : ISPanel
---@field sectionHeader ShopSectionHeader
---@field nameLabel ISLabel
---@field typeLabel ISLabel
---@field stockLabel ISLabel
---@field xuiSkin any
---@field tableLayout ISTableLayout
local ShopItemHeader = ISPanel:derive("ShopItemHeader")

function ShopItemHeader:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopItemHeader:createChildren()
    ISPanel.createChildren(self)

    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if self.tableLayout then
        self.tableLayout:addColumnFill()
        self:addChild(self.tableLayout)
    end

    -- 1. Static Section Header - Matches "SHOP GIVES" / "YOU NEED"
    self.sectionHeader = ShopSectionHeader:new(0, 0, self.width, 40, "TRADE DETAILS", self.xuiSkin)
    if self.sectionHeader and self.tableLayout then
        self.sectionHeader:initialise()
        self.sectionHeader:instantiate()
        self.tableLayout:addRow()
        self.tableLayout:setElement(0, 0, self.sectionHeader)
    end

    -- 2. Item Info Area (Text Stack)
    if self.tableLayout then
        local rInfo = self.tableLayout:addRowFill()
        if rInfo then
            -- Labels Stack
            ---@type ISTableLayout|nil
            local labelTable = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
            if labelTable then
                labelTable:addColumnFill()

                local _rName = labelTable:addRow()
                self.nameLabel = self:xuiBuild(
                    nil,
                    ISLabel,
                    0,
                    0,
                    24,
                    "Select an item",
                    1,
                    1,
                    1,
                    1,
                    UIFont.Medium,
                    true
                )
                if self.nameLabel then
                    ---@diagnostic disable-next-line: inject-field
                    self.nameLabel.calculateLayout = function(_slf, _w, _h)
                        _slf:setWidth(_w)
                    end
                    labelTable:setElement(0, 0, self.nameLabel)
                end

                local _rType = labelTable:addRow()
                self.typeLabel = self:xuiBuild(
                    nil,
                    ISLabel,
                    0,
                    0,
                    20,
                    "",
                    0.40,
                    0.40,
                    0.40,
                    1,
                    UIFont.Small,
                    true
                )
                if self.typeLabel then
                    ---@diagnostic disable-next-line: inject-field
                    self.typeLabel.calculateLayout = function(_slf, _w, _h)
                        _slf:setWidth(_w)
                    end
                    labelTable:setElement(0, 1, self.typeLabel)
                end

                local _rStock = labelTable:addRow()
                self.stockLabel = self:xuiBuild(
                    nil,
                    ISLabel,
                    0,
                    0,
                    20,
                    "",
                    0.53,
                    0.53,
                    0.53,
                    1,
                    UIFont.Small,
                    true
                )
                if self.stockLabel then
                    ---@diagnostic disable-next-line: inject-field
                    self.stockLabel.calculateLayout = function(_slf, _w, _h)
                        _slf:setWidth(_w)
                    end
                    labelTable:setElement(0, 2, self.stockLabel)
                end

                self.tableLayout:setElement(0, 1, labelTable)
            end
        end
    end
end

function ShopItemHeader:setItem(name, typeName, stock, icon)
    if self.nameLabel then
        self.nameLabel:setName(name or "Select an item")
    end

    if self.typeLabel then
        self.typeLabel:setName(typeName or "")
    end

    if self.stockLabel then
        self.stockLabel:setName(stock and ("Stock: " .. tostring(stock)) or "")
    end
end

function ShopItemHeader:calculateLayout(width, height)
    self:setWidth(width)

    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
        self:setHeight(self.tableLayout:getHeight())
    end

    if self.sectionHeader then
        self.sectionHeader:calculateLayout(width, self.sectionHeader:getHeight())
    end
end

function ShopItemHeader:new(x, y, w, h, xuiSkin)
    ---@type ShopItemHeader
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopItemHeader
