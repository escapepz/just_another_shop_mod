require("Entity/ISUI/Windows/ISEntityWindow")
require("Entity/ISUI/Controls/ISTableLayout")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")
require("TimedActions/ISBaseTimedAction")
require("TimedActions/ISTimedActionQueue")

local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")

local ShopDataManager = require("just_another_shop_mod/entity_ui/models/shop_data_manager")
local SearchFilterPanel =
    require("just_another_shop_mod/entity_ui/components/shop/shared/shop_search_filter_panel")
local ProductListPanel =
    require("just_another_shop_mod/entity_ui/components/product/product_list_panel")
local ShopTradeOfferPanel =
    require("just_another_shop_mod/entity_ui/components/shop/owner/shop_trade_offer_panel")
local ShopRequirementPanel =
    require("just_another_shop_mod/entity_ui/components/shop/owner/shop_requirement_panel")
local ShopFooterPanel =
    require("just_another_shop_mod/entity_ui/components/shop/owner/shop_footer_panel")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local KUtilities = require("pz_utils_shared").konijima.Utilities

-- ============================================================
-- COLOR PALETTE (matches design5.html / customer_view_window)
-- ============================================================
-- #0f0f0f  -> { r=0.06, g=0.06, b=0.06 }  Main bg / right panel
-- #1a1a1a  -> { r=0.10, g=0.10, b=0.10 }  Left panel / row bg
-- #2a2416  -> { r=0.16, g=0.14, b=0.09 }  Selected item bg
-- #f39c12  -> { r=0.95, g=0.61, b=0.07 }  Orange accent
-- #333     -> { r=0.20, g=0.20, b=0.20 }  Border / divider
-- #ff4444  -> { r=1.00, g=0.27, b=0.27 }  Error text
-- #ccc     -> { r=0.80, g=0.80, b=0.80 }  Secondary text
-- #888     -> { r=0.53, g=0.53, b=0.53 }  Muted text

-- ============================================================
-- CONSTANTS
-- ============================================================
local LEFT_PANEL_WIDTH = 280 -- px (design5: aside width: 280px)
local MAX_PATHS = 5 -- design5_rule §3: max 5 confirmed paths

-- ============================================================
-- TYPE ANNOTATIONS
-- ============================================================

---@class OwnerRequirementPath
---@field itemType    string   Full type (e.g. "Base.GoldBar")
---@field requestQty    integer
---@field name   string

---@class OwnerViewWindow : ISEntityWindow
---@field player            IsoPlayer
---@field titleBar          boolean
---@field xuiSkin           XuiSkin
---@field masterLayout      ISTableLayout
---@field leftStackLayout   ISTableLayout
---@field mainContentLayout ISTableLayout
---@field dataManager       ShopDataManager
---@field inventory         CustomerViewInventory
---@field selectedItem      CustomerViewInventoryItem|nil
---@field hasUnsavedChanges boolean
---@field requirementPaths  OwnerRequirementPath[]
---@field offerQty          integer
-- left panel components
---@field searchPanel    ShopSearchFilterPanel|nil
---@field productPanel   ProductListPanel|nil
---@field pathsTableLayout ISTableLayout
---@field pathItems      ShopCustomerOptionItem[]
-- right panel widgets
---@field rightPanel    ISPanel
---@field offerIcon     ISLabel
---@field offerName     ISLabel
---@field offerDebug    ISLabel
---@field offerStock    ISLabel
---@field offerQtyInput ISTextEntryBox
---@field yieldInfo     ISLabel
---@field pathsScrollList ISScrollingListBox
---@field newPathQtyInput  ISTextEntryBox
---@field newPathTypeInput  ISTextEntryBox
---@field addPathBtn       ISButton
---@field errorLabel       ISLabel
---@field currentPublishAction JASM_PublishTradeAction|nil
---@field isPublishing      boolean
local OwnerViewWindow = ISEntityWindow:derive("OwnerViewWindow")
OwnerViewWindow.instance = nil
OwnerViewWindow.coords = nil

-- ============================================================
-- REUSED HELPER: xuiBuild (identical pattern to CustomerViewWindow)
-- ============================================================

--- Helper to build, initialise and instantiate a component in one go.
function OwnerViewWindow:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        if o.initialise then
            o:initialise()
        end

        if o.instantiate then
            o:instantiate()
        end
    end
    return o
end

-- ============================================================
-- ENTITY HEADER OVERRIDE (reused from customer_view_window)
-- ============================================================

function OwnerViewWindow:so_override_the_entity_header()
    if not self.entityHeader then
        return
    end

    ---@diagnostic disable-next-line: inject-field
    self.entityHeader.consumeMouseEvents = false
    self.entityHeader.background = true
    self.entityHeader.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    self.entityHeader.borderColor = { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }

    ---@cast self.entity IsoObject
    if self.entityHeader.icon then
        local texName = self.entity:getTextureName()
        local size = 48
        ---@diagnostic disable-next-line: inject-field
        self.entityHeader.iconSize = size
        self.entityHeader.icon.background = true
        ---@diagnostic disable-next-line: undefined-field
        self.entityHeader.icon.texture = getTexture(texName)
        self.entityHeader.icon:setWidth(size)
        self.entityHeader.icon:setHeight(size)
        ---@diagnostic disable-next-line: inject-field
        self.entityHeader.icon.autoScale = true
        self.entityHeader.icon:setY(-4)
    end

    if self.entityHeader.title then
        self.entityHeader.title:setName("SHOP OWNER CONFIG")
        self.entityHeader.title.textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
    end

    self.entityHeader:calculateLayout(self.width, 0)
end

-- ============================================================
-- WINDOW LIFECYCLE (reused pattern from customer_view_window)
-- ============================================================

function OwnerViewWindow:initialise()
    logger:debug("OwnerViewWindow:initialise() called")
    ISEntityWindow.initialise(self)
end

function OwnerViewWindow:removeDebugPanel()
    if self.entityDebug then
        self:removeChild(self.entityDebug)
        self.entityDebug = nil
    end
end

function OwnerViewWindow:createChildren()
    logger:debug("OwnerViewWindow:createChildren() called")
    ISEntityWindow.createChildren(self)

    self:removeDebugPanel()
    self:so_override_the_entity_header()

    if self.componentsPanel then
        self.componentsPanel:setVisible(false)
    end

    -- Hook resize
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.resizeWidget.resizeFunction = self.calculateLayout
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.resizeWidget2.resizeFunction = self.calculateLayout

    -- Build UI
    self:initLayout()
    self:populateInitialData()

    if self.masterLayout then
        self.masterLayout:backMost()
    end

    -- Keep window chrome on top

    if self.collapseButton then
        self.collapseButton:bringToTop()
    end

    if self.pinButton then
        self.pinButton:bringToTop()
    end

    if self.closeButton then
        self.closeButton:bringToTop()
    end

    self.xuiPreferredResizeWidth = self.width
    self.xuiPreferredResizeHeight = self.height
    self:calculateLayout(self.width, self.height)
end

-- ============================================================
-- LAYOUT CALCULATION (reused pattern from customer_view_window)
-- ============================================================

function OwnerViewWindow:xuiRecalculateLayout(
    _preferredWidth,
    _preferredHeight,
    _force,
    _anchorRight
)
    if self.calculateLayout and ((not self.dirtyLayout) or _force) then
        self.xuiPreferredResizeWidth = self.width
        self.xuiPreferredResizeHeight = self.height
        self.xuiResizeAnchorRight = _anchorRight
        if _preferredWidth then
            self.xuiPreferredResizeWidth = _preferredWidth < 0 and self.width + _preferredWidth
                or _preferredWidth
        end
        if _preferredHeight then
            self.xuiPreferredResizeHeight = _preferredHeight < 0 and self.height + _preferredHeight
                or _preferredHeight
        end
        self.dirtyLayout = true
    end
end

function OwnerViewWindow:calculateLayout(_preferredWidth, _preferredHeight)
    local th = self:titleBarHeight()
    local rh = self.resizable and self:resizeWidgetHeight() or 0

    local width = math.max(_preferredWidth or self.width, self.minimumWidth)
    local height = math.max(_preferredHeight or self.height, self.minimumHeight)

    -- Entity header
    local y = th

    if self.entityHeader then
        self.entityHeader:setX(0)
        self.entityHeader:setY(y)
        self.entityHeader:calculateLayout(width, 0)
        y = y + self.entityHeader:getHeight()
    end

    -- Master layout fills everything below the entity header
    self.masterLayout:setX(0)
    self.masterLayout:setY(y)
    self.masterLayout:setWidth(width)
    self.masterLayout:setHeight(height - y - rh)
    self.masterLayout:calculateLayout(width, height - y - rh)

    -- Calculate layouts handled entirely by masterLayout now

    self.pinButton:setX(width - 3 - self.pinButton:getWidth())
    self.collapseButton:setX(width - 3 - self.collapseButton:getWidth())

    if self.width ~= width then
        self:setWidth(width)
    end
    if self.height ~= height then
        self:setHeight(height)
    end
    self.dirtyLayout = false
end

