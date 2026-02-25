require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISTextEntryBox")
require("ISUI/ISImage")
require("Entity/ISUI/Controls/ISTableLayout")

local ShopSectionHeader = require("jasm/entity_ui/components/shop/shared/shop_section_header")

---@class ShopTradeOfferPanel : ISPanel
---@field target any
---@field onQtyChanged fun(target: any)
---@field xuiSkin any
---@field sectionHeader ShopSectionHeader
---@field offerIcon ISImage
---@field offerName ISLabel
---@field offerDebug ISLabel
---@field offerStock ISLabel
---@field offerQtyInput ISTextEntryBox
---@field yieldInfo ISLabel
---@field tableLayout ISTableLayout
---@field setQty fun(qty: number)
local ShopTradeOfferPanel = ISPanel:derive("ShopTradeOfferPanel")

function ShopTradeOfferPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopTradeOfferPanel:createChildren()
    ISPanel.createChildren(self)

    local INPUT_H = 26
    local R_PAD = 16

    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if not self.tableLayout then
        return
    end
    self:addChild(self.tableLayout)
    self.tableLayout:addColumnFill()

    -- Section label "ITEM TO GIVE (OFFER)"
    self.sectionHeader =
        ShopSectionHeader:new(0, 0, self.width, 40, "ITEM TO GIVE (OFFER)", self.xuiSkin)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.sectionHeader and self.tableLayout then
        self.sectionHeader:initialise()
        self.sectionHeader:instantiate()
        local rHeader = self.tableLayout:addRow()
        if rHeader then
            rHeader.minimumHeight = 40
        end
        self.tableLayout:setElement(0, 0, self.sectionHeader)
    end

    -- Offer box
    local boxH = 70
    local offerBoxRow = self.tableLayout:addRow()
    if offerBoxRow then
        ---@diagnostic disable-next-line: inject-field
        offerBoxRow.marginTop = 6
        ---@type ISTableLayout|nil
        local offerBox = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, boxH)
        if offerBox then
            offerBox.background = true
            offerBox.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
            offerBox.borderColor = { r = 0.20, g = 0.20, b = 0.20, a = 1.0 }

            local obColIcon = offerBox:addColumn()
            obColIcon.minimumWidth = 50
            offerBox:addColumnFill() -- meta col
            local obColQty = offerBox:addColumn()
            obColQty.minimumWidth = 70

            local obRow = offerBox:addRowFill()
            if obRow then
                ---@type ISImage|nil
                self.offerIcon = self:xuiBuild(nil, ISImage, 0, 0, 40, 40, nil)
                ---@diagnostic disable-next-line: unnecessary-if
                if self.offerIcon then
                    offerBox:setElement(0, obRow:index(), self.offerIcon)
                end

                ---@type ISTableLayout|nil
                local infoStack = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
                if infoStack then
                    infoStack:addColumnFill()
                    ---@type ISLabel|nil
                    self.offerName = self:xuiBuild(
                        nil,
                        ISLabel,
                        0,
                        0,
                        18,
                        "Select an item",
                        1.0,
                        1.0,
                        1.0,
                        1,
                        UIFont.Small,
                        false
                    )
                    local rName = infoStack:addRowFill()
                    ---@diagnostic disable-next-line: unnecessary-if
                    if self.offerName and rName then
                        ---@diagnostic disable-next-line: inject-field
                        self.offerName.calculateLayout = function(_slf, _w, _h)
                            _slf:setWidth(_w)
                        end
                        infoStack:setElement(0, rName:index(), self.offerName)
                    end

                    ---@type ISLabel|nil
                    self.offerDebug = self:xuiBuild(
                        nil,
                        ISLabel,
                        0,
                        0,
                        20,
                        "Dbg: --",
                        0.53,
                        0.53,
                        0.53,
                        1,
                        UIFont.Small,
                        false
                    )
                    local rDbg = infoStack:addRowFill()
                    ---@diagnostic disable-next-line: unnecessary-if
                    if self.offerDebug and rDbg then
                        ---@diagnostic disable-next-line: inject-field
                        self.offerDebug.calculateLayout = function(_slf, _w, _h)
                            _slf:setWidth(_w)
                        end
                        infoStack:setElement(0, rDbg:index(), self.offerDebug)
                    end

                    ---@type ISLabel|nil
                    self.offerStock = self:xuiBuild(
                        nil,
                        ISLabel,
                        0,
                        0,
                        20,
                        "Stock: --",
                        0.53,
                        0.53,
                        0.53,
                        1,
                        UIFont.Small,
                        false
                    )
                    local rStock = infoStack:addRowFill()
                    ---@diagnostic disable-next-line: unnecessary-if
                    if self.offerStock and rStock then
                        ---@diagnostic disable-next-line: inject-field
                        self.offerStock.calculateLayout = function(_slf, _w, _h)
                            _slf:setWidth(_w)
                        end
                        infoStack:setElement(0, rStock:index(), self.offerStock)
                    end

                    offerBox:setElement(1, obRow:index(), infoStack)
                end

                ---@type ISTextEntryBox|nil
                self.offerQtyInput = self:xuiBuild(nil, ISTextEntryBox, "1", 0, 0, 60, INPUT_H)
                ---@diagnostic disable-next-line: unnecessary-if
                if self.offerQtyInput then
                    self.offerQtyInput.onTextChange = function()
                        if self.onQtyChanged and self.target then
                            self.onQtyChanged(self.target)
                        end
                    end
                    offerBox:setElement(2, obRow:index(), self.offerQtyInput)
                end
            end
            self.tableLayout:setElement(0, offerBoxRow:index(), offerBox)
        end
    end

    -- Yield info label
    local yieldRow = self.tableLayout:addRow()
    if yieldRow then
        ---@diagnostic disable-next-line: inject-field
        yieldRow.marginTop = 6
        ---@diagnostic disable-next-line: inject-field
        yieldRow.marginBottom = R_PAD
        ---@type ISLabel|nil
        self.yieldInfo = self:xuiBuild(
            nil,
            ISLabel,
            0,
            0,
            20,
            "Select an item to configure.",
            0.53,
            0.53,
            0.53,
            1,
            UIFont.Small,
            false
        )
        ---@diagnostic disable-next-line: unnecessary-if
        if self.yieldInfo then
            ---@diagnostic disable-next-line: inject-field
            self.yieldInfo.calculateLayout = function(_slf, _w, _h)
                _slf:setWidth(_w)
            end
            self.tableLayout:setElement(0, yieldRow:index(), self.yieldInfo)
        end
    end
