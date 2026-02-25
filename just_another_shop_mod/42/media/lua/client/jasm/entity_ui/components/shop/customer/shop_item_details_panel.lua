require("ISUI/ISPanel")
require("ISUI/ISButton")
require("ISUI/ISScrollingListBox")
require("ISUI/ISImage")
require("Entity/ISUI/Controls/ISTableLayout")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local ShopItemHeader = require("jasm/entity_ui/components/shop/customer/shop_item_header")
local ShopItemGivesPanel = require("jasm/entity_ui/components/shop/customer/shop_item_gives_panel")
local ShopItemRequirementsPanel =
    require("jasm/entity_ui/components/shop/customer/shop_item_requirements_panel")
local ShopItemActionFooter =
    require("jasm/entity_ui/components/shop/customer/shop_item_action_footer")

---@class TradeItem : umbrella.ISScrollingListBox.Item
---@field hasCount number
---@field requestQty number

--- Panel that shows detailed information about a selected product,
--- including its cost and the trade acceptance button.
---@class ShopItemDetailsPanel : ISPanel
---@field player IsoPlayer
---@field xuiSkin any
---@field product CustomerViewInventoryItem
---@field headerPanel ShopItemHeader
---@field givesPanel ShopItemGivesPanel
---@field requirementsPanel ShopItemRequirementsPanel
---@field footerPanel ShopItemActionFooter
---@field inventory any
---@field entity GameEntity
---@field dirtyLayout boolean
---@field xuiPreferredResizeWidth number
---@field xuiPreferredResizeHeight number
---@field minimumWidth number
---@field minimumHeight number
local ShopItemDetailsPanel = ISPanel:derive("ShopItemDetailsPanel")

function ShopItemDetailsPanel:createChildren()
    logger:debug("ShopItemDetailsPanel:createChildren() called")
    ISPanel.createChildren(self)

    -- 1. Main Table Layout
    ---@type ISTableLayout
    self.tableLayout = ISXuiSkin.build(
        self.xuiSkin,
        nil,
        ISTableLayout,
        0,
        0,
        self.width,
        self.height,
        nil,
        nil,
        nil
    )
    ---@diagnostic disable-next-line: unnecessary-if
    if self.tableLayout then
        self.tableLayout:initialise()
        self.tableLayout:instantiate()
        self.tableLayout:addColumnFill() -- One column stack
        self:addChild(self.tableLayout)
    end

    -- 1a Header Area
    ---@type ShopItemHeader
    self.headerPanel = ShopItemHeader:new(0, 0, self.width, 76, self.xuiSkin)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.headerPanel then
        self.headerPanel:initialise()
        self.headerPanel:instantiate()
        local rHeader = self.tableLayout:addRow()
        if rHeader then
            rHeader.minimumHeight = 76
            self.tableLayout:setElement(0, rHeader:index(), self.headerPanel)
        end
    end

    -- 1b "Shop Gives" Container
    ---@type ShopItemGivesPanel
    self.givesPanel = ShopItemGivesPanel:new(0, 0, self.width, 84, self.xuiSkin)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.givesPanel then
        self.givesPanel:initialise()
        self.givesPanel:instantiate()
        local rGives = self.tableLayout:addRow()
        if rGives then
            rGives.minimumHeight = 84
            self.tableLayout:setElement(0, rGives:index(), self.givesPanel)
        end
    end

    -- 1c Requirements Container
    ---@type ShopItemRequirementsPanel
    self.requirementsPanel =
        ShopItemRequirementsPanel:new(0, 0, self.width, 0, self, self.onSelectReq, self.xuiSkin)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.requirementsPanel then
        self.requirementsPanel:initialise()
        self.requirementsPanel:instantiate()
        local rReq = self.tableLayout:addRow()
        if rReq then
            self.tableLayout:setElement(0, rReq:index(), self.requirementsPanel)
        end
    end

    -- Spacer row to push footer to bottom
    self.tableLayout:addRowFill()

    -- 1d Action Footer
    ---@type ShopItemActionFooter
    self.footerPanel = ShopItemActionFooter:new(
        0,
        0,
        self.width,
        90,
        self,
        self.onAcceptTrade,
        self.onDebugForceGive,
        self.xuiSkin
    )
    self.footerPanel:initialise()
    self.footerPanel:instantiate()
    local rFooter = self.tableLayout:addRow()
    if rFooter then
        rFooter.minimumHeight = 90
        self.tableLayout:setElement(0, rFooter:index(), self.footerPanel)
    end

    self.dirtyLayout = true
    logger:debug("ShopItemDetailsPanel:createChildren() finishing layout")