function OwnerViewWindow:prerender()
    if self.dirtyLayout then
        local oldX = self:getX()
        local oldWidth = self:getWidth()

        if self.calculateLayout then
            self:calculateLayout(self.xuiPreferredResizeWidth, self.xuiPreferredResizeHeight)
        end
        self.dirtyLayout = false

        if self.xuiResizeAnchorRight then
            self:setX(oldX - (self:getWidth() - oldWidth))
            self.xuiResizeAnchorRight = false
        end
    end

    ISEntityWindow.prerender(self)

    -- Issue 14: Refresh shop inventory when container changes (Owner View)
    ---@cast self.entity IsoObject
    local _container = self.entity and self.entity:getContainer()
    if _container then
        local _currentSize = _container:getItems():size()
        local _isDirty = _container:isDirty() or _container:isDrawDirty()
        if _currentSize ~= self._lastContainerSize or _isDirty then
            self:refresh()
        end
    end
end

--- Rescans the container and refreshes all UI components with fresh data.
function OwnerViewWindow:refresh()
    ---@cast self.entity IsoObject
    local _container = self.entity and self.entity:getContainer()
    if not _container then
        return
    end

    logger:debug("OwnerViewWindow:refresh() - rescanning container")

    -- 1. Scan Container
    self.dataManager:scanContainer(_container)
    self.inventory = self.dataManager.inventory
    self._lastContainerSize = _container:getItems():size()

    -- 2. Preserve UI State: Re-apply Search and Sort (Issue 14 Regression Fix)
    if self.searchPanel then
        local searchText = self.searchPanel.searchBox:getInternalText() or ""
        local sortMode = "Alphabetical (A-Z)"
        if self.searchPanel.sortCombo then
            sortMode = self.searchPanel.sortCombo:getOptionText(self.searchPanel.sortCombo.selected)
                or sortMode
        end

        logger:debug("OwnerViewWindow:refresh() - restoring filters", {
            searchText = searchText,
            sortMode = sortMode,
        })

        -- Re-run search/sort flow on the fresh data
        self.dataManager:search(searchText)
        self.dataManager:sort(sortMode)
        -- self.inventory list is now filtered and sorted correctly
    end

    -- 3. Clear dirty flags to match Loot Panel (prevents frame loop flickering)
    _container:setDrawDirty(false)
    _container:setDirty(false)

    -- 4. Update Panels
    self:refreshInventoryList(self.inventory)

    -- Update selected item stock count display ONLY (Issue 14)
    -- Early exit if no item is selected or the item isn't in the fresh inventory
    local _freshItem = self.selectedItem and self.inventory.map[self.selectedItem.type]
    if not _freshItem then
        return
    end

    self.selectedItem = _freshItem

    -- Update the right-side header with new stock number
    if self.updateOfferPreview then
        self:updateOfferPreview(_freshItem)
    end

    -- Sync highlight in product panel without triggering a selection callback
    if self.productPanel then
        self.productPanel:setSelectedProduct(_freshItem)
    end
end

-- ============================================================
-- LAYOUT INIT
-- ============================================================

function OwnerViewWindow:initLayout()
    local th = self:titleBarHeight()

    -- MASTER LAYOUT: vertical columns (left stack | right panel)
    ---@type ISTableLayout
    self.masterLayout = self:xuiBuild(nil, ISTableLayout, 0, th, self.width, self.height - th)
    self.masterLayout.background = false
    ---@diagnostic disable-next-line: inject-field
    self.masterLayout.consumeMouseEvents = false
    self:addChild(self.masterLayout)

    -- Two columns: fixed left (280px) + fill right
    local colL = self.masterLayout:addColumn()
    colL.minimumWidth = LEFT_PANEL_WIDTH
    ---@diagnostic disable-next-line: inject-field
    colL.maximumWidth = LEFT_PANEL_WIDTH
    self.masterLayout:addColumnFill()
    self.masterLayout:addRowFill()

    -- LEFT STACK LAYOUT: vertical (search row + list fill)
    ---@type ISTableLayout
    self.leftStackLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
    self.leftStackLayout:addColumnFill()
    local rowS = self.leftStackLayout:addRow()
    if rowS then
        rowS.minimumHeight = 90 -- tighter slim filter bar height
        ---@diagnostic disable-next-line: inject-field
        rowS.maximumHeight = 90
    end
    self.leftStackLayout:addRowFill()
    self.masterLayout:setElement(0, 0, self.leftStackLayout)

    -- Build the two left-panel sub-components
    self:initLeftPanels()

    -- RIGHT PANEL
    self:initRightPanel()
    self.masterLayout:setElement(1, 0, self.rightPanel)

    self:calculateLayout(self.width, self.height)
end

-- ============================================================
-- LEFT PANEL - ShopSearchFilterPanel (slim) + ProductListView
-- ============================================================

