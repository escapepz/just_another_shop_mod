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

--- Override close to prevent closing sibling windows
function CustomerViewWindow:close()
    logger:debug("CustomerViewWindow:close() - closing customer view only")
    ISEntityWindow.close(self)
end

--- Create child components and set up the layout.
function CustomerViewWindow:createChildren()
    logger:debug("CustomerViewWindow:createChildren() called")
    ISEntityWindow.createChildren(self)

    self:removeDebugPanel()
    self:so_override_the_entity_header()

    ---@diagnostic disable-next-line: unnecessary-if
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

    ---@diagnostic disable-next-line: unnecessary-if
    -- Move the layout to the bottom of the child stack so it doesn't block
    -- the window's own area for dragging (title bar handle).
    if self.masterLayout then
        self.masterLayout:backMost()
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Interactive buttons MUST be on top of the layout to be clickable
    if self.collapseButton then
        self.collapseButton:bringToTop()
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.pinButton then
        self.pinButton:bringToTop()
    end
    ---@diagnostic disable-next-line: unnecessary-if
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

    ---@diagnostic disable-next-line: unnecessary-if
    -- The master layout handles 100% of the remaining content area
    if self.masterLayout then
        self.masterLayout:setX(0)
        self.masterLayout:setY(y)
        self.masterLayout:setWidth(width)
        self.masterLayout:setHeight(height - y - rh)
        self.masterLayout:calculateLayout(width, height - y - rh)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Simple pin/collapse buttons positioning
    if self.pinButton then
        self.pinButton:setX(width - 3 - self.pinButton:getWidth())
    end
    ---@diagnostic disable-next-line: unnecessary-if
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
    ---@diagnostic disable-next-line: unnecessary-if
    if self.dirtyLayout then
        local oldX = self:getX()
        local oldWidth = self:getWidth()

        ---@diagnostic disable-next-line: unnecessary-if
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
end

--- Remove the default debug panel if it exists.
function CustomerViewWindow:removeDebugPanel()
    ---@diagnostic disable-next-line: unnecessary-if
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
        self.xuiSkin
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
    end
end

--- Populate components with initial data.
function CustomerViewWindow:populateInitialData()
    ---@diagnostic disable-next-line: unnecessary-if
    -- Pass player inventory map
    if self.detailsPanel and self.player then
        local pMap = ShopDataManager.ScanPlayerInventory(self.player)
        self.detailsPanel:setInventory(pMap)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Set shop products
    if self.productPanel then
        self.productPanel:setProducts(self.inventory)
    end

    -- Initial selection
    local list = self.inventory.list
    if #list > 0 then
        self:onSelectProduct(list[1])
    ---@diagnostic disable-next-line: unnecessary-if
    elseif self.detailsPanel then
        self.detailsPanel:setProduct(nil)
    end
end

--- Callback for search input. Filters the product list based on the query.
---@param text string The search query.
function CustomerViewWindow:onSearch(text)
    logger:debug("CustomerViewWindow:onSearch() query: " .. tostring(text))
    local filteredInventory = self.dataManager:search(text)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.productPanel then
        self.productPanel:setProducts(filteredInventory)
    end
end

--- Callback for sort selection. Sorts the product list based on the chosen mode.
---@param mode string The sort mode ("High Stock", "Low Stock", or default A-Z).
function CustomerViewWindow:onSort(mode)
    logger:debug("CustomerViewWindow:onSort() mode: " .. tostring(mode))
    local sortedInventory = self.dataManager:sort(mode)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.productPanel then
        self.productPanel:setProducts(sortedInventory)
    end
end

--- Callback for view toggle (Grid/List).
---@param mode string The view mode.
function CustomerViewWindow:onViewToggle(mode)
    logger:debug("CustomerViewWindow:onViewToggle() mode: " .. tostring(mode))
    ---@diagnostic disable-next-line: unnecessary-if
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
    ---@diagnostic disable-next-line: unnecessary-if
    if self.detailsPanel then
        self.detailsPanel:setProduct(product)
    end
    ---@diagnostic disable-next-line: unnecessary-if
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
    ---@diagnostic disable-next-line: unnecessary-if
    if container then
        o.inventory = o.dataManager:scanContainer(container)
    else
        o.inventory = { map = {}, list = {} }
    end

    return o
end

-- Track open windows by entity to prevent cross-closing
local _openWindowsByEntity = {}

---@param playerIndex integer
---@param _context any
---@param entity IsoObject
---@param playerIndex integer
---@param _context any
---@param entity IsoObject
function CustomerViewWindow.open(playerIndex, _context, entity)
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    local windowWidth = 800
    local windowHeight = 600
    local windowX = (screenWidth - windowWidth - 90)
    local windowY = (screenHeight - windowHeight) / 2

    local player = getSpecificPlayer(playerIndex)
    local window =
        CustomerViewWindow:new(windowX, windowY, windowWidth, windowHeight, player, entity)
    window:initialise()
    window:addToUIManager()

    -- Track this window
    local entityID = entity:getObjectIndex()
    _openWindowsByEntity[entityID] = _openWindowsByEntity[entityID] or {}
    _openWindowsByEntity[entityID].customer = window

    return window
end

local function _onFillWorldObjectContextMenu(playerIndex, context, worldObjects)
    if worldObjects and #worldObjects > 0 then
        ---@type IsoObject
        local wObj = worldObjects and worldObjects[1] or nil
        ---@diagnostic disable-next-line: unnecessary-if
        if wObj and wObj:getContainer() then
            context:addOption("Open Customer Shop View", nil, function()
                CustomerViewWindow.open(playerIndex, context, wObj)
            end)
        end
    end
end

-- Events.OnFillWorldObjectContextMenu.Add(_onFillWorldObjectContextMenu)

return CustomerViewWindow