end

function ShopTradeOfferPanel:setYieldInfo(text)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.yieldInfo then
        ---@diagnostic disable-next-line: undefined-field
        self.yieldInfo:setName(text)
    end
end

function ShopTradeOfferPanel:setOfferItem(name, dbg, stock, tex)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerName then
        ---@diagnostic disable-next-line: undefined-field
        self.offerName:setName(name)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerDebug then
        ---@diagnostic disable-next-line: undefined-field
        self.offerDebug:setName(dbg)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerStock then
        ---@diagnostic disable-next-line: undefined-field
        self.offerStock:setName("Stock: " .. tostring(stock) .. " units")
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerIcon then
        local iconTex = tex
        if iconTex and type(iconTex) == "string" then
            iconTex = getTexture(iconTex)
        end
        self.offerIcon.texture = iconTex
    end
end

function ShopTradeOfferPanel:setQty(qty)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerQtyInput then
        self.offerQtyInput:setText(tostring(qty or 1))
    end
end

function ShopTradeOfferPanel:getQty()
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerQtyInput then
        local text = self.offerQtyInput:getText()
        local qty = toInt(tonumber(text) or 0)
        if qty and qty > 0 then
            return qty
        end
    end
    return 1
end

function ShopTradeOfferPanel:clearQtyBackground()
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerQtyInput then
        self.offerQtyInput.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    end
end

function ShopTradeOfferPanel:errorQtyBackground()
    ---@diagnostic disable-next-line: unnecessary-if
    if self.offerQtyInput then
        self.offerQtyInput.backgroundColor = { r = 0.5, g = 0, b = 0, a = 1 }
    end
end

function ShopTradeOfferPanel:calculateLayout(width, height)
    self:setWidth(width)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
        self:setHeight(self.tableLayout:getHeight())
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.sectionHeader then
        self.sectionHeader:calculateLayout(width, self.sectionHeader:getHeight())
    end
end

function ShopTradeOfferPanel:new(x, y, w, h, target, onQtyChanged, xuiSkin)
    ---@type ShopTradeOfferPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.onQtyChanged = onQtyChanged
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopTradeOfferPanel
