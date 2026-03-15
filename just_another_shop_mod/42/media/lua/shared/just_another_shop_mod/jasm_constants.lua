local ALLOWED_CRATE_SPRITES = {
    -- metal crates, lower level only
    "constructedobjects_01_44",
    "constructedobjects_01_45",
    "constructedobjects_01_46",
    "constructedobjects_01_47",
    "crafted_05_44",

    -- wooden crates, lower level only
    "carpentry_01_16",
    "carpentry_01_19",
    "carpentry_02_104",

    -- military crates, lower level only
    "location_military_generic_01_0",
    "location_military_generic_01_1",
    "location_military_generic_01_8",
    "location_military_generic_01_9",
}

local JASM_Constants = {
    SHOP_TRADE_RANGE = 3,
    ITEM_COUNT_CAP = 500,
    ALLOWED_CRATE_SPRITES = ALLOWED_CRATE_SPRITES,
}

---@param spriteName string|nil
---@return boolean
function JASM_Constants:isValidShopContainer(spriteName)
    if not spriteName or not self.ALLOWED_CRATE_SPRITES then
        return false
    end
    for _, pattern in ipairs(self.ALLOWED_CRATE_SPRITES) do
        if string.find(spriteName, pattern) then
            return true
        end
    end
    return false
end

return JASM_Constants
