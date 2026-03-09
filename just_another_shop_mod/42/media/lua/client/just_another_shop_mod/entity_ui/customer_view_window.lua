require("Entity/ISUI/Windows/ISEntityWindow")
require("Entity/ISUI/Controls/ISTableLayout")
require("ISUI/ISLabel")
require("ISUI/ISButton")

local SearchFilterPanel =
    require("just_another_shop_mod/entity_ui/components/shop/shared/shop_search_filter_panel")
local ProductListPanel =
    require("just_another_shop_mod/entity_ui/components/product/product_list_panel")
local ItemDetailsPanel =
    require("just_another_shop_mod/entity_ui/components/shop/customer/shop_item_details_panel")
local ShopDataManager = require("just_another_shop_mod/entity_ui/models/shop_data_manager")

local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
local KUtilities = require("pz_utils_shared").konijima.Utilities

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

--- Main window for the Customer Shop View.
--- This window handles the display of shop inventory, searching, sorting, and selecting products for detailed view.
---@class CustomerViewWindow : ISEntityWindow
---@field player IsoPlayer
---@field xuiSkin XuiSkin
---@field titleBar boolean
---@field masterLayout ISTableLayout
---@field mainContentLayout ISTableLayout
---@field leftStackLayout ISTableLayout
---@field searchPanel ShopSearchFilterPanel
---@field productPanel ProductListPanel
---@field detailsPanel ShopItemDetailsPanel
---@field customHeader ISTableLayout
---@field inventory CustomerViewInventory
---@field dataManager ShopDataManager
local CustomerViewWindow = ISEntityWindow:derive("CustomerViewWindow")
CustomerViewWindow.instance = nil
CustomerViewWindow.coords = nil

--- Helper to build, initialise and instantiate a component in one go.
function CustomerViewWindow:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

--- Helper to build a component and immediately place it in a layout slot.
function CustomerViewWindow:xuiBuildInLayout(layout, col, row, style, class, ...)
    local o = self:xuiBuild(style, class, ...)
    if o and layout then
        layout:setElement(col, row, o)
    end
    return o
end

--- Initialise the window.
function CustomerViewWindow:initialise()
    logger:debug("CustomerViewWindow:initialise() called")
    ISEntityWindow.initialise(self)
end

