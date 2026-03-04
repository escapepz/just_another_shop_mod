require("Entity/ISUI/Controls/ISTableLayout")

local ShopSectionHeader =
    require("just_another_shop_mod/entity_ui/components/shop/shared/shop_section_header")
local TextureUtils = require("just_another_shop_mod/entity_ui/utils/texture_utils")

---@class ShopItemRequirementsPanel : ISPanel
---@field headerPanel ShopSectionHeader
---@field tableLayout ISTableLayout
---@field requirementsList ISScrollingListBox|nil
---@field target any
---@field onSelect fun(target: any, item: any)|nil
---@field xuiSkin any
local ShopItemRequirementsPanel = ISPanel:derive("ShopItemRequirementsPanel")

function ShopItemRequirementsPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopItemRequirementsPanel:createChildren()
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
    ---@type ISPanel
    self.headerPanel =
        ShopSectionHeader:new(0, 0, self.width, 40, "YOU NEED (CHOOSE ONE)", self.xuiSkin)
    if self.headerPanel and self.tableLayout then
        self.headerPanel:initialise()
        self.headerPanel:instantiate()
        ---@diagnostic disable-next-line: undefined-field
        if self.headerPanel.tableLayout then
            ---@diagnostic disable-next-line: undefined-field
            local hrRow = self.headerPanel.tableLayout:row(1)
            if hrRow then
                hrRow.marginBottom = 0
            end
        end
        local rHeader = self.tableLayout:addRow()
        if rHeader then
            rHeader.minimumHeight = 40
        end
        self.tableLayout:setElement(0, 0, self.headerPanel)
    end

    local REQ_ITEM_H = 42

    if self.tableLayout then
        local rList = self.tableLayout:addRow()
        if rList then
            ---@type ISScrollingListBox|nil
            local list = self:xuiBuild(nil, ISScrollingListBox, 0, 0, self.width, 10)
            if list then
                self.requirementsList = list
                list.itemheight = REQ_ITEM_H
                list.drawBorder = false
                ---@diagnostic disable-next-line: inject-field
                list.calculateLayout = function(_self_list, _w, _h)
                    _self_list:setWidth(_w)
                    local desiredHeight =
                        math.max(0, math.min(5 * REQ_ITEM_H, #_self_list.items * REQ_ITEM_H))
                    _self_list:setHeight(desiredHeight)
                end
                list.doDrawItem = self.doDrawReqItem
                list:setOnMouseDownFunction(self, self.onSelectReq)
                list.target = self
                self.tableLayout:setElement(0, rList:index(), list)
            end
        end
    end
end

function ShopItemRequirementsPanel.doDrawReqItem(listbox, y, item, _alt)
    local self = listbox
    ---@cast self ISScrollingListBox

    local req = item.item
    local isSelected = self.selected == item.index

    -- Selection / hover background tint
    if isSelected then
        self:drawRect(0, y, self.width, item.height, 0.15, 0.95, 0.61, 0.07)
        self:drawRectBorder(0, y, self.width, item.height, 0.6, 0.95, 0.61, 0.07)
    elseif self.mouseoverselected == item.index then
        self:drawRect(0, y, self.width, item.height, 0.05, 0.10, 0.10, 0.10)
    end

    -- Always get texture from itemFullID (requestItem)
    local texture = TextureUtils.getItemTexture(req.requestItem)
    if texture then
        self:drawTextureScaled(texture, 12, y + 8, 24, 24, 1, 1, 1, 1)
    end

    -- Name Logic: ScriptManager > req.name fallback
    local name = "Unknown Item"
    if req.requestItem then
        local scriptItem = ScriptManager.instance:getItem(req.requestItem)
        name = scriptItem and scriptItem:getDisplayName() or req.name or "Unknown Item"
    else
        name = req.name or "Unknown Item"
    end

    -- Specific fallback for money
    -- if req.requestItem == "Base.Money" then
    --     name = "Money"
    -- end

    self:drawText(name, 46, y + 5, 0.80, 0.80, 0.80, 1, UIFont.Small)

    -- Status
    local hasCount = req.hasCount or 0
    local reqCount = req.requestQty or 1
    local isOk = hasCount >= reqCount
    local statusTxt = tostring(hasCount) .. " / " .. tostring(reqCount)
    local sr, sg, sb = isOk and 0.50 or 1.0, isOk and 0.83 or 0.42, isOk and 0.50 or 0.42
    self:drawText(statusTxt, 46, y + 21, sr, sg, sb, 1, UIFont.Small)

    return y + item.height
end

function ShopItemRequirementsPanel:onSelectReq(item)
    if self.onSelect and self.target then
        self.onSelect(self.target, item)
    end
end

function ShopItemRequirementsPanel:setTrades(trades)
    if not self.requirementsList then
        return
    end
    self.requirementsList:clear()
    for _, trade in ipairs(trades or {}) do
        self.requirementsList:addItem(trade.requestItem, trade)
    end
    if #self.requirementsList.items > 0 then
        self.requirementsList.selected = 1
    end
end

---@return any|nil
function ShopItemRequirementsPanel:getSelectedTrade()
    local list = self.requirementsList
    ---@cast list ISScrollingListBox
    if not list then
        return nil
    end
    local sel = list.selected
    if sel > 0 and sel <= #list.items then
        ---@diagnostic disable-next-line: undefined-field
        return list.items[sel].item
    end
    return nil
end

function ShopItemRequirementsPanel:calculateLayout(width, _height)
    self:setWidth(width)

    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:setWidth(width)
        self.tableLayout:calculateLayout(width, 0)
        self:setHeight(math.max(self.minimumHeight or 0, self.tableLayout:getHeight()))
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.headerPanel then
        self.headerPanel:calculateLayout(width, self.headerPanel:getHeight())
    end
end

function ShopItemRequirementsPanel:new(x, y, w, h, target, onSelect, xuiSkin)
    ---@type ShopItemRequirementsPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.onSelect = onSelect
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopItemRequirementsPanel
