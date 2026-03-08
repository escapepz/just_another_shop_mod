local pz_lua_commons = require("pz_lua_commons_client")
local class = pz_lua_commons.yonaba.yon_30log

---@class CustomerViewInventory
---@field map table<string, CustomerViewInventoryItem>
---@field list CustomerViewInventoryItem[]

---@class CustomerViewInventoryItem
---@field name string
---@field icon any
---@field item InventoryItem|nil
---@field type string
---@field count integer
---@field stock integer
---@field trades ShopItemTradeData|CustomerViewInventoryItemTradePath[]
---@field offerQty integer|nil

---@class ShopItemTradeData
---@field offerQty integer|nil
---@field paths CustomerViewInventoryItemTradePath[]

---@class CustomerViewInventoryItemTradePath
---@field requestItem string
---@field requestQty integer
---@field name string
---@field hasCount number|nil
---@field icon Texture|nil

---@class ShopDataManager
---@field inventory CustomerViewInventory
---@field fullList CustomerViewInventoryItem[]
local ShopDataManager = class("ShopDataManager")

--- Constructor
function ShopDataManager:init()
    ---@type CustomerViewInventory
    self.inventory = {
        map = {},
        list = {},
    }
    ---@type CustomerViewInventoryItem[]
    self.fullList = {}
end

--- Set the current inventory data
---@param inventory CustomerViewInventory
function ShopDataManager:setInventory(inventory)
    self.inventory = inventory
    self.fullList = inventory.list
end

--- Scan a container and populate the inventory structure
---@param container ItemContainer
function ShopDataManager:scanContainer(container)
    local inventory = { map = {}, list = {} }
    if not container then
        return inventory
    end

    local allItems = container:getItems()
    local size = allItems:size()
    local listCount = 0

    local modData = container:getParent() and container:getParent():getModData()
    local shopTrades = modData and modData.shopTrades or {}

    for i = 0, size - 1 do
        local item = allItems:get(i)
        local itemType = item:getFullType()

        local entry = inventory.map[itemType]
        if not entry then
            entry = {
                name = item:getName(),
                icon = item:getIcon(),
                item = item,
                type = itemType,
                count = 0,
                stock = 0,
                -- Load saved trades from modData if they exist
                trades = shopTrades[itemType],
            }
            inventory.map[itemType] = entry
            listCount = listCount + 1
            inventory.list[listCount] = entry
        end

        entry.count = entry.count + 1
        entry.stock = entry.count
    end

    self:setInventory(inventory)
    return inventory
end

--- Filter the inventory based on a search query
---@param query string
---@return CustomerViewInventory
function ShopDataManager:search(query)
    local q = query:lower()
    if q == "" then
        self.inventory.list = self.fullList
        return self.inventory
    end

    local filteredList = {}
    for i = 1, #self.fullList do
        local entry = self.fullList[i]
        if entry.name:lower():find(q, 1, true) or entry.type:lower():find(q, 1, true) then
            table.insert(filteredList, entry)
        end
    end

    self.inventory.list = filteredList
    return self.inventory
end

--- Sort the inventory list
---@param mode string "High Stock", "Low Stock", or "A-Z"
---@return CustomerViewInventory
function ShopDataManager:sort(mode)
    local list = self.inventory.list

    if mode == "High Stock" then
        table.sort(list, function(a, b)
            return a.stock > b.stock
        end)
    elseif mode == "Low Stock" then
        table.sort(list, function(a, b)
            return a.stock < b.stock
        end)
    else -- Default: A-Z
        table.sort(list, function(a, b)
            if a.name == b.name then
                return a.stock > b.stock
            end
            return a.name < b.name
        end)
    end

    return self.inventory
end

--- Static utility to scan player inventory.
---@param player IsoPlayer
---@param recursive boolean|nil If true, scans all sub-containers (backpacks). Defaults to false.
---@return CustomerViewInventory
function ShopDataManager.ScanPlayerInventory(player, recursive)
    local rootInv = player:getInventory()
    local pMap = { map = {}, list = {} }

    local function scan(container)
        if not container then
            return
        end
        local items = container:getItems()
        local size = items:size()
        for i = 0, size - 1 do
            local item = items:get(i)
            local type = item:getFullType()

            -- Register item count in map
            if not pMap.map[type] then
                pMap.map[type] = {
                    count = 0,
                    name = item:getName(),
                    icon = item:getIcon(),
                    type = type,
                }
                table.insert(pMap.list, pMap.map[type])
            end
            pMap.map[type].count = pMap.map[type].count + 1

            -- Recurse if enabled and item has its own inventory (backpacks, bags)
            if recursive then
                local subInv = item:getInventory()
                if subInv and subInv ~= container then
                    scan(subInv)
                end
            end
        end
    end

    scan(rootInv)
    return pMap
end

return ShopDataManager