--- Build the search filter and product list panels into leftStackLayout.
function OwnerViewWindow:initLeftPanels()
    -- Search filter (slim: search box + sort combo only)
    ---@type ShopSearchFilterPanel
    self.searchPanel = self:xuiBuild(
        nil,
        SearchFilterPanel,
        0,
        0,
        10,
        90,
        self,
        self.xuiSkin,
        true -- slim=true
    )
    self.searchPanel.onSearch = self.onInventorySearch
    self.searchPanel.onSort = self.onInventorySort
    -- Removed onViewToggle: owner view is strictly list-only
    self.leftStackLayout:setElement(0, 0, self.searchPanel)

    ---@cast self.entity IsoObject
    -- List view (fills remaining height)
    self.productPanel = self:xuiBuild(
        nil,
        ProductListPanel,
        0,
        0,
        10,
        10,
        self.player,
        self.xuiSkin,
        self.entity and self.entity:getContainer()
    )

    if self.productPanel then
        self.productPanel.target = self
        ---@diagnostic disable-next-line: inject-field
        self.productPanel.onSelectProduct = self.onSelectInventoryItem
        self.leftStackLayout:setElement(0, 1, self.productPanel)

        -- Force List Mode (no grid in owner config)
        local panel = self.productPanel
        ---@cast panel ProductListPanel
        panel:setViewMode("list")
    end
end

-- ============================================================
-- RIGHT PANEL - Configuration
-- ============================================================

local R_PAD = 16 -- inner padding for right panel

function OwnerViewWindow:initRightPanel()
    local rw = self.width - LEFT_PANEL_WIDTH
    local rh = self.height

    ---@type ISTableLayout|nil
    self.rightPanel = self:xuiBuild(nil, ISTableLayout, 0, 0, rw, rh)
    if not self.rightPanel then
        return
    end

    self.rightPanel.background = true
    -- #0f0f0f - right panel background
    self.rightPanel.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }

    -- One column that fills the right panel width
    self.rightPanel:addColumnFill()

    -- (Removed "Configure Trade Pair" section header as per request)

    -- ── OFFER SECTION ───────────────────────────────────────────────
    local offerSecRow = self.rightPanel:addRow()
    if offerSecRow then
        ---@type ShopTradeOfferPanel|nil
        self.offerPanel = ShopTradeOfferPanel:new(
            0,
            0,
            rw - R_PAD * 2,
            120,
            self,
            self.onOfferQtyChanged,
            self.xuiSkin
        )
        if self.offerPanel then
            self.offerPanel:initialise()
            self.offerPanel:instantiate()
            self.rightPanel:setElement(0, offerSecRow:index(), self.offerPanel)
        end
    end

    -- ── REQUIREMENT PATHS SECTION ───────────────────────────────────
    local pathsRow = self.rightPanel:addRow()
    if pathsRow then
        ---@diagnostic disable-next-line: inject-field
        pathsRow.marginTop = 10
        local callbacks = {
            onUnsavedChanges = function()
                self.hasUnsavedChanges = true
            end,
            onError = function(_, msg)
                self:showError(msg)
            end,
            onClearError = function()
                self:clearError()
            end,
        }
        self.requirementPanel = ShopRequirementPanel:new(
            0,
            0,
            rw - R_PAD * 2,
            300,
            self.requirementPaths,
            MAX_PATHS,
            self.inventory,
            self,
            callbacks,
            self.xuiSkin
        )
        self.requirementPanel:initialise()
        self.requirementPanel:instantiate()
        self.rightPanel:setElement(0, pathsRow:index(), self.requirementPanel)
    end

    -- ── FOOTER ──────────────────────────────────────────────────────
    self.rightPanel:addRowFill() -- Flex row to push footer to bottom

    local footerRow = self.rightPanel:addRow()
    if footerRow then
        footerRow.minimumHeight = 64
        ---@diagnostic disable-next-line: inject-field
        footerRow.marginTop = 10
        self.footerPanel =
            ShopFooterPanel:new(0, 0, rw - R_PAD * 2, 60, self, self.onPublishClicked, self.xuiSkin)

        if self.footerPanel then
            self.footerPanel:initialise()
            self.footerPanel:instantiate()
            self.rightPanel:setElement(0, footerRow:index(), self.footerPanel)
        end
    end
end

-- ============================================================
-- INVENTORY LIST RENDERING (custom draw via ISScrollingListBox)
-- ============================================================

--- Populate the product panel with the current inventory.
---@param inv CustomerViewInventory
function OwnerViewWindow:refreshInventoryList(inv)
    if self.productPanel then
        self.productPanel:setProducts(inv)
    end
end

-- ============================================================
-- DATA POPULATION
-- ============================================================

