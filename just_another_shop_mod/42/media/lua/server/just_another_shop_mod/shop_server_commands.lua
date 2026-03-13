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
-- Lock State Wrappers
-- ---------------------------------------------------------------------------

---Store shop lock in modData
---@param containerObj IsoObject
---@param username string Player username
---@return boolean success
local function setShopLock(containerObj, username)
    if not containerObj then
        logger:debug("setShopLock - aborting, containerObj is nil")
        return false
    end
    local modData = containerObj:getModData()
    if modData.shopLock == username then
        return true -- already locked by this user, redundant but valid
    end
    modData.shopLock = username
    local sessionData = ModData.getOrCreate("JASM_ServerSession")
    modData.shopLockSessionID = sessionData and sessionData.id
    containerObj:transmitModData()
    logger:debug("setShopLock", {
        shopName = modData.shopName,
        lockedBy = username,
    })
    return true
end

---Release shop lock from modData
---@param containerObj IsoObject
---@param username string Player username (must match current lock holder)
---@return boolean success
local function clearShopLock(containerObj, username)
    if not containerObj then
        logger:debug("clearShopLock - aborting, containerObj is nil")
        return false
    end
    local modData = containerObj:getModData()
    if modData.shopLock == username then
        modData.shopLock = nil
        modData.shopLockSessionID = nil
        containerObj:transmitModData()
        logger:debug("clearShopLock", {
            shopName = modData.shopName,
            wasLockedBy = username,
        })
        return true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Action handlers (Single Responsibility)
-- ---------------------------------------------------------------------------

---Count player's active shops from global registry
---@param ownerID string
---@return number
local function getPlayerShopCount(ownerID)
    local registeredShops = ModData.getOrCreate("JASM_RegisteredShops")
    local count = 0
    for _, shop in pairs(registeredShops) do
        if shop.ownerID == ownerID then
            count = count + 1
        end
    end
    return count
end

---Get effective limit for player
---@param ownerID string
---@return number
local function getPlayerShopLimit(ownerID)
    local limits = ModData.getOrCreate("JASM_PlayerShopLimits")
    if limits[ownerID] ~= nil then
        return limits[ownerID]
    end
    return JASM_SandboxVars.Get("MaxPlayerShopsPerPlayer", 5)
end

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
        KUtilities.SendServerCommandTo(
            player,
            "JASM_ShopManager",
            "RegisterDenied",
            { reason = "already_registered" }
        )
        return
    end

    local ownerID = player:getUsername()
    local limit = getPlayerShopLimit(ownerID)
    local count = getPlayerShopCount(ownerID)
    if count >= limit then
        logger:warn("Shop Register denied: limit reached", {
            player = ownerID,
            current = count,
            limit = limit,
        })
        KUtilities.SendServerCommandTo(
            player,
            "JASM_ShopManager",
            "RegisterDenied",
            { reason = "limit_reached", limit = limit, current = count }
        )
        return
    end

    modData.isShop = true
    modData.shopType = args.shopType
    modData.shopOwnerID = ownerID

    -- Prevent sledgehammer and dismantle
    modData.indestructible = true
    modData.immovable = true

    setThumpable(thumpable, thumpableN, false)

    logger:info("Shop Registered", { type = args.shopType, owner = modData.shopOwnerID })

    -- Save to global registry
    local square = containerObj:getSquare()
    if square then
        local squareID = KUtilities.SquareToString(square)
        local registeredShops = ModData.getOrCreate("JASM_RegisteredShops")
        registeredShops[squareID] = {
            ownerID = ownerID,
            shopName = args.shopName or "A Shop",
            registeredDate = pz_utils.escape.Utilities.GetIRLTimestamp(),
        }
    end

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
        KUtilities.SendServerCommandTo(
            player,
            "JASM_ShopManager",
            "UnregisterDenied",
            { reason = "not_owner_or_admin" }
        )
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

    -- Remove from global registry
    local square = containerObj:getSquare()
    if square then
        local squareID = KUtilities.SquareToString(square)
        local registeredShops = ModData.getOrCreate("JASM_RegisteredShops")
        registeredShops[squareID] = nil
    end

    -- Persist and Sync to all clients
    containerObj:transmitModData()

    KUtilities.SendServerCommandTo(
        player,
        "JASM_ShopManager",
        "UpdateSuccess",
        { action = args.action }
    )
end

-- Helper to find the shop object on a square
local function getShopObject(square)
    local objects = square:getObjects()
    if not objects then
        return nil
    end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local modData = obj:getModData()
        if modData and modData.isShop then
            return obj, modData
        end
    end
    return nil
end

---@param player IsoPlayer
---@param args table
local function handleLockShop(player, args)
    -- In VANILLA mode, ISEntityWindow owns the lock; no modData write
    local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
    if lockMethod == 2 then
        logger:debug("handleLockShop - VANILLA mode, skip modData write")
        return
    end

    local square = getSquare(args.x, args.y, args.z)
    if not square then
        return logger:debug("handleLockShop - no square", args)
    end

    local obj, modData = getShopObject(square)
    if not obj then
        return logger:debug("handleLockShop - no shop", args)
    end

    local username = player:getUsername()

    -- Check ownership/lock status
    if modData.shopLock and modData.shopLock ~= username then
        KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "LockFail", args)
        return logger:warn(
            "LockShop failed - already locked",
            { player = username, lockedBy = modData.shopLock }
        )
    end

    -- Perform action
    if setShopLock(obj, username) then
        KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "LockSuccess", args)
        logger:info(
            "LockShop command - success",
            { player = username, shopName = modData.shopName }
        )
    end
end

---@param player IsoPlayer
---@param args table
local function handleUnlockShop(player, args)
    -- In VANILLA mode, ISEntityWindow owns the lock; nothing to clear in modData
    local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
    if lockMethod == 2 then
        logger:debug("handleUnlockShop - VANILLA mode, skip modData clear")
        return
    end

    local square = getSquare(args.x, args.y, args.z)
    if not square then
        return logger:debug("handleUnlockShop - no square", args)
    end

    local obj, modData = getShopObject(square)
    if not obj then
        return logger:debug("handleUnlockShop - no shop", args)
    end

    local username = player:getUsername()

    if clearShopLock(obj, username) then
        KUtilities.SendServerCommandTo(player, "JASM_ShopManager", "UnlockSuccess", args)
        logger:info(
            "UnlockShop command - success",
            { player = username, shopName = modData.shopName }
        )
    else
        logger:debug(
            "handleUnlockShop - redundant/unauthorized",
            { player = username, currentLock = modData.shopLock }
        )
    end
end

---Handle ManageShop command (REGISTER / UNREGISTER)
---@param player IsoPlayer
---@param args table
local function handleManageShop(player, args)
    local square = getSquare(args.x, args.y, args.z)
    if not square then
        logger:debug("handleManageShop - aborting, square is nil", args)
        return
    end

    local objects = square:getObjects()
    if not objects then
        logger:debug("handleManageShop - aborting, objects is nil", args)
        return
    end

    local containerObj = objects:get(args.index)
    if not containerObj or not containerObj:getContainer() then
        logger:debug("handleManageShop - aborting, containerObj or its container is nil", args)
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
        -- logger:debug("OnClientCommand - ignoring module", { module = module })
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
