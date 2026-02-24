require("ISUI/ISPanel")
require("ISUI/ISButton")
require("ISUI/ISScrollingListBox")
require("ISUI/ISImage")
require("Entity/ISUI/Controls/ISTableLayout")

local ShopItemHeader = require("jasm/entity_ui/components/shop_item_header")
local ShopItemGivesPanel = require("jasm/entity_ui/components/shop_item_gives_panel")
local ShopItemRequirementsPanel = require("jasm/entity_ui/components/shop_item_requirements_panel")
local ShopItemActionFooter = require("jasm/entity_ui/components/shop_item_action_footer")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

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
    print("[JASM] ShopItemDetailsPanel:createChildren() called")
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
        end
        self.tableLayout:setElement(0, 0, self.headerPanel)
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
        end
        self.tableLayout:setElement(0, 1, self.givesPanel)
    end

    -- 1c Requirements Container
    ---@type ShopItemRequirementsPanel
    self.requirementsPanel =
        ShopItemRequirementsPanel:new(0, 0, self.width, 0, self, self.onSelectReq, self.xuiSkin)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.requirementsPanel then
        self.requirementsPanel:initialise()
        self.requirementsPanel:instantiate()
        self.tableLayout:addRow()
        self.tableLayout:setElement(0, 2, self.requirementsPanel)
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
    ---@diagnostic disable-next-line: unnecessary-if
    if self.footerPanel then
        self.footerPanel:initialise()
        self.footerPanel:instantiate()
        local rFooter = self.tableLayout:addRow()
        if rFooter then
            rFooter.minimumHeight = 90
        end
        self.tableLayout:setElement(0, 4, self.footerPanel)
    end

    self.dirtyLayout = true
    print("[JASM] ShopItemDetailsPanel:createChildren() finishing layout")
end

--- Callback for the debug Force Give button.
function ShopItemDetailsPanel:onDebugForceGive()
    print("[JASM] ShopItemDetailsPanel:onDebugForceGive() called (debug)")
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
    print("[JASM] ShopItemDetailsPanel:setInventory() called")
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
        self.givesPanel:setItem(product.name, 1, product.icon)
    end

    -- Assuming 'self.inventory' is the map {map={}, list={}}
    local pInvMap = self.inventory and self.inventory.map

    local trades = {}
    ---@diagnostic disable-next-line: undefined-field
    for _, trade in ipairs(product.trades or {}) do
        local hasCount = 0.0
        if pInvMap and pInvMap[trade.requestItem] then
            hasCount = pInvMap[trade.requestItem].count
        end

        trade.hasCount = hasCount
        trade.icon = (pInvMap and pInvMap[trade.requestItem]) and pInvMap[trade.requestItem].icon
            or "InventoryItem_Default"
        table.insert(trades, trade)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    if self.requirementsPanel then
        self.requirementsPanel:setTrades(trades)
    end
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
    print("[JASM] ShopItemDetailsPanel:onAcceptTrade() executing trade")

    local selectedTrade = self.requirementsPanel:getSelectedTrade()
    if not selectedTrade or not self.product then
        return
    end

    ---@cast self.entity IsoObject
    local entity = self.entity
    if not entity then
        print("[JASM] ShopItemDetailsPanel:onAcceptTrade() ERROR: no entity")
        return
    end

    local args = {
        x = entity:getX(),
        y = entity:getY(),
        z = entity:getZ(),
        index = entity:getObjectIndex(),
        action = "BUY_TRADE",
        itemType = self.product.type,
        -- Trade data
        requestItem = selectedTrade.requestItem,
        requestQty = selectedTrade.requestQty,
    }

    print("[JASM] ShopItemDetailsPanel:onAcceptTrade() sending command JASM_ShopManager ManageShop")
    KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
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
    -- Resize tableLayout to fill panel
    if self.tableLayout then
        self.tableLayout:setWidth(width)
        self.tableLayout:setHeight(height)
        self.tableLayout:calculateLayout(width, height)
    end

    -- Resize components
    ---@diagnostic disable-next-line: unnecessary-if
    if self.headerPanel then
        self.headerPanel:calculateLayout(width, 76)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.givesPanel then
        self.givesPanel:calculateLayout(width, 84)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.requirementsPanel then
        self.requirementsPanel:calculateLayout(width, self.requirementsPanel:getHeight())
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.footerPanel then
        self.footerPanel:calculateLayout(width, 90)
    end

    self.dirtyLayout = false
end

--- Create a new instance of ShopItemDetailsPanel.
function ShopItemDetailsPanel:new(x, y, width, height, player, xuiSkin)
    print("[JASM] ShopItemDetailsPanel:new() called")
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