function OwnerViewWindow:populateInitialData()
    self.requirementPaths = {}
    self.hasUnsavedChanges = false
    self.offerQty = 1
    self.selectedItem = nil

    -- Load inventory
    self:refreshInventoryList(self.inventory)

    -- If inventory has items, select the first automatically
    if self.inventory and #self.inventory.list > 0 then
        self:onSelectInventoryItem(self.inventory.list[1])
    else
        self:updateOfferPreview(nil)
    end
end

-- ============================================================
-- CALLBACKS
-- ============================================================

--- Inventory search callback. Passed as `onSearch` to the SearchFilterPanel.
---@param text string
function OwnerViewWindow:onInventorySearch(text)
    logger:debug("OwnerViewWindow:onInventorySearch() query: " .. tostring(text))
    local filtered = self.dataManager:search(text)
    self:refreshInventoryList(filtered)
end

--- Inventory sort callback. Passed as `onSort` to the SearchFilterPanel.
---@param mode string
function OwnerViewWindow:onInventorySort(mode)
    logger:debug("OwnerViewWindow:onInventorySort() mode: " .. tostring(mode))
    local sorted = self.dataManager:sort(mode)
    self:refreshInventoryList(sorted)
end

--- Select an inventory item as the current trade "offer".
---@param entry CustomerViewInventoryItem
function OwnerViewWindow:onSelectInventoryItem(entry)
    logger:debug("OwnerViewWindow:onSelectInventoryItem() item: " .. tostring(entry and entry.name))
    self.selectedItem = entry
    -- Clear paths from previous selection
    self.requirementPaths = {}

    local tradesToLoad = self:getTradeData(entry)

    -- Load saved per-item paths if the entry has trades stored
    if
        entry
        and tradesToLoad
        and type(tradesToLoad) == "table"
        and type(tradesToLoad.paths) == "table"
    then
        local loadedPaths = tradesToLoad.paths or tradesToLoad -- fallback for legacy/flat
        -- if type(loadedPaths) == "table" then
        for _, t in ipairs(loadedPaths) do
            local path = {
                itemType = t.requestItem or "",
                requestQty = math.floor(tonumber(t.requestQty) or 1),
                name = t.name or t.requestItem or "",
                icon = nil,
            }
            -- Try to look up icon from inventory map
            local mapped = self.inventory
                and self.inventory.map
                and self.inventory.map[path.itemType]

            if mapped then
                path.icon = mapped.icon
            end
            table.insert(self.requirementPaths, path)
        end
        -- end
    end

    ---@cast self.entity IsoObject
    local clientModData = self.entity:getModData()
    self.hasUnsavedChanges = (
        clientModData.pendingTrade ~= nil and clientModData.pendingTrade.itemType == entry.type
    )

    self:updateOfferPreview(entry)

    if self.requirementPanel then
        ---@diagnostic disable-next-line: undefined-field
        self.requirementPanel:setRequirementPaths(self.requirementPaths)
    end
    -- Sync selection highlight in the product panel
    if self.productPanel then
        self.productPanel:setSelectedProduct(entry)
    end
end

--- Internal helper to handle draft/pending recovery logic.
---@param entry CustomerViewInventoryItem|nil
---@return ShopItemTradeData|nil
function OwnerViewWindow:getTradeData(entry)
    if not entry then
        return nil
    end

    ---@cast self.entity IsoObject
    local clientModData = self.entity:getModData()
    if clientModData.pendingTrade and clientModData.pendingTrade.itemType == entry.type then
        ---@cast clientModData.pendingTrade ShopItemTradeData
        return clientModData.pendingTrade
    end

    ---@cast entry.trades ShopItemTradeData
    return entry.trades
end

--- Update the offer preview box (right panel header area).
---@param entry CustomerViewInventoryItem|nil
function OwnerViewWindow:updateOfferPreview(entry)
    if self.offerPanel then
        local name = entry and (entry.name or "?") or "Select an item"
        local typeStr = "Type: " .. (entry and (entry.type or "--") or "--")
        local stock = entry and (entry.stock or 0) or 0
        local tex = entry and entry.icon or nil

        -- Pre-fill configured offerQty from the saved payload, or default to 1
        local configuredOfferQty = 1
        local trades = self:getTradeData(entry)
        if trades then
            configuredOfferQty = trades.offerQty or 1
        end

        self.offerPanel:setQty(configuredOfferQty)

        -- Check if it's a proxy string not supported by emojis
        -- if tex and type(tex) == "string" and not getTexture(tex) then
        --     tex = nil -- will default to ?
        -- end

        self.offerPanel:setOfferItem(name, typeStr, stock, tex)
    end

    -- Yield info
    self:updateYieldInfo()
end

