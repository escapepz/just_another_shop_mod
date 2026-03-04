local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("just_another_shop_mod")

-- Shops are protected by two main mechanisms:
-- 1. When shops are placed, shop:setIsThumpable(false) prevents zombies from targeting and damaging them.
-- 2. Block sledgehammer tool (ISDestroyCursorPatch.lua):
--    The canDestroy() function checks if an object's sprite name contains
--    either "npcshop_" or "playershop_" prefixes and blocks destruction for non-admin players.
--    Admins can still destroy shops since the patch checks if not (isAdmin()) first.
-- 3. Block Dismantle ?

---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
local function OnClientCommand(module, command, player, args)
    if module ~= "JASM_ShopManager" then
        return
    end

    if command == "ManageShop" then
        local square = getSquare(args.x, args.y, args.z)
        if not square then
            return
        end

        local containerObj = square:getObjects():get(args.index)
        if not containerObj or not containerObj:getContainer() then
            return
        end

        -- used for disable zed target hit
        local thumpable = square:getThumpable(false)
        local thumpableN = square:getThumpable(true)

        local modData = containerObj:getModData()

        if args.action == "REGISTER" then
            -- Optional security: Only allow register if not already a shop
            if not modData.isShop or KUtilities.IsPlayerAdmin(player) then
                modData.isShop = true
                modData.shopType = args.shopType
                modData.shopOwnerID = player:getUsername()

                -- Prevent sledgehammer and dismantle
                modData.indestructible = true
                modData.immovable = true

                ---@diagnostic disable-next-line: unnecessary-if
                if thumpable then
                    thumpable:setIsThumpable(false)
                end

                ---@diagnostic disable-next-line: unnecessary-if
                if thumpableN then
                    thumpableN:setIsThumpable(false)
                end

                logger:info(
                    "Shop Registered",
                    { type = args.shopType, owner = modData.shopOwnerID }
                )
            else
                logger:error(
                    "Shop Register denied: already registered",
                    { player = player:getUsername() }
                )
                return
            end
        elseif args.action == "UNREGISTER" then
            local isOwner = modData.shopOwnerID == player:getUsername()
            local isAdmin = KUtilities.IsPlayerAdmin(player)

            ---@diagnostic disable-next-line: unnecessary-if
            if isOwner or isAdmin then
                modData.isShop = nil
                modData.shopType = nil
                modData.shopOwnerID = nil

                -- Remove sledgehammer and dismantle protection
                modData.indestructible = nil
                modData.immovable = nil

                ---@diagnostic disable-next-line: unnecessary-if
                if thumpable then
                    thumpable:setIsThumpable(true)
                end

                ---@diagnostic disable-next-line: unnecessary-if
                if thumpableN then
                    thumpableN:setIsThumpable(true)
                end

                logger:info("Shop Unregistered", {
                    x = args.x,
                    y = args.y,
                    by = player:getUsername(),
                    isAdmin = isAdmin,
                })
            else
                logger:error("Shop Unregister denied: not owner or admin", {
                    player = player:getUsername(),
                    owner = modData.shopOwnerID,
                })
                return
            end
        end

        -- Persist and Sync to all clients
        containerObj:transmitModData()

        -- Optional: Explicit sync notification back to the player
        KUtilities.SendServerCommandTo(
            player,
            "JASM_ShopManager",
            "UpdateSuccess",
            { action = args.action }
        )
    elseif command == "LockShop" then
        local square = getSquare(args.x, args.y, args.z)
        if not square then
            return
        end
        local squareID = KUtilities.SquareToString(square)

        if _G.JASM_ShopManager:lockShop(squareID, player:getUsername()) then
            KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "LockSuccess", args)
        else
            KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "LockFail", args)
        end
    elseif command == "UnlockShop" then
        local square = getSquare(args.x, args.y, args.z)
        if not square then
            return
        end
        local squareID = KUtilities.SquareToString(square)
        _G.JASM_ShopManager:unlockShop(squareID, player:getUsername())
        KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "UnlockSuccess", args)
    end
end

return OnClientCommand