function CustomerViewWindow:so_override_the_entity_header()
    if not self.entityHeader then
        return
    end

    -- Ensure the header itself is transparent to mouse events to allow window dragging
    ---@diagnostic disable-next-line: inject-field
    self.entityHeader.consumeMouseEvents = false

    -- CSS design colors (matches HTML window header area)
    -- Background: #0f0f0f
    self.entityHeader.background = true
    self.entityHeader.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    -- Bottom accent border: #f39c12 orange (matches HTML .details-header border-bottom)
    self.entityHeader.borderColor = { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }

    ---@cast self.entity IsoObject
    -- Apply to icon component
    if self.entityHeader.icon then
        local texName = self.entity:getTextureName()
        -- Icon slot size: 48px (matches HTML .preview-icon)
        local size = 48
        ---@diagnostic disable-next-line: inject-field
        self.entityHeader.iconSize = size

        -- Icon slot background: #1a1a1a (matches HTML .preview-icon background)
        ---@diagnostic disable-next-line: inject-field
        self.entityHeader.icon.background = true
        -- -@diagnostic disable-next-line: inject-field
        -- self.entityHeader.icon.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }

        -- Update the Icon texture
        ---@diagnostic disable-next-line: undefined-field
        self.entityHeader.icon.texture = getTexture(texName)
        self.entityHeader.icon:setWidth(size)
        self.entityHeader.icon:setHeight(size)
        ---@diagnostic disable-next-line: inject-field
        self.entityHeader.icon.autoScale = true

        -- Offset whitespace: world sprites are tall, shift up slightly
        self.entityHeader.icon:setY(-4)
    end

    -- Set Title: "SHOP INVENTORY" in white (#fff matches HTML .preview-text h2)
    if self.entityHeader.title then
        self.entityHeader.title:setName("SHOP INVENTORY")
        -- Title text color: #fff
        self.entityHeader.title.textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
    end

    self.entityHeader:calculateLayout(self.width, 0)
end

--- Override close to release shop lock and prevent closing sibling windows
function CustomerViewWindow:close()
    if self.closing then
        return
    end
    self.closing = true

    logger:debug("CustomerViewWindow:close() - closing customer view only")

    -- Release shop lock when window closes (Issue 8)
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
            logger:debug("CustomerViewWindow:close() - unlock sent", { squareID = squareID })
        end
    end

    -- Save position for next open (vanilla pattern)
    CustomerViewWindow.coords = { self:getX(), self:getY(), self:getWidth(), self:getHeight() }

    -- Vanilla pattern: cleanup singleton
    CustomerViewWindow.instance = nil

    -- ISBaseEntityWindow.close handles: ISCollapsableWindow.close, ISEntityUI.OnCloseWindow,
    -- joypad cleanup, entity:setUsingPlayer(nil), and removeFromUIManager
    ISBaseEntityWindow.close(self)
end

--- Create child components and set up the layout.
function CustomerViewWindow:createChildren()
    logger:debug("CustomerViewWindow:createChildren() called")
    ISEntityWindow.createChildren(self)

    self:removeDebugPanel()
    self:so_override_the_entity_header()

    -- Hide default B42 panels so they don't block our custom layout
    if self.componentsPanel then
        self.componentsPanel:setVisible(false)
    end

    -- Custom resize behavior
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.resizeWidget.resizeFunction = self.calculateLayout
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.resizeWidget2.resizeFunction = self.calculateLayout

    -- Build the layout hierarchy
    self:initLayout()
    self:initPanels()
    self:populateInitialData()

    -- Move the layout to the bottom of the child stack so it doesn't block
    -- the window's own area for dragging (title bar handle).
    if self.masterLayout then
        self.masterLayout:backMost()
    end

    -- Interactive buttons MUST be on top of the layout to be clickable
    if self.collapseButton then
        self.collapseButton:bringToTop()
    end

    if self.pinButton then
        self.pinButton:bringToTop()
    end

    if self.closeButton then
        self.closeButton:bringToTop()
    end

    -- Initialize preferred dimensions for dirty layout
    self.xuiPreferredResizeWidth = self.width
    self.xuiPreferredResizeHeight = self.height
    self:calculateLayout(self.width, self.height)
end

function CustomerViewWindow:xuiRecalculateLayout(
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

function CustomerViewWindow:calculateLayout(_preferredWidth, _preferredHeight)
    local th = self:titleBarHeight()
    local rh = self.resizable and self:resizeWidgetHeight() or 0

    -- Ensure we don't snap to minimum size if called without arguments
    local width = math.max(_preferredWidth or self.width, self.minimumWidth)
    local height = math.max(_preferredHeight or self.height, self.minimumHeight)

    -- Position the entity header first (the SHOP CUSTOMER VIEW bar)
    local y = th
    if self.entityHeader then
        self.entityHeader:setX(0)
        self.entityHeader:setY(y)
        self.entityHeader:calculateLayout(width, 0)
        y = y + self.entityHeader:getHeight()
    end

    -- The master layout handles 100% of the remaining content area
    if self.masterLayout then
        self.masterLayout:setX(0)
        self.masterLayout:setY(y)
        self.masterLayout:setWidth(width)
        self.masterLayout:setHeight(height - y - rh)
        self.masterLayout:calculateLayout(width, height - y - rh)
    end

    -- Simple pin/collapse buttons positioning
    if self.pinButton then
        self.pinButton:setX(width - 3 - self.pinButton:getWidth())
    end

    if self.collapseButton then
        self.collapseButton:setX(width - 3 - self.collapseButton:getWidth())
    end

    -- Final window dimension application
    if self.width ~= width then
        self:setWidth(width)
    end
    if self.height ~= height then
        self:setHeight(height)
    end
    self.dirtyLayout = false
end

function CustomerViewWindow:prerender()
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

    -- Issue 14 & Issue 5: Refresh shop inventory when container OR player inventory changes
    ---@cast self.entity IsoObject
    local _container = self.entity and self.entity:getContainer()
    local _playerInv = self.player and self.player:getInventory()

    local _shopDirty = false
    if _container then
        local _currentSize = _container:getItems():size()
        local _isDirty = _container:isDirty() or _container:isDrawDirty()
        if _currentSize ~= self._lastContainerSize or _isDirty then
            _shopDirty = true
        end
    end

    local _playerDirty = false
    if _playerInv then
        local _currentInvSize = _playerInv:getItems():size()
        local _isInvDirty = _playerInv:isDirty() or _playerInv:isDrawDirty()
        if _currentInvSize ~= self._lastPlayerInvSize or _isInvDirty then
            _playerDirty = true
        end
    end

    if _shopDirty or _playerDirty then
        self:refresh(_shopDirty, _playerDirty)
    end
end

--- Rescans containers and refreshes UI.
---@param shopDirty boolean If true, rescan shop container and rebuild product list.
---@param playerDirty boolean If true, rescan player inventory and update trade satisfactions.
function CustomerViewWindow:refresh(shopDirty, playerDirty)
    ---@cast self.entity IsoObject
    local _container = self.entity and self.entity:getContainer()
    if not _container then
        return
    end

    -- 1. Handle Shop Refresh
    if shopDirty then
        logger:debug("CustomerViewWindow:refresh() - SHOP dirty")
        self.dataManager:scanContainer(_container)
        self.inventory = self.dataManager.inventory
        self._lastContainerSize = _container:getItems():size()

        -- Flattened Search/Sort logic
        local sPanel = self.searchPanel
        if sPanel then
            local searchText = sPanel.searchBox:getInternalText() or ""
            local sortCombo = sPanel.sortCombo
            local sortMode = sortCombo and sortCombo:getOptionText(sortCombo.selected)
                or "Alphabetical (A-Z)"

            self.dataManager:search(searchText)
            self.dataManager:sort(sortMode)
        end

        if self.productPanel then
            self.productPanel:setProducts(self.inventory)
        end

        _container:setDrawDirty(false)
        _container:setDirty(false)
    end

    -- 2. Handle Player Refresh
    local _playerInv = self.player and self.player:getInventory()
    local _pInvMap = nil

    if playerDirty and _playerInv then
        logger:debug("CustomerViewWindow:refresh() - PLAYER dirty")
        _pInvMap = ShopDataManager.ScanPlayerInventory(self.player)
        self._lastPlayerInvSize = _playerInv:getItems():size()
        _playerInv:setDrawDirty(false)
        _playerInv:setDirty(false)
    end

    -- 3. Surgical Update of Details Panel
    -- Check requirements immediately
    local pPanel = self.productPanel
    local dPanel = self.detailsPanel
    if not (pPanel and dPanel and pPanel.selectedProduct) then
        return
    end

    local selected = pPanel.selectedProduct
    local freshProduct = self.inventory.map[selected.type]

    -- Handle "Item removed from shop" case and exit
    if not freshProduct then
        dPanel:setProduct(nil)
        return
    end

    -- Final sequence (No nesting)
    if _pInvMap then
        dPanel:setInventory(_pInvMap)
    end
    dPanel:setProduct(freshProduct)
    pPanel:setSelectedProduct(freshProduct)
end

--- Remove the default debug panel if it exists.
function CustomerViewWindow:removeDebugPanel()
    if self.entityDebug then
        self:removeChild(self.entityDebug)
        self.entityDebug = nil
    end
end

--- Initialize the main table layout structure.
function CustomerViewWindow:initLayout()
    -- 1. MASTER LAYOUT: Vertical Stack (Header Slot + Content Slot)
    local th = self:titleBarHeight()
    ---@type ISTableLayout
    self.masterLayout = self:xuiBuild(nil, ISTableLayout, 0, th, self.width, self.height - th)

    self.masterLayout.background = false
    ---@diagnostic disable-next-line: inject-field
    self.masterLayout.consumeMouseEvents = false
    self:addChild(self.masterLayout)
    self.masterLayout:addColumnFill()

    -- Only one row for content; Header is handled by the window itself
    self.masterLayout:addRowFill()

    -- 2. MAIN CONTENT LAYOUT: Horizontal Split (Left List + Right Details)
    ---@type ISTableLayout
    self.mainContentLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10, nil, nil, nil)
    -- Left panel ~60%, right panel ~40%  (matches HTML mockup: 60% / 40%)
    local colL = self.mainContentLayout:addColumn()
    colL.minimumWidth = 480
    local colR = self.mainContentLayout:addColumnFill()
    colR.minimumWidth = 320
    self.mainContentLayout:addRowFill()
    self.masterLayout:setElement(0, 0, self.mainContentLayout)

    -- 3. LEFT STACK LAYOUT: Vertical Split (Search Panel + Product List)
    ---@type ISTableLayout
    self.leftStackLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 10)
    self.leftStackLayout:addColumnFill()
    local rowS = self.leftStackLayout:addRow()
    if rowS then
        rowS.minimumHeight = 95
    end
    self.leftStackLayout:addRowFill()
    self.mainContentLayout:setElement(0, 0, self.leftStackLayout)

    self:calculateLayout(self.width, self.height)