--- Recalculate and display yield info.
function OwnerViewWindow:updateYieldInfo()
    if not self.offerPanel then
        return
    end

    if not self.selectedItem then
        self.offerPanel:setYieldInfo("Select an item to configure.")
        return
    end

    local qty = self.offerPanel:getQty()
    if qty < 1 then
        qty = 1
    end

    local stock = self.selectedItem.stock or 0
    local totalTrades = math.floor(stock / qty)
    self.offerPanel:setYieldInfo(
        string.format("This will create %d total trades based on your current stock.", totalTrades)
    )
end

--- Called when the offer quantity input changes.
function OwnerViewWindow:onOfferQtyChanged()
    local qty = self.offerPanel and self.offerPanel:getQty() or 1
    self.offerQty = math.max(1, qty)
    self.hasUnsavedChanges = true
    self:updateYieldInfo()
end

--- Called when "Add" button is clicked to add a requirement path.

--- Published trade: validate -> save to CLIENT modData -> queue TimedAction.
--- The server completes the authoritative modData write via JASM_PublishTradeAction:complete().
function OwnerViewWindow:onPublishClicked()
    logger:debug("OwnerViewWindow:onPublishClicked() called")
    if not self.selectedItem then
        self:showError("Error: Select an item to configure first")
        return
    end

    -- ── ANTI-SPAM: Prevent multiple actions ──
    if self.isPublishing then
        return
    end
    -- ──────────────────────────────────────────

    -- Validation: at least one confirmed path
    local confirmedCount = 0
    for _, _ in ipairs(self.requirementPaths) do
        confirmedCount = confirmedCount + 1
    end
    if confirmedCount == 0 then
        logger:error("OwnerViewWindow:onPublishClicked() ERROR: confirmedCount == 0")
        self:showError("Error: Every trade must have at least one requirement path")
        return
    end

    -- Validation: stock >= qty
    local qty = self.offerPanel and self.offerPanel:getQty() or 1
    local stock = self.selectedItem.stock or 0
    if stock < qty then
        logger:error(
            "OwnerViewWindow:onPublishClicked() ERROR: stock < qty ("
                .. tostring(stock)
                .. " < "
                .. tostring(qty)
                .. ")"
        )
        self:showError("Error: Stock is insufficient for even one trade")
        return
    end

    -- Build the trades table from confirmed requirement paths
    local tradesPayload = {}
    for _, p in ipairs(self.requirementPaths) do
        table.insert(tradesPayload, {
            requestItem = p.itemType,
            requestQty = math.floor(p.requestQty or 1),
            name = p.name,
        })
    end
    self.selectedItem.trades = tradesPayload
    self.selectedItem.offerQty = math.floor(qty)

    -- ── CLIENT-SIDE ONLY: store pending trade in local entity modData ──────
    -- This does NOT call transmitModData() – the server owns the authoritative write.
    ---@cast self.entity IsoObject
    local clientModData = self.entity:getModData()
    clientModData.pendingTrade = {
        itemType = self.selectedItem.type,
        offerQty = math.floor(qty),
        paths = tradesPayload,
    }
    -- ────────────────────────────────────────────────────────────────────────

    self:clearError()
    self.hasUnsavedChanges = false

    -- ── Queue the TimedAction (progress bar + server-authoritative write) ───
    -- ── VALIDATE PAYLOAD ON ACTION CREATE ──
    local payload = {
        x = self.entity:getX(),
        y = self.entity:getY(),
        z = self.entity:getZ(),
        index = self.entity:getObjectIndex(),
        itemType = self.selectedItem.type,
        trades = tradesPayload,
        offerQty = qty,
    }

    if not payload.itemType or not payload.trades or #payload.trades == 0 then
        logger:error(
            "OwnerViewWindow:onPublishClicked() - Invalid payload for JASM_PublishTradeAction"
        )
        self:showError("Error: Internal error - invalid trade data")
        return
    end

    -- Serialize trades into a blob string for reliable networking
    -- Format: "Item|Qty|Name;Item|Qty|Name"
    local blobParts = {}
    for _, t in ipairs(payload.trades) do
        table.insert(
            blobParts,
            string.format("%s|%d|%s", t.requestItem, t.requestQty, t.name or "")
        )
    end
    local tradesBlob = table.concat(blobParts, ";")
    -- ──────────────────────────────────────────

    local action = JASM_PublishTradeAction:new(
        self.player,
        self.entity,
        payload.x,
        payload.y,
        payload.z,
        payload.index,
        payload.itemType,
        payload.offerQty,
        tradesBlob
    )

    -- Track publish state
    self.isPublishing = true
    self.currentPublishAction = action

    -- Success callback: show UI feedback after complete() confirmed by server
    local window = self
    local itemName = self.selectedItem.name
    local finalQty = qty
    local finalCount = confirmedCount
    ---@diagnostic disable-next-line: undefined-field
    action:setOnComplete(function()
        logger:info("JASM_PublishTradeAction – complete callback: trade confirmed by server")

        -- Reset state
        window.isPublishing = false
        window.currentPublishAction = nil

        if window.footerPanel then
            ---@diagnostic disable-next-line: undefined-field
            window.footerPanel:setSuccess(
                "Trade published! ("
                    .. itemName
                    .. " x"
                    .. finalQty
                    .. ", "
                    .. finalCount
                    .. " paths)"
            )
        end
        -- Clear the optimistic pending marker now that server confirmed
        clientModData.pendingTrade = nil

        -- Rescan container and refresh UI
        window:refresh()
    end, nil)

    -- Cancel callback: clear pending marker if player aborts
    ---@diagnostic disable-next-line: undefined-field
    action:setOnCancel(function()
        logger:debug("JASM_PublishTradeAction – cancel callback")

        -- Reset state
        window.isPublishing = false
        window.currentPublishAction = nil

        clientModData.pendingTrade = nil
    end, nil)

    logger:info("OwnerViewWindow:onPublishClicked() – queuing JASM_PublishTradeAction", {
        itemType = payload.itemType,
        tradeCount = #tradesPayload,
    })
    ISTimedActionQueue.add(action)
    -- ────────────────────────────────────────────────────────────────────────
