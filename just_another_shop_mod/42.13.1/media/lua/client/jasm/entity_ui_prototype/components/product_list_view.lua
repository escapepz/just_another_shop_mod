require("ISUI/ISPanel")
require("ISUI/ISScrollingListBox")

--- Lightweight list-only product panel.
--- Draws items as rows (icon + name + type + stock), with selection highlight.
--- API mirrors ProductListPanel so it can be dropped in wherever a list view is needed.
---@class ProductListView : ISPanel
---@field listPanel ISScrollingListBox
---@field target any
---@field onSelectProduct fun(target: any, product: any)
---@field selectedProduct any
---@field xuiSkin any
---@field player IsoPlayer
local ProductListView = ISPanel:derive("ProductListView")

-- ============================================================
-- DRAW
-- ============================================================

--- Custom item renderer for the scrolling list.
--- Called by ISScrollingListBox with `self` = the list box.
function ProductListView.doDrawListItem(listbox, y, item, alt)
    local self = listbox
    ---@cast self ISScrollingListBox

    if not item or not item.item then
        return y
    end
    local product = item.item
    local isSelected = self.selected == item.index
    local width = self.width
    if self.vscroll and self.vscroll:isVisible() then
        width = width - 16
    end
    local height = item.height or self.itemheight

    -- Row background: #0f0f0f
    self:drawRect(2, y + 2, width - 4, height - 4, 0.9, 0.06, 0.06, 0.06)
    self:drawRectBorder(2, y + 2, width - 4, height - 4, 0.6, 0.20, 0.20, 0.20)

    if isSelected then
        -- Selected: #2a2416 bg + orange border
        self:drawRect(1, y + 1, width - 2, height - 2, 1.0, 0.16, 0.14, 0.09)
        self:drawRectBorder(1, y + 1, width - 2, height - 2, 1.0, 0.95, 0.61, 0.07)
    end

    -- Icon
    if product.icon then
        local tex = product.icon
        if type(tex) == "string" then
            tex = getTexture(tex)
        end
        if tex then
            self:drawTextureScaled(tex, 12, y + 8, 24, 24, 1, 1, 1, 1)
        else
            self:drawText("?", 12, y + 10, 0.53, 0.53, 0.53, 1, UIFont.Medium)
        end
    else
        self:drawText("?", 12, y + 10, 0.53, 0.53, 0.53, 1, UIFont.Medium)
    end

    -- Name (#ccc) + Type meta (#666)
    self:drawText(product.name or "?", 44, y + 6, 0.80, 0.80, 0.80, 1, UIFont.Small)
    self:drawText(product.type or "", 44, y + 21, 0.40, 0.40, 0.40, 1, UIFont.Small)

    -- Stock (right-aligned, #888 / green)
    local vscrollWidth = (self.vscroll and self.vscroll:isVisible()) and self.vscroll:getWidth()
        or 0
    local rightMargin = 12 + vscrollWidth
    local stockTxt = tostring(product.stock or 0)
    local textW = getTextManager():MeasureStringX(UIFont.Small, stockTxt)
    local r, g, b = 0.53, 0.53, 0.53
    if (product.stock or 0) > 0 then
        r, g, b = 0.50, 0.83, 0.50
    end
    self:drawText(stockTxt, width - textW - rightMargin, y + 14, r, g, b, 1, UIFont.Small)

    return y + height
end

-- ============================================================
-- EVENTS
-- ============================================================

function ProductListView:onListItemClicked(item)
    local product = item
    if type(item) == "table" and item.item and item.itemindex then
        product = item.item
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.onSelectProduct then
        self.onSelectProduct(self.target, product)
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Populate the list with a product list/inventory object.
---@param products CustomerViewInventory|CustomerViewInventoryItem[]
function ProductListView:setProducts(products)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.listPanel then
        self.listPanel:clear()
    end

    local list = products
    if products and products.list then
        list = products.list
    end

    for _, product in ipairs(list or {}) do
        ---@diagnostic disable-next-line: unnecessary-if
        if self.listPanel then
            self.listPanel:addItem(product.name, product)
        end
    end
end

--- Highlight the given product as selected.
---@param product any
function ProductListView:setSelectedProduct(product)
    self.selectedProduct = product
    ---@diagnostic disable-next-line: unnecessary-if
    if self.listPanel then
        self.listPanel.selected = -1
        for i, listItem in ipairs(self.listPanel.items) do
            if listItem.item == product then
                self.listPanel.selected = i
                break
            end
        end
    end
end

-- ============================================================
-- LIFECYCLE
-- ============================================================

function ProductListView:createChildren()
    ISPanel.createChildren(self)

    ---@type ISScrollingListBox
    self.listPanel = ISXuiSkin.build(
        self.xuiSkin,
        nil,
        ISScrollingListBox,
        0,
        0,
        self.width,
        self.height
    )
    ---@diagnostic disable-next-line: unnecessary-if
    if self.listPanel then
        self.listPanel:initialise()
        self.listPanel:instantiate()
        self.listPanel.itemheight = 40
        self.listPanel.doDrawItem = self.doDrawListItem
        self.listPanel:setOnMouseDownFunction(self, self.onListItemClicked)
        self.listPanel.target = self
        self.listPanel.background = false
        self.listPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
        self.listPanel.borderColor = { r = 0.20, g = 0.20, b = 0.20, a = 0.5 }
        if not self.listPanel.vscroll then
            self.listPanel:addScrollBars()
        end
        self:addChild(self.listPanel)
    end
end

function ProductListView:calculateLayout(width, height)
    self:setWidth(width)
    self:setHeight(height)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.listPanel then
        self.listPanel:setX(0)
        self.listPanel:setY(0)
        self.listPanel:setWidth(width)
        self.listPanel:setHeight(height)
        if self.listPanel.vscroll then
            self.listPanel.vscroll:setHeight(height)
            self.listPanel.vscroll:setX(width - self.listPanel.vscroll:getWidth())
            self.listPanel.vscroll:setY(0)
        end
    end
    self.dirtyLayout = false
end

function ProductListView:xuiRecalculateLayout(
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

function ProductListView:prerender()
    ---@diagnostic disable-next-line: unnecessary-if
    if self.dirtyLayout then
        self:calculateLayout(self.width, self.height)
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Force stencil clipping to prevent items drawing outside our area (e.g. over window borders)
    if self.listPanel then
        self.listPanel:setStencilRect(0, 0, self.width, self.height)
    end

    ISPanel.prerender(self)
    -- Keep scrollbar properly sized when parent resizes
    if self.listPanel and self.listPanel.vscroll then
        self.listPanel.vscroll:setHeight(self.listPanel:getHeight())
        self.listPanel.vscroll:setX(self.listPanel:getWidth() - self.listPanel.vscroll:getWidth())
    end
end

function ProductListView:render()
    ISPanel.render(self)
    ---@diagnostic disable-next-line: unnecessary-if
    -- Clean up stencil so it doesn't affect other components
    if self.listPanel then
        self.listPanel:clearStencilRect()
    end
end

function ProductListView:onResize()
    ISPanel.onResize(self)
    self.dirtyLayout = true
    self:calculateLayout(self.width, self.height)
end

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

---@param x number
---@param y number
---@param w number
---@param h number
---@param player IsoPlayer
---@param xuiSkin any
---@return ProductListView
function ProductListView:new(x, y, w, h, player, xuiSkin)
    ---@type ProductListView
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    o.minimumWidth = 0
    o.minimumHeight = 40 -- enough to see at least one item
    o.background = true
    o.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
    o.dirtyLayout = true
    return o
end

return ProductListView

