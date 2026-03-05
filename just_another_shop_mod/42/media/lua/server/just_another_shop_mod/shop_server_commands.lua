local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local KUtilities = pz_utils.konijima.Utilities
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
local logger = ZUL.new("just_another_shop_mod")

-- Shops are protected by two main mechanisms:
-- 1. When shops are placed, shop:setIsThumpable(false) prevents zombies from targeting and damaging them.
-- 2. Block sledgehammer tool (ISDestroyCursorPatch.lua):
--    The canDestroy() function checks if an object's sprite name contains
--    either "npcshop_" or "playershop_" prefixes and blocks destruction for non-admin players.
--    Admins can still destroy shops since the patch checks if not (isAdmin()) first.
-- 3. Block Dismantle ?

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@return boolean
local function isAdminBypassEnabled()
    return JASM_SandboxVars.Get("AdminBypass") == true
end

---Check whether a container currently holds any items
---@param containerObj IsoObject
---@return boolean
local function containerHasItems(containerObj)
    local container = containerObj:getContainer()
    if not container then
        return false
    end
    return container:getItems():size() > 0
end

---Apply thumpable flag to tile objects if they exist
---@param thumpable any|nil
---@param thumpableN any|nil
---@param state boolean
local function setThumpable(thumpable, thumpableN, state)
    if thumpable then
        thumpable:setIsThumpable(state)
    end

    if thumpableN then
        thumpableN:setIsThumpable(state)
    end
end

-- ---------------------------------------------------------------------------
-- Action handlers (Single Responsibility)
-- ---------------------------------------------------------------------------

---Handle REGISTER action
---@param player IsoPlayer
---@param args table
---@param containerObj IsoObject
---@param thumpable any|nil
---@param thumpableN any|nil
local function handleRegister(player, args, containerObj, thumpable, thumpableN)
    local modData = containerObj:getModData()

    -- REGISTER is only allowed when there is no active shop.
    -- Admins are NOT exempt from this rule — an existing shop must be
    -- unregistered first before it can be re-registered.
    if modData.isShop then
        logger:error("Shop Register denied: already registered", { player = player:getUsername() })
        return
    end

    modData.isShop = true
    modData.shopType = args.shopType
    modData.shopOwnerID = player:getUsername()

    -- Prevent sledgehammer and dismantle
    modData.indestructible = true
    modData.immovable = true

    setThumpable(thumpable, thumpableN, false)

    logger:info("Shop Registered", { type = args.shopType, owner = modData.shopOwnerID })

    -- Persist and Sync to all clients
    containerObj:transmitModData()

    KUtilities.SendServerCommandTo(
        player,
        "JASM_ShopManager",
        "UpdateSuccess",
        { action = args.action }
    )
end

---Handle UNREGISTER action
---@param player IsoPlayer
---@param args table
---@param containerObj IsoObject
---@param thumpable any|nil
---@param thumpableN any|nil
local function handleUnregister(player, args, containerObj, thumpable, thumpableN)
    local modData = containerObj:getModData()
    local isOwner = modData.shopOwnerID == player:getUsername()
    local isAdmin = KUtilities.IsPlayerAdmin(player)
    local adminBypass = isAdminBypassEnabled()

    -- Ownership check: owner always allowed; admins allowed only if sandbox permits
    if not isOwner and not (isAdmin and adminBypass) then
        logger:error("Shop Unregister denied: not owner or admin", {
            player = player:getUsername(),
            owner = modData.shopOwnerID,
        })
        return
    end

    -- Container must be empty — no bypass, not even for admins
    if containerHasItems(containerObj) then
        logger:warn("Shop Unregister denied: container not empty", {
            player = player:getUsername(),
        })
        KUtilities.SendServerCommandTo(
            player,
            "JASM_ShopManager",
            "UnregisterDenied",
            { reason = "container_not_empty" }
        )
        return
    end

    modData.isShop = nil
    modData.shopType = nil
    modData.shopOwnerID = nil

    -- Remove sledgehammer and dismantle protection
    modData.indestructible = nil
    modData.immovable = nil

    setThumpable(thumpable, thumpableN, true)

    logger:info("Shop Unregistered", {
        x = args.x,
        y = args.y,
        by = player:getUsername(),
        isAdmin = isAdmin,
    })

    -- Persist and Sync to all clients
    containerObj:transmitModData()

    KUtilities.SendServerCommandTo(
        player,
        "JASM_ShopManager",
        "UpdateSuccess",
        { action = args.action }
    )
end

---Handle LockShop command
---@param player IsoPlayer
---@param args table
local function handleLockShop(player, args)
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
end

---Handle UnlockShop command
---@param player IsoPlayer
---@param args table
local function handleUnlockShop(player, args)
    local square = getSquare(args.x, args.y, args.z)
    if not square then
        return
    end

    local squareID = KUtilities.SquareToString(square)
    _G.JASM_ShopManager:unlockShop(squareID, player:getUsername())
    KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "UnlockSuccess", args)
end

---Handle ManageShop command (REGISTER / UNREGISTER)
---@param player IsoPlayer
---@param args table
local function handleManageShop(player, args)
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

    if args.action == "REGISTER" then
        handleRegister(player, args, containerObj, thumpable, thumpableN)
    elseif args.action == "UNREGISTER" then
        handleUnregister(player, args, containerObj, thumpable, thumpableN)
    end
end

-- ---------------------------------------------------------------------------
-- Dispatcher
-- ---------------------------------------------------------------------------

---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
local function OnClientCommand(module, command, player, args)
    if module ~= "JASM_ShopManager" then
        return
    end

    if command == "ManageShop" then
        handleManageShop(player, args)
    elseif command == "LockShop" then
        handleLockShop(player, args)
    elseif command == "UnlockShop" then
        handleUnlockShop(player, args)
    end
end

return OnClientCommand
