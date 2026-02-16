---@class JASM_ShopView_Customer : ISPanel
---@field player IsoPlayer
---@field entity IsoObject
---@field layout ISTableLayout
---@field productGrid ISTiledIconListBox
---@field detailsPanel ISPanel
---@field detailsLayout ISTableLayout
---@field productNameLabel ISLabel
---@field priceLabel ISLabel
---@field buyButton ISButton
---@field errorLabel ISLabel
---@field dataList any
---@field selectedProduct any
---@field view JASM_ShopView_Customer | ISPanel  -- Define 'view' properly to avoid type mismatches
local JASM_ShopView_Customer = {}

---@param x number
---@param y number
---@param width number
---@param height number
---@param player IsoPlayer
---@param entity IsoObject
---@return JASM_ShopView_Customer
function JASM_ShopView_Customer:new(x, y, width, height, player, entity) end

---@param self JASM_ShopView_Customer
function JASM_ShopView_Customer:initialise() end

---@param self JASM_ShopView_Customer
function JASM_ShopView_Customer:createChildren() end

---@param self JASM_ShopView_Customer
function JASM_ShopView_Customer:refreshProducts() end

---@param self JASM_ShopView_Customer
---@param _tile any
---@param _data any
---@param _x number
---@param _y number
---@param _w number
---@param _h number
---@param _mouseover boolean
function JASM_ShopView_Customer:onRenderProductTile(_tile, _data, _x, _y, _w, _h, _mouseover) end

---@param self JASM_ShopView_Customer
---@param _data any
function JASM_ShopView_Customer:onProductSelected(_data) end

---@param self JASM_ShopView_Customer
function JASM_ShopView_Customer:updateBuyButton() end

---@param self JASM_ShopView_Customer
function JASM_ShopView_Customer:onBuy() end

---@param self JASM_ShopView_Customer
---@param _preferredWidth number
---@param _preferredHeight number
function JASM_ShopView_Customer:calculateLayout(_preferredWidth, _preferredHeight) end

return JASM_ShopView_Customer
