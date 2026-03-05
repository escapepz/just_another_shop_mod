require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")
require("Entity/ISUI/CraftRecipe/ISTiledIconListBox")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local ProductListView =
    require("just_another_shop_mod/entity_ui/components/product/product_list_view")

--- Panel that displays a list of products, either as a grid or a list.
---@class ProductListPanel : ISPanel
---@field iconPanel ISTiledIconListBox
---@field listView ProductListView
---@field dataList any -- Java ArrayList
---@field mouseover boolean
---@field onSelectProduct fun(target: any, product: any)
---@field selected any
---@field target any
---@field player IsoPlayer
---@field xuiSkin any
---@field viewMode string
---@field selectedProduct any
local ProductListPanel = ISPanel:derive("ProductListPanel")

--- Helper to build, initialise and instantiate a component in one go.
function ProductListPanel:xuiBuild(style, class, ...)
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

--- Helper to build a component and immediately place it in a layout slot.
function ProductListPanel:xuiBuildInLayout(layout, col, row, style, class, ...)
    local o = self:xuiBuild(style, class, ...)
    if o and layout then
        layout:setElement(col, row, o)
    end
    return o
end

local function onRenderTile(_listbox, _product, _x, _y, _width, _height, _mouseover)
    if not _product then
        return
    end -- Safety guard
    local product = _product
    local _self = _listbox -- ISTiledIconListBox

    -- 1. Card Background: #0f0f0f  (matches .item-slot)
    _self:drawRect(_x + 4, _y + 4, _width - 8, _height - 8, 0.9, 0.06, 0.06, 0.06)
    -- Card border: #333
    _self:drawRectBorder(_x + 4, _y + 4, _width - 8, _height - 8, 0.9, 0.20, 0.20, 0.20)

    -- Selection / Hover  (matches .item-slot.selected  /  .item-slot:hover)
    if _self.selectedTileData == product then
        -- Selected: #2a2416 bg + #f39c12 orange border  (0.16,0.14,0.09 alpha=1)
        _self:drawRect(_x + 2, _y + 2, _width - 4, _height - 4, 1.0, 0.16, 0.14, 0.09)
        _self:drawRectBorder(_x + 2, _y + 2, _width - 4, _height - 4, 1.0, 0.95, 0.61, 0.07)
    elseif _mouseover then
        -- Hover: slightly lighter card  (#1a1a1a)
        _self:drawRect(_x + 2, _y + 2, _width - 4, _height - 4, 0.6, 0.10, 0.10, 0.10)
    end

    -- 2. Icon — draw directly using passed bounds
    if product.icon then
        local tex = product.icon
        if type(tex) == "string" then
            tex = getTexture(tex)
        end
        if tex then
            _self:drawTextureScaled(tex, _x, _y, _width, _height, 1, 1, 1, 1)
        else
            -- Fallback for emoji/text icons
            local font = UIFont.Large
            local textW = getTextManager():MeasureStringX(font, product.icon)
            local textH = getTextManager():getFontHeight(font)
            _self:drawText(
                product.icon,
                _x + (_width - textW) / 2,
                _y + (_height - textH) / 2,
                0.8,
                0.8,
                0.8,
                1,
                font
            )
        end
    end

    -- 3. Stock Count badge (bottom-right, matches .slot-qty: #888 text, dark bg)
    local qty = tostring(product.stock or 0)
    local qtyW = getTextManager():MeasureStringX(UIFont.Small, qty)
    local qtyH = 14
    local badgeX = _x + _width - qtyW - 4
    local badgeY = _y + _height - qtyH - 2
    _self:drawRect(badgeX - 2, badgeY, qtyW + 4, qtyH, 0.75, 0.0, 0.0, 0.0)

    -- Stock color: #888 when zero, green when > 0  (matches .slot-qty color logic)
    local r, g, b = 0.53, 0.53, 0.53
    if (product.stock or 0) > 0 then
        r, g, b = 0.50, 0.83, 0.50 -- #7fd37f green
    end
    _self:drawText(qty, badgeX, badgeY, r, g, b, 1, UIFont.Small)
end

---@param product any
function ProductListPanel:onTileClicked(product)
    logger:debug(
        "ProductListPanel:onTileClicked() product: "
            .. (product and tostring(product.name) or "nil")
    )

    if self.onSelectProduct then
        self.onSelectProduct(self.target, product)
    end
end

function ProductListPanel:createChildren()
    logger:debug("ProductListPanel:createChildren() called")
    ISPanel.createChildren(self)

    ---@diagnostic disable-next-line: undefined-global
    self.dataList = ArrayList.new()

    -- 1. GRID VIEW pagination bar
    local btnSize = getTextManager():getFontHeight(UIFont.Small) + 6

    ---@type ISButton
    self.gridPrevBtn = self:xuiBuild(nil, ISButton, 0, 0, btnSize, btnSize, nil, self, function()
        if self.iconPanel then
            self.iconPanel:setCurrentPage(self.iconPanel:getCurrentPage() - 1)
            self:onGridPageChanged()
        end
    end)

    if self.gridPrevBtn then
        self.gridPrevBtn.image = getTexture("ArrowLeft")
        self:addChild(self.gridPrevBtn)
    end

    ---@type ISLabel
    self.gridPageLabel = ISLabel:new(0, 0, btnSize, "1 / 1", 1, 1, 1, 1, UIFont.Small, true)
    self.gridPageLabel:initialise()
    self.gridPageLabel:instantiate()
    self:addChild(self.gridPageLabel)

    ---@type ISButton
    self.gridNextBtn = self:xuiBuild(nil, ISButton, 0, 0, btnSize, btnSize, nil, self, function()
        if self.iconPanel then
            self.iconPanel:setCurrentPage(self.iconPanel:getCurrentPage() + 1)
            self:onGridPageChanged()
        end
    end)

    if self.gridNextBtn then
        self.gridNextBtn.image = getTexture("ArrowRight")
        self:addChild(self.gridNextBtn)
    end

    -- 1b. GRID VIEW (ISTiledIconListBox)
    ---@type ISTiledIconListBox
    self.iconPanel =
        self:xuiBuild(nil, ISTiledIconListBox, 0, 0, self.width, self.height, self.dataList)

    if self.iconPanel then
        self.iconPanel.onRenderTile = onRenderTile
        self.iconPanel.onClickTile = function(_target, product)
            self:onTileClicked(product)
        end
        self.iconPanel.onPageChanged = function()
            self:onGridPageChanged()
        end
        self.iconPanel.minimumColumns = 1
        self.iconPanel.target = self
        self:addChild(self.iconPanel)
    end

    -- 2. LIST VIEW
    self.listView = ProductListView:new(0, 0, self.width, self.height, self.player, self.xuiSkin)

    if self.listView then
        self.listView:initialise()
        self.listView:instantiate()
        self.listView.target = self
        self.listView.onSelectProduct = function(_target, product)
            if self.onSelectProduct then
                self.onSelectProduct(self.target, product)
            end
        end
        self.listView:setVisible(false)
        self:addChild(self.listView)
    end

    self.dirtyLayout = true
end

function ProductListPanel:xuiRecalculateLayout(
    _preferredWidth,
    _preferredHeight,
    _force,
    _anchorRight
)
    if self.calculateLayout and ((not self.dirtyLayout) or _force) then
        self.xuiPreferredResizeWidth = self.width
        self.xuiPreferredResizeHeight = self.height
        self.dirtyLayout = true
    end
end

function ProductListPanel:onGridPageChanged()
    if self.iconPanel and self.gridPageLabel then
        local pages = math.max(1, self.iconPanel:getPages())
        local cur = self.iconPanel:getCurrentPage() + 1
        local text = tostring(cur) .. " / " .. tostring(pages)
        self.gridPageLabel:setName(text)
        -- Re-centre the label now that the text (and thus width) may have changed
        local lblW = getTextManager():MeasureStringX(UIFont.Small, text) + 10
        self.gridPageLabel:setWidth(lblW)
        self.gridPageLabel:setX((self:getWidth() - lblW) / 2)
    end
end

function ProductListPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    -- Pagination bar dimensions
    local btnSize = self.gridPrevBtn and self.gridPrevBtn:getHeight() or 0
    local barHeight = btnSize > 0 and (btnSize + 4) or 0 -- 4px gap below bar

    if self.gridPrevBtn then
        self.gridPrevBtn:setX(0)
        self.gridPrevBtn:setY(0)
    end

    if self.gridPageLabel then
        local lblW = getTextManager():MeasureStringX(
            UIFont.Small,
            self.gridPageLabel:getName() or "1 / 1"
        ) + 10
        self.gridPageLabel:setWidth(lblW)
        self.gridPageLabel:setX((width - lblW) / 2)
        self.gridPageLabel:setY(0)
    end

    if self.gridNextBtn then
        self.gridNextBtn:setX(width - btnSize)
        self.gridNextBtn:setY(0)
    end

    if self.iconPanel then
        self.iconPanel:setX(0)
        self.iconPanel:setY(barHeight)
        self.iconPanel:setWidth(width)
        self.iconPanel:setHeight(height - barHeight)
        self.iconPanel:calculateTiles()
        self:onGridPageChanged()
    end

    if self.listView then
        self.listView:setX(0)
        self.listView:setY(0)
        self.listView:calculateLayout(width, height)
    end

    self:setWidth(width)
    self:setHeight(height)
    self.dirtyLayout = false
end

function ProductListPanel:prerender()
    if self.dirtyLayout and self.calculateLayout then
        self:calculateLayout(self.xuiPreferredResizeWidth, self.xuiPreferredResizeHeight)
    end
    ISPanel.prerender(self)
end

function ProductListPanel:onResize()
    ISPanel.onResize(self)
    self:calculateLayout(self.width, self.height)
end

function ProductListPanel:setViewMode(mode)
    logger:debug("ProductListPanel:setViewMode() mode: " .. tostring(mode))
    self.viewMode = mode
    local isGrid = mode == "grid"

    if self.iconPanel then
        self.iconPanel:setVisible(isGrid)
    end

    if self.gridPrevBtn then
        self.gridPrevBtn:setVisible(isGrid)
    end

    if self.gridPageLabel then
        self.gridPageLabel:setVisible(isGrid)
    end

    if self.gridNextBtn then
        self.gridNextBtn:setVisible(isGrid)
    end

    if self.listView then
        self.listView:setVisible(not isGrid)
    end
    self.dirtyLayout = true
    self:calculateLayout(self.width, self.height)
end

function ProductListPanel:setSelectedProduct(product)
    logger:debug(
        "ProductListPanel:setSelectedProduct() product: "
            .. (product and tostring(product.name) or "nil")
    )
    self.selectedProduct = product

    -- Sync Grid
    if self.iconPanel then
        ---@diagnostic disable-next-line: inject-field
        self.iconPanel.selectedTileData = product
    end

    -- Sync List
    if self.listView then
        self.listView:setSelectedProduct(product)
    end
end

function ProductListPanel:setProducts(products)
    logger:debug(
        "ProductListPanel:setProducts() count: "
            .. (products and products.list and #products.list or (products and #products or 0))
    )
    if self.dataList then
        self.dataList:clear()
    end

    local list = products
    if products and products.list then
        list = products.list
    end

    for _, product in ipairs(list or {}) do
        if self.dataList then
            self.dataList:add(product)
        end
    end

    -- Refresh ListView
    if self.listView then
        self.listView:setProducts(products)
    end

    -- Refresh grid
    if self.iconPanel then
        self.iconPanel:calculateTiles()
    end
    self.dirtyLayout = true
    self:calculateLayout(self.width, self.height)
end

function ProductListPanel:new(x, y, w, h, player, xuiSkin)
    logger:debug("ProductListPanel:new() called")
    ---@type ProductListPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    o.viewMode = "grid"
    o.minimumWidth = 0
    o.minimumHeight = 0
    -- Left panel background: #1a1a1a (matching middle-panel in HTML)
    o.background = true
    o.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
    return o
end

return ProductListPanel