end

--- Callback for the debug Force Give button.
function ShopItemDetailsPanel:onDebugForceGive()
    logger:debug("ShopItemDetailsPanel:onDebugForceGive() called (debug)")
    local selectedTrade = self.requirementsPanel:getSelectedTrade()
    if not selectedTrade or not self.product then
        return
    end

    ---@cast self.entity IsoObject
    local entity = self.entity
    if not entity then
        logger:error("ShopItemDetailsPanel:onDebugForceGive() ERROR: no entity")
        return
    end

    -- Force give still requires an item type check to know *what* to give
    local sq = entity:getSquare()
    if not sq then
        return
    end

    if luautils.walkAdj(self.player, sq, true) then
        ISTimedActionQueue.add(JASM_AcceptTradeAction:new(self.player, entity, {
            itemType = self.product.type,
            offerQty = self.product.offerQty or 1,
            requestItem = selectedTrade.requestItem,
            requestQty = selectedTrade.requestQty,
            isForceGive = true,
        }))
    end
end

--- Callback when a requirement (trade option) is selected.
---@param item any The selected requirement item.
function ShopItemDetailsPanel:onSelectReq(item)
    -- print("[JASM] ShopItemDetailsPanel:onSelectReq() called")
    self:updateTradeButton()
end

--- Set the current player inventory for requirement checking.
---@param inventory CustomerViewInventory The player's inventory structure.
function ShopItemDetailsPanel:setInventory(inventory)
    logger:debug("ShopItemDetailsPanel:setInventory() called")
    self.inventory = inventory
end

--- Update the panel to show details for a specific product.
---@param product CustomerViewInventoryItem|nil The product to display.
function ShopItemDetailsPanel:setProduct(product)
    -- print("[JASM] ShopItemDetailsPanel:setProduct() product: " .. (product and tostring(product.name) or "nil"))
    self.product = product

    if not product then
        ---@diagnostic disable-next-line: unnecessary-if
        if self.headerPanel then
            self.headerPanel:setItem(nil, nil, nil, nil)
        end
        ---@diagnostic disable-next-line: unnecessary-if
        if self.givesPanel then
            self.givesPanel:setItem(nil, 1, nil)
        end
        ---@diagnostic disable-next-line: unnecessary-if
        if self.requirementsPanel then
            self.requirementsPanel:setTrades(nil)
        end
        ---@diagnostic disable-next-line: unnecessary-if
        if self.footerPanel then
            self.footerPanel:setError("")
        end
        ---@diagnostic disable-next-line: unnecessary-if
        if self.footerPanel then
            self.footerPanel:setTradeEnabled(false)
        end
        return
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.headerPanel then
        self.headerPanel:setItem(product.name, product.type, product.stock, product.icon)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.givesPanel then
        -- Read offerQty from the IsoObject modData (single source of trust)
        ---@diagnostic disable-next-line: undefined-field
        local shopTrades = self.entity and self.entity:getModData().shopTrades
        local tradeData = shopTrades and shopTrades[product.type]
        local offerQty = math.floor(tonumber(tradeData and tradeData.offerQty) or 1)
        product.offerQty = offerQty -- Save it for the action payload
        self.givesPanel:setItem(product.name, offerQty, product.icon)
    end

    -- Read trade paths from the IsoObject modData (single source of trust)
    ---@diagnostic disable-next-line: undefined-field
    local shopTrades = self.entity and self.entity:getModData().shopTrades
    local tradeData = shopTrades and shopTrades[product.type]

    -- Schema: { offerQty = number, paths = { {requestItem, requestQty, name}, ... } }
    local rawPaths = tradeData and tradeData.paths or {}
    local pInvMap = self.inventory and self.inventory.map

    local trades = {}
    for _, t in ipairs(rawPaths) do
        -- Strictly follow the canonical schema and ensure integer quantities
        local trade = {
            requestItem = t.requestItem,
            requestQty = math.floor(tonumber(t.requestQty) or 1),
            name = t.name or "",
            icon = t.icon,
        }

        local hasCount = 0.0
        if pInvMap and pInvMap[trade.requestItem] then
            hasCount = pInvMap[trade.requestItem].count
        end

        trade.hasCount = hasCount
        -- Resolve icon from player inventory map if not already set in modData
        if not trade.icon then
            trade.icon = (pInvMap and pInvMap[trade.requestItem])
                    and pInvMap[trade.requestItem].icon
                or nil
        end
        table.insert(trades, trade)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.requirementsPanel then
        self.requirementsPanel:setTrades(trades)
    end
    -- Trigger layout update immediately so children are properly tiered in this frame
    self:calculateLayout(self.width, self.height)
    self:updateTradeButton()