end

--- Show an error (or info) message in the footer error space.
---@param msg string
function OwnerViewWindow:showError(msg)
    logger:error("OwnerViewWindow:showError(): " .. tostring(msg))

    if self.footerPanel then
        ---@diagnostic disable-next-line: undefined-field
        self.footerPanel:setError(msg)
    end
end

--- Clear the error/info message.
function OwnerViewWindow:clearError()
    if self.footerPanel then
        ---@diagnostic disable-next-line: undefined-field
        self.footerPanel:clearError()
    end
end

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

---@param x number
---@param y number
---@param w number
---@param h number
---@param player IsoPlayer
---@param entity IsoObject
---@return OwnerViewWindow
function OwnerViewWindow:new(x, y, w, h, player, entity)
    logger:debug("OwnerViewWindow:new() instantiating window")
    local xuiSkin = XuiManager.GetDefaultSkin()
    local style = xuiSkin:getEntityUiStyle("JASM_OwnerViewWindow")
    ---@type OwnerViewWindow
    local o = ISEntityWindow:new(x, y, w, h, player, entity, style)
    setmetatable(o, self)
    self.__index = self

    o.panelCloseDistance = 2
    o.player = player
    o.xuiSkin = xuiSkin
    o.title = "JASM - Just Another Shop Mod"
    o.titleBar = true
    o.moveWithMouse = true
    o.enableHeader = true
    o:setResizable(false) -- disable resize because of performance
    -- Fixed dimensions per design5_rule §1 (but allow resize through standard handler)
    o.minimumWidth = 800
    o.minimumHeight = 600
    o.entity = entity

    -- Data
    o.dataManager = ShopDataManager()
    local container = entity:getContainer()

    if container then
        o.inventory = o.dataManager:scanContainer(container)
        o._lastContainerSize = container:getItems():size()
    else
        o.inventory = { map = {}, list = {} }
        o._lastContainerSize = 0
    end

    o.requirementPaths = {}
    o.hasUnsavedChanges = false
    o.selectedItem = nil
    o.offerQty = 1

    -- TimedAction state for anti-spam/progress
    o.isPublishing = false
    o.currentPublishAction = nil

    return o
end

--- Override close to release shop lock and prevent closing sibling windows
function OwnerViewWindow:close()
    if self.closing then
        return
    end
    self.closing = true

    logger:debug("OwnerViewWindow:close() - closing owner view only")

    -- Release shop lock if owner holds it (Issue 8)
    local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
    if lockMethod == 1 and self.entity then
        local square = self.entity:getSquare()
        if square then
            local squareID = KUtilities.SquareToString(square)
            KUtilities.SendClientCommand("JASM_ShopManager", "UnlockShop", {
                x = square:getX(),
                y = square:getY(),
                z = square:getZ(),
            })
            logger:debug("OwnerViewWindow:close() - unlock sent", { squareID = squareID })
        end
    end

    -- Save position for next open (vanilla pattern)
    OwnerViewWindow.coords = { self:getX(), self:getY(), self:getWidth(), self:getHeight() }

    -- Vanilla pattern: cleanup singleton
    OwnerViewWindow.instance = nil

    -- ISBaseEntityWindow.close handles: ISCollapsableWindow.close, ISEntityUI.OnCloseWindow,
    -- joypad cleanup, entity:setUsingPlayer(nil), and removeFromUIManager
    ISBaseEntityWindow.close(self)