end

--- Initialize the search, product, and details panels.
function CustomerViewWindow:initPanels()
    -- Build Search Panel -> Left Stack Row 0
    ---@type ShopSearchFilterPanel|nil
    self.searchPanel = self:xuiBuildInLayout(
        self.leftStackLayout,
        0,
        0,
        nil,
        SearchFilterPanel,
        0,
        0,
        10,
        95,
        self,
        self.xuiSkin
    )
    if self.searchPanel then
        self.searchPanel.onSearch = self.onSearch
        self.searchPanel.onSort = self.onSort
        self.searchPanel.onViewToggle = self.onViewToggle
    end

    -- Build Product List -> Left Stack Row 1
    ---@cast self.entity IsoObject

    ---@type ProductListPanel|nil
    self.productPanel = self:xuiBuildInLayout(
        self.leftStackLayout,
        0,
        1,
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
        self.productPanel.onSelectProduct = self.onSelectProduct
    end

    -- -- Build Details Panel -> Main Content Col 1
    ---@type ShopItemDetailsPanel|nil
    self.detailsPanel = self:xuiBuildInLayout(
        self.mainContentLayout,
        1,
        0,
        nil,
        ItemDetailsPanel,
        0,
        0,
        10,
        10,
        self.player,
        self.xuiSkin
    )
    if self.detailsPanel then
        self.detailsPanel.entity = self.entity
        self.detailsPanel.target = self -- Set target for refresh callbacks

        -- Initial player inventory sync for trade requirements
        local _pInvManager = ShopDataManager()
        local _pInvFresh = _pInvManager:scanContainer(self.player:getInventory())
        self.detailsPanel:setInventory(_pInvFresh)
    end
end

--- Populate components with initial data.
function CustomerViewWindow:populateInitialData()
    -- Pass player inventory map
    if self.detailsPanel and self.player then
        local pMap = ShopDataManager.ScanPlayerInventory(self.player)
        self.detailsPanel:setInventory(pMap)
    end

    -- Set shop products
    if self.productPanel then
        self.productPanel:setProducts(self.inventory)
    end

    -- Initial selection
    local list = self.inventory.list
    if #list > 0 then
        self:onSelectProduct(list[1])
    elseif self.detailsPanel then
        self.detailsPanel:setProduct(nil)
    end
end

--- Callback for search input. Filters the product list based on the query.
---@param text string The search query.
function CustomerViewWindow:onSearch(text)
    logger:debug("CustomerViewWindow:onSearch() query: " .. tostring(text))
    local filteredInventory = self.dataManager:search(text)

    if self.productPanel then
        self.productPanel:setProducts(filteredInventory)
    end
end

--- Callback for sort selection. Sorts the product list based on the chosen mode.
---@param mode string The sort mode ("High Stock", "Low Stock", or default A-Z).
function CustomerViewWindow:onSort(mode)
    logger:debug("CustomerViewWindow:onSort() mode: " .. tostring(mode))
    local sortedInventory = self.dataManager:sort(mode)

    if self.productPanel then
        self.productPanel:setProducts(sortedInventory)
    end
end

--- Callback for view toggle (Grid/List).
---@param mode string The view mode.
function CustomerViewWindow:onViewToggle(mode)
    logger:debug("CustomerViewWindow:onViewToggle() mode: " .. tostring(mode))

    if self.productPanel then
        self.productPanel:setViewMode(mode)
    end
end

--- Callback when a product is selected in the list/grid.
---@param product CustomerViewInventoryItem The selected product entry.
function CustomerViewWindow:onSelectProduct(product)
    logger:debug(
        "CustomerViewWindow:onSelectProduct() product: "
            .. (product and tostring(product.name) or "nil")
    )
    if not product then
        return
    end

    if self.detailsPanel then
        self.detailsPanel:setProduct(product)
    end

    if self.productPanel then
        self.productPanel:setSelectedProduct(product)
    end
end

--- Create a new instance of CustomerViewWindow.
---@param x number
---@param y number
---@param w number
---@param h number
---@param player IsoPlayer
---@param entity IsoObject
---@return CustomerViewWindow
function CustomerViewWindow:new(x, y, w, h, player, entity)
    logger:debug("CustomerViewWindow:new() instantiating window")
    local xuiSkin = XuiManager.GetDefaultSkin()
    local style = xuiSkin:getEntityUiStyle("JASM_CustomerViewWindow")
    ---@type CustomerViewWindow
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
    o.minimumWidth = 800
    o.minimumHeight = 600
    o.entity = entity

    -- Data Management
    o.dataManager = ShopDataManager()
    local container = entity:getContainer()

    if container then
        o.inventory = o.dataManager:scanContainer(container)
        o._lastContainerSize = container:getItems():size()
    else
        o.inventory = { map = {}, list = {} }
        o._lastContainerSize = 0
    end

    -- Track player inventory for trade paths
    o._lastPlayerInvSize = player:getInventory():getItems():size()

    return o
end

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
function CustomerViewWindow.open(playerIndex, _context, entity)
    logger:debug("CustomerViewWindow.open() - request for entity", {
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
                logger:info("CustomerViewWindow.open() blocked - JASM lock", {
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
            logger:warn("CustomerViewWindow.open() blocked - entity desync (JASM unaware)", {
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
            logger:info("CustomerViewWindow.open() blocked - vanilla entity lock", {
                player = player:getUsername(),
                entityUser = entityUser:getUsername(),
            })
            return nil
        end
    end

    -- Vanilla pattern: Check if instance exists first
    if CustomerViewWindow.instance then
        _bringToTop(CustomerViewWindow)
        return CustomerViewWindow.instance
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local windowWidth = 800.0
    local windowHeight = 600.0

    -- Position right side, keeps center visible (player view/zombie danger zone)
    local windowX = math.max(0.0, screenWidth - windowWidth - 90.0)
    local windowY = math.max(0.0, (screenHeight - windowHeight) / 2.0)

    -- Use saved coords if available
    if CustomerViewWindow.coords then
        windowX, windowY = CustomerViewWindow.coords[1], CustomerViewWindow.coords[2]
    end

    local window =
        CustomerViewWindow:new(windowX, windowY, windowWidth, windowHeight, player, entity)
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
            logger:info("CustomerViewWindow.open() - LockShop sent", {
                player = player:getUsername(),
                squareID = KUtilities.SquareToString(square),
            })
        end
    end

    -- Store the instance
    CustomerViewWindow.instance = window

    return window
end

local function _onFillWorldObjectContextMenu(playerIndex, context, worldObjects)
    if worldObjects and #worldObjects > 0 then
        ---@type IsoObject
        local wObj = worldObjects and worldObjects[1] or nil

        if wObj and wObj:getContainer() then
            context:addOption("Open Customer Shop View", nil, function()
                CustomerViewWindow.open(playerIndex, context, wObj)
            end)
        end
    end
end

-- Events.OnFillWorldObjectContextMenu.Add(_onFillWorldObjectContextMenu)

return CustomerViewWindow
