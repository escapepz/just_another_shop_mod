local ALLOWED_CRATE_SPRITES = {
    -- -- exact sprite match
    -- "constructedobjects_01_44",
    -- -- match any tile with container type "crate"
    -- { container = "crate" },
    -- -- match any tile with container type "crate" and starts with "constructedobjects_01_"
    -- { container = "crate", startsWith = "constructedobjects_01_" },
    -- -- match any "Metal Shelf" specifically
    -- { CustomName = "Shelf", GroupName = "Metal" },
    -- -- match any tile that is a "counter" container in the "Kitchen" group
    -- { container = "counter", GroupName = "Kitchen" },

    -- metal crates, lower level only (string = sprite name match)
    "constructedobjects_01_44",
    {
        container = "crate",
        GroupName = "Metal",
        CustomName = "Crate",
        ContainerPosition = "Low",
    },
    {
        container = "crate",
        GroupName = "Fancy Metal",
        CustomName = "Crate",
        ContainerPosition = "Low",
    },
    -- "constructedobjects_01_45",
    -- "constructedobjects_01_46",
    -- "constructedobjects_01_47",
    -- "crafted_05_44",

    -- wooden crates, lower level only
    { container = "crate", CustomName = "Crate", ContainerPosition = "Low" },
    -- "carpentry_01_16",
    -- "carpentry_01_19",
    -- "carpentry_02_104",

    -- military crates, lower level only
    {
        container = "militarycrate",
        GroupName = "Military",
        CustomName = "Crate",
        ContainerPosition = "Low",
    },
    -- "location_military_generic_01_0",
    -- "location_military_generic_01_1",
    -- "location_military_generic_01_8",
    -- "location_military_generic_01_9",

    -- Kiosk Shop Sprites (npcshop_ prefix)
    -- "npcshop_0",
    -- "npcshop_1",
    -- "npcshop_2",
    -- "npcshop_3",
    -- "npcshop_4",
    -- "npcshop_5",
    -- "npcshop_6",
    -- "npcshop_7",

    -- Player Shop Sprites (playershop_ prefix)
    { container = "crate", startsWith = "playershop_" },
    { container = "freeze", startsWith = "playershop_" },

    -- furniture_shelving_01_*
    -- Bookshelves
    { container = "shelves", GroupName = "Big Wall", CustomName = "Shelves" },
    { container = "shelves", GroupName = "Big Wall Corner", CustomName = "Shelves" },
    { container = "shelves", GroupName = "White Fancy", CustomName = "Shelves" },
    { container = "shelves", GroupName = "Oakwood", CustomName = "Shelves" },
    -- Metal Shelves
    { container = "metal_shelves", GroupName = "Large Metal", CustomName = "Shelves" },

    -- location_shop_*
    -- Magazine Shelves
    { container = "shelvesmag", startsWith = "location_shop_" },
    -- { container = "shelvesmag", CustomName = "Magazine Shelf" },

    -- Display Case
    { container = "displaycase", GroupName = "Glass Display", CustomName = "Counter" },
    { container = "displaycase", GroupName = "Glass Corner Display", CustomName = "Counter" },
    -- Vending Machine
    { container = "vendingsnack", GroupName = "Large", CustomName = "Machine" },
    { container = "vendingpop", GroupName = "Small Soda", CustomName = "Machine" },
    -- Cooler Fridge
    { container = "fridge", GroupName = "Generic Cooled", CustomName = "Shelves" },
    -- Display Case Bakery
    {
        container = "displaycasebakery",
        GroupName = "Rounded Glass Display",
        CustomName = "Counter",
    },
    -- Grocer Stand
    { container = "grocerstand", GroupName = "Shop Display", CustomName = "Counter" },
    { container = "grocerstand", GroupName = "Trapzoid Shop", CustomName = "Shelves" },

    -- location_restaurant_bar_01_*
    -- Bar Shelves
    { container = "shelves", GroupName = "Dark Right Bar Wall", CustomName = "Bar" },
    { container = "shelves", GroupName = "Dark Left Bar Wall", CustomName = "Bar" },
    { container = "shelves", GroupName = "Dark Bar Wall", CustomName = "Bar" },

    { container = "shelves", GroupName = "Right Bar Wall", CustomName = "Bar" },
    { container = "shelves", GroupName = "Left Bar Wall", CustomName = "Bar" },
    { container = "shelves", GroupName = "Bar Wall", CustomName = "Bar" },

    -- appliances_refrigeration_01_*
    -- Fridge
    { container = "fridge", GroupName = "Large", CustomName = "Fridge" },
    { container = "fridge", GroupName = "Industrial", CustomName = "Fridge" },
    { container = "fridge", GroupName = "White Industrial", CustomName = "Fridge" },
    -- Freezer
    { Freezer = "", GroupName = "Popsicle", CustomName = "Freezer" },

    -- Clothing Rack
    { container = "clothingrack", GroupName = "Large Clothes", CustomName = "Rack" },
    { container = "clothingrack", GroupName = "Small Clothes", CustomName = "Rack" },
    { container = "clothingrack", CustomName = "Clothes Stand" },
}

_G.JASM_ALLOWED_CRATE_SPRITES = _G.JASM_ALLOWED_CRATE_SPRITES or ALLOWED_CRATE_SPRITES

local JASM_Constants = {
    SHOP_TRADE_RANGE = 3,
    ITEM_COUNT_CAP = 500,
    ALLOWED_CRATE_SPRITES = _G.JASM_ALLOWED_CRATE_SPRITES,
}

local pairs, ipairs = pairs, ipairs
local type = type
local string_find = string.find
local table_insert = table.insert

local function matchProperties(props, pattern, spriteName)
    for k, v in pairs(pattern) do
        if k == "startsWith" and (not spriteName or string_find(spriteName, v, 1, true) ~= 1) then
            return false
        end

        if k ~= "startsWith" and (not props or not props:has(k) or props:get(k) ~= v) then
            return false
        end
    end
    return true
end

---@param pattern string|table
function JASM_Constants:registerAllowedContainer(pattern)
    if not pattern or not self.ALLOWED_CRATE_SPRITES then
        return
    end
    table_insert(self.ALLOWED_CRATE_SPRITES, pattern)
end

---@param spriteName string|nil
---@param tileObj IsoObject|nil
---@return boolean
function JASM_Constants:isValidShopContainer(spriteName, tileObj)
    -- Direct lookup in _G ensures we always have the latest table reference
    local allowed = _G.JASM_ALLOWED_CRATE_SPRITES or self.ALLOWED_CRATE_SPRITES
    if not allowed then
        return false
    end

    local props = tileObj and tileObj:getSprite() and tileObj:getSprite():getProperties()

    for _, pattern in ipairs(allowed) do
        local pType = type(pattern)

        -- Match by Name
        if pType == "string" and spriteName and string_find(spriteName, pattern) then
            return true
        end

        -- Match by Properties
        if pType == "table" and matchProperties(props, pattern, spriteName) then
            return true
        end
    end

    -- if props then
    --     local names = props:getPropertyNames()
    --     for i = 0, names:size() - 1 do
    --         local name = names:get(i)
    --         print("  prop: " .. name .. " = " .. tostring(props:get(name)))
    --     end
    -- end

    return false
end

return JASM_Constants