end

--- Update the state of the "Accept Trade" button based on requirements.
function ShopItemDetailsPanel:updateTradeButton()
    local selectedTrade = self.requirementsPanel:getSelectedTrade()
    local canTrade = false
    local errorTxt = ""

    if selectedTrade then
        if selectedTrade.hasCount >= selectedTrade.requestQty then
            canTrade = true
        else
            errorTxt = "You do not have all required items"
        end
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.footerPanel then
        self.footerPanel:setTradeEnabled(canTrade)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.footerPanel then
        self.footerPanel:setError(errorTxt)
    end
end

--- Callback when the trade button is clicked.
function ShopItemDetailsPanel:onAcceptTrade()
    logger:info("ShopItemDetailsPanel:onAcceptTrade() executing trade")

    local selectedTrade = self.requirementsPanel:getSelectedTrade()
    if not selectedTrade or not self.product then
        return
    end

    ---@cast self.entity IsoObject
    local entity = self.entity
    if not entity then
        logger:error("ShopItemDetailsPanel:onAcceptTrade() ERROR: no entity")
        return
    end

    -- Walk to and queue action
    local sq = entity:getSquare()
    if not sq then
        logger:error("ShopItemDetailsPanel:onAcceptTrade() ERROR: no square")
        return
    end

    if luautils.walkAdj(self.player, sq, true) then
        ISTimedActionQueue.add(JASM_AcceptTradeAction:new(self.player, entity, {
            itemType = self.product.type,
            offerQty = self.product.offerQty or 1,
            requestItem = selectedTrade.requestItem,
            requestQty = selectedTrade.requestQty,
            isForceGive = false,
        }))
    end
end

function ShopItemDetailsPanel:prerender()
    if self.dirtyLayout or self.width ~= self.lastWidth or self.height ~= self.lastHeight then
        self.lastWidth = self.width
        self.lastHeight = self.height
        self:calculateLayout(self.width, self.height)
    end
    ISPanel.prerender(self)
end

function ShopItemDetailsPanel:onResize()
    ISPanel.onResize(self)
    self:calculateLayout(self.width, self.height)
end

function ShopItemDetailsPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth or 0)
    local height = math.max(_preferredHeight or 0, self.minimumHeight or 0)

    self:setWidth(width)
    self:setHeight(height)

    ---@diagnostic disable-next-line: unnecessary-if
    -- 1. First, tell the Requirements panel to determine its own height based on current list items
    -- This ensures its :getHeight() is stable before the parent table uses it to allocate row space.
    if self.requirementsPanel then
        self.requirementsPanel:calculateLayout(width, 0)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- 2. Resize tableLayout to fill panel and re-flow rows based on new heights
    if self.tableLayout then
        self.tableLayout:setWidth(width)
        self.tableLayout:setHeight(height)
        self.tableLayout:calculateLayout(width, height)
    end

    self.dirtyLayout = false
end

--- Create a new instance of ShopItemDetailsPanel.
function ShopItemDetailsPanel:new(x, y, width, height, player, xuiSkin)
    logger:debug("ShopItemDetailsPanel:new() called")
    ---@type ShopItemDetailsPanel
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.xuiSkin = xuiSkin
    o.dirtyLayout = true
    o.xuiPreferredResizeWidth = width
    o.xuiPreferredResizeHeight = height
    o.minimumWidth = 0
    o.minimumHeight = 0
    -- Right panel background: #0f0f0f
    o.background = true
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    return o
end

return ShopItemDetailsPanel