end

-- ============================================================
-- REGISTRATION / CONTEXT MENU
-- ============================================================

local function _bringToTop(window)
    -- Bring to top if already open
    if window.instance:isVisible() then
        window.instance:bringToTop()
    else
        window.instance:setVisible(true)
        window.instance:bringToTop()
    end
end

---@param playerIndex integer
---@param _context any
---@param entity IsoObject
function OwnerViewWindow.open(playerIndex, _context, entity)
    logger:debug("OwnerViewWindow.open() - request for entity", {
        x = entity:getX(),
        y = entity:getY(),
        z = entity:getZ(),
    })

    local player = getSpecificPlayer(playerIndex)
    local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)

    -- ===== Lock check BEFORE instance/singleton check =====
    if lockMethod == 1 then
        -- Layer 1: Check JASM application-level lock via modData (synced from server)
        local modData = entity:getModData()
        if modData and modData.isShop then
            local globalModData = ModData.getOrCreate("JASM_ServerSession")
            local currentSession = globalModData and globalModData.id

            local lockSession = modData.shopLockSessionID
            local lockHolder = lockSession == currentSession and modData.shopLock or nil

            if lockHolder and lockHolder ~= player:getUsername() then
                HaloTextHelper.addBadText(
                    player,
                    "Shop is locked by " .. tostring(lockHolder) .. "."
                )
                logger:info("OwnerViewWindow.open() blocked - JASM lock", {
                    player = player:getUsername(),
                    lockedBy = lockHolder,
                })
                return nil
            end
        end

        -- Layer 2 awareness: fallback if entity shows a different user (desync guard)
        local entityUser = entity:getUsingPlayer()
        if entityUser and entityUser ~= player then
            local entityUserName = entityUser:getUsername()
            HaloTextHelper.addBadText(player, "Shop is in use by " .. entityUserName .. ".")
            logger:warn("OwnerViewWindow.open() blocked - entity desync (JASM unaware)", {
                player = player:getUsername(),
                entityUser = entityUserName,
            })
            return nil
        end
    elseif lockMethod == 2 then
        -- VANILLA mode: check only entity:getUsingPlayer()
        local entityUser = entity:getUsingPlayer()
        if entityUser and entityUser ~= player then
            HaloTextHelper.addBadText(
                player,
                "Shop is in use by " .. entityUser:getUsername() .. "."
            )
            logger:info("OwnerViewWindow.open() blocked - vanilla entity lock", {
                player = player:getUsername(),
                entityUser = entityUser:getUsername(),
            })
            return nil
        end
    end

    -- Vanilla pattern: Check if instance exists first
    if OwnerViewWindow.instance then
        _bringToTop(OwnerViewWindow)
        return OwnerViewWindow.instance
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local windowWidth = 800.0
    local windowHeight = 600.0
    -- Position left side, keeps center visible (player view/zombie danger zone)
    local windowX = math.max(0.0, screenWidth / 2.0 - windowWidth - 69.0)
    local windowY = math.max(0.0, (screenHeight - windowHeight) / 2.0)

    -- Use saved coords if available
    if OwnerViewWindow.coords then
        windowX, windowY = OwnerViewWindow.coords[1], OwnerViewWindow.coords[2]
    end

    local window = OwnerViewWindow:new(windowX, windowY, windowWidth, windowHeight, player, entity)
    window:initialise()
    window:addToUIManager()

    -- ===== Layer 1: Acquire JASM lock after window is successfully created =====
    if lockMethod == 1 then
        local square = entity:getSquare()
        if square then
            KUtilities.SendClientCommand("JASM_ShopManager", "LockShop", {
                x = square:getX(),
                y = square:getY(),
                z = square:getZ(),
            })
            logger:info("OwnerViewWindow.open() - LockShop sent", {
                player = player:getUsername(),
                squareID = KUtilities.SquareToString(square),
            })
        end
    end

    -- Store the instance
    OwnerViewWindow.instance = window

    return window
end

local function _onFillWorldObjectContextMenu(playerIndex, context, worldObjects)
    if worldObjects and #worldObjects > 0 then
        ---@type IsoObject
        local wObj = worldObjects and worldObjects[1] or nil

        if wObj and wObj:getContainer() then
            context:addOption("Open Owner Shop Config", nil, function()
                OwnerViewWindow.open(playerIndex, context, wObj)
            end)
        end
    end
end

-- Events.OnFillWorldObjectContextMenu.Add(_onFillWorldObjectContextMenu)

return OwnerViewWindow
