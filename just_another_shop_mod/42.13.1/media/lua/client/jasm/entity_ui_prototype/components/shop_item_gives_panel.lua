local ShopSectionHeader = require("jasm_test/components/shop_section_header")
require("Entity/ISUI/Controls/ISTableLayout")
require("ISUI/ISImage")

---@class ShopItemGivesPanel : ISPanel
---@field headerPanel ShopSectionHeader
---@field tableLayout ISTableLayout
---@field receiveIconSlot ISImage
---@field receiveName ISLabel
---@field receiveQty ISLabel
---@field xuiSkin any
local ShopItemGivesPanel = ISPanel:derive("ShopItemGivesPanel")

local UI_BORDER_SPACING = 12

function ShopItemGivesPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopItemGivesPanel:createChildren()
    ISPanel.createChildren(self)

    self.background = true
    -- #1a1a1a background
    self.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
    -- #333 border
    self.borderColor = { r = 0.20, g = 0.20, b = 0.20, a = 1.0 }

    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if self.tableLayout then
        self.tableLayout:addColumnFill()
        self:addChild(self.tableLayout)
    end

    -- Header
    self.headerPanel = ShopSectionHeader:new(0, 0, self.width, 40, "SHOP GIVES", self.xuiSkin)
    if self.headerPanel and self.tableLayout then
        self.headerPanel:initialise()
        self.headerPanel:instantiate()
        self.tableLayout:addRow()
        self.tableLayout:setElement(0, 0, self.headerPanel)
    end

    -- Item Card/Info Row
    if self.tableLayout then
        local rInfo = self.tableLayout:addRowFill()
        if rInfo then
            ---@type ISTableLayout|nil
            local infoTable = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
            if infoTable then
                local cIcon = infoTable:addColumn()
                cIcon.minimumWidth = 50
                infoTable:addColumnFill() -- Name/Qty stack
                infoTable:addRowFill()

                ---@type ISImage|nil
                self.receiveIconSlot = self:xuiBuild(nil, ISImage, 0, 0, 40, 40, nil)
                if self.receiveIconSlot then
                    infoTable:setElement(0, 0, self.receiveIconSlot)
                end

                ---@type ISTableLayout|nil
                local metaTable = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
                if metaTable then
                    metaTable:addColumnFill()

                    local _rName = metaTable:addRow()
                    self.receiveName =
                        self:xuiBuild(nil, ISLabel, 0, 0, 20, "", 1, 1, 1, 1, UIFont.Small, false)
                    if self.receiveName then
                        ---@diagnostic disable-next-line: inject-field
                        self.receiveName.calculateLayout = function(_slf, _w, _h)
                            _slf:setWidth(_w)
                        end
                        metaTable:setElement(0, 0, self.receiveName)
                    end

                    local _rQty = metaTable:addRow()
                    self.receiveQty = self:xuiBuild(
                        nil,
                        ISLabel,
                        0,
                        0,
                        20,
                        "Quantity: 1",
                        0.53,
                        0.53,
                        0.53,
                        1,
                        UIFont.Small,
                        false
                    )
                    if self.receiveQty then
                        ---@diagnostic disable-next-line: inject-field
                        self.receiveQty.calculateLayout = function(_slf, _w, _h)
                            _slf:setWidth(_w)
                        end
                        metaTable:setElement(0, 1, self.receiveQty)
                    end

                    infoTable:setElement(1, 0, metaTable)
                end

                self.tableLayout:setElement(0, 1, infoTable)
            end
        end
    end
end

function ShopItemGivesPanel:setItem(name, qty, icon)
    self.receiveName:setName(name or "")
    self.receiveQty:setName("Quantity: " .. tostring(qty or 1))
    local tex = icon
    if tex and type(tex) == "string" then
        tex = getTexture(tex)
    end
    self.receiveIconSlot.texture = tex
end

function ShopItemGivesPanel:calculateLayout(width, height)
    self:setWidth(width)
    self.tableLayout:calculateLayout(width, height)
    self:setHeight(self.tableLayout:getHeight())
    self.headerPanel:calculateLayout(width, self.headerPanel:getHeight())
end

function ShopItemGivesPanel:new(x, y, w, h, xuiSkin)
    ---@type ShopItemGivesPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopItemGivesPanel
