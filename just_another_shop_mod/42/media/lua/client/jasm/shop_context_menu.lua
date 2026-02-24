local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

local JASM_ShopView_Customer = require("jasm/entity_ui/customer_view_window")
local JASM_ShopView_Owner = require("jasm/entity_ui/owner_view_window")

-- guard again non crate objects
local allowedCrates = { ["Base.Wood_Crate"] = true, ["Base.Metal_Crate"] = true }

---@param worldObjects IsoObject[]
---@param playerObj IsoPlayer
---@param action string
---@param shopType string
local function onShopAction(worldObjects, playerObj, action, shopType)
    local containerObj = nil
    for _, obj in ipairs(worldObjects) do
        ---@diagnostic disable-next-line: unnecessary-if
        if obj:getContainer() then
            containerObj = obj
            break
        end
    end

    -- print(playerObj)

    if not containerObj then
        return
    end

    local args = {
        x = containerObj:getX(),
        y = containerObj:getY(),
        z = containerObj:getZ(),
        index = containerObj:getObjectIndex(),
        shopType = shopType,
        action = action,
    }

    -- Sends command to server
    KUtilities.SendClientCommand("JASM_ShopManager", "ManageShop", args)
end

---@param playerIndex integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
---@param test boolean
local function DoShopContextMenu(playerIndex, context, worldObjects, test)
    if test then
        return
    end
    local playerObj = getSpecificPlayer(playerIndex)
    local isAdmin = KUtilities.IsPlayerAdmin(playerObj)

    ---@type IsoObject|nil
    local containerObj = nil
    for _, obj in ipairs(worldObjects) do
        ---@diagnostic disable-next-line: unnecessary-if
        if obj:getContainer() then
            containerObj = obj
            break
        end
    end
    if not containerObj then
        return
    end

    local modData = containerObj:getModData()
    local isShop = modData.isShop
    local shopType = modData.shopType
    local objName = containerObj:getObjectName()

    local entityDisplayName = containerObj:getEntityDisplayName() or "Unknown"

    local entityFullTypeDebug = containerObj:getEntityFullTypeDebug()
    if not entityFullTypeDebug then
        return
    end

    -- print(containerObj:getObjectName()) -- Thumpable
    -- print(containerObj:getName()) -- Wood_Crate_Lvl1
    -- print(containerObj:getObjectIndex())
    -- print(containerObj:getX())
    -- print(containerObj:getY())
    -- print(containerObj:getZ())
    -- print(containerObj:getEntityDisplayName())
    -- print(containerObj:getEntityFullTypeDebug())

    -- guard again non thumpable objects
    if objName ~= "Thumpable" then
        return
    end

    -- 1. Try to capture everything before "_Lvl"
    local baseName = string.match(entityFullTypeDebug, "(.-)_Lvl%d+") or entityFullTypeDebug

    if not allowedCrates[baseName] then
        return
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Top Level Shop Access
    if isShop then
        -- Open Customer View
        context:addOption("Open Shop UI", worldObjects, function()
            JASM_ShopView_Customer.open(playerIndex, nil, containerObj)
        end)
    end

    -- JASM Management Submenu (Registration/NPC/Management)
    local jOption = context:addOption("JASM Shop", worldObjects, nil)
    local jMenu = ISContextMenu:getNew(context)
    context:addSubMenu(jOption, jMenu)

    ---@diagnostic disable-next-line: unnecessary-if
    if isShop then
        -- Open Owner View (if owner or admin)
        local isOwner = modData.shopOwnerID == playerObj:getUsername()
        ---@diagnostic disable-next-line: unnecessary-if
        if isOwner or isAdmin then
            jMenu:addOption("Manage Shop", worldObjects, function()
                JASM_ShopView_Owner.open(playerIndex, nil, containerObj)
            end)
        end
    end

    ---@diagnostic disable-next-line: unnecessary-if
    -- Player Shop Submenu
    if not isShop or shopType == "PLAYER" or isAdmin then
        local pOption = jMenu:addOption("Player Shop", worldObjects, nil)
        local pMenu = ISContextMenu:getNew(jMenu)
        jMenu:addSubMenu(pOption, pMenu)

        if not isShop then
            pMenu:addOption(
                "Register Shop [" .. entityDisplayName .. "]",
                worldObjects,
                onShopAction,
                playerObj,
                "REGISTER",
                "PLAYER"
            )
        else
            pMenu:addOption(
                "UnRegister Shop [" .. entityDisplayName .. "]",
                worldObjects,
                onShopAction,
                playerObj,
                "UNREGISTER",
                "PLAYER"
            )
        end
    end

    -- NPC Shop Submenu (Admin Only)
    if isAdmin then
        if not isShop or shopType == "SYSTEM" then
            local nOption = jMenu:addOption("NPC Shop", worldObjects, nil)
            local nMenu = ISContextMenu:getNew(jMenu)
            jMenu:addSubMenu(nOption, nMenu)

            if not isShop then
                nMenu:addOption(
                    "Register Shop  [" .. entityDisplayName .. "]",
                    worldObjects,
                    onShopAction,
                    playerObj,
                    "REGISTER",
                    "SYSTEM"
                )
            else
                nMenu:addOption(
                    "UnRegister Shop [" .. entityDisplayName .. "]",
                    worldObjects,
                    onShopAction,
                    playerObj,
                    "UNREGISTER",
                    "SYSTEM"
                )
            end
        end
    end
end

return DoShopContextMenu
