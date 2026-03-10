local ZUL = require("zul")

local logger = ZUL.new("just_another_shop_mod")
-- logger:setLevel("TRACE")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")

---@param ctx CAF.Context
local RuleShopProtection = function(ctx)
    local srcContainer = ctx.src
    local player = ctx.character
    local item = ctx.item

    -- 1. Check if the source is a Shop
    local parent = srcContainer:getParent()

    logger:debug("parent=", parent)

    local modData = parent and parent:getModData() or nil
    if modData and modData.isShop then
        local ownerID = modData.shopOwnerID
        local playerUsername = player:getUsername()
        -- Rule: Lock Check
        -- If shop is locked by another player, NOBODY can modify inventory
        local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
        local lockHolder = nil

        if lockMethod == 1 then
            -- DUAL mode: JASM modData lock is authoritative
            local globalModData = ModData.getOrCreate("JASM_ServerSession")
            local currentSession = globalModData and globalModData.id

            if modData.shopLockSessionID and modData.shopLockSessionID == currentSession then
                lockHolder = modData.shopLock
            else
                lockHolder = nil -- stale lock from previous server crash
            end
        elseif lockMethod == 2 then
            -- VANILLA mode: entity usage is authoritative
            -- Note: getUsingPlayer is technically from GameEntity/Component in B42, duck-typed here
            local entityUser = parent:getUsingPlayer()
            if entityUser then
                lockHolder = entityUser:getUsername()
            end
        end

        if lockHolder and lockHolder ~= playerUsername then
            -- STRICT LOCK: If locked by someone else, NOBODY can remove items (Source check).
            -- This prevents the owner from stealing items while a customer is browsing (Issue 1).
            -- Block customer AND owner from withdrawing when shop locked
            -- Lock holder can PURCHASE (trade) but not directly grab/drop items
            -- Owner can DEPOSIT (restock) but not withdraw
            ctx.flags.rejected = true
            ctx.flags.reason = "Shop is locked by " .. tostring(lockHolder) .. "."
            -- ctx.callbacks = ctx.callbacks or {}
            -- ctx.callbacks.onRejected = function()
            HaloTextHelper.addBadText(getSpecificPlayer(0), ctx.flags.reason)
            -- end
            logger:info("Shop locked - removal denied", {
                player = playerUsername,
                lockedBy = lockHolder,
                shop = modData.shopName,
            })
            return
        end

        -- Rule: Owners can take anything (only if not locked)
        if playerUsername == ownerID and not lockHolder then
            logger:debug("Owner access granted (Source)", {
                player = player:getUsername(),
                shop = modData.shopName,
            })
            return -- No rejection
        end

        -- Rule: Admin bypass (check sandbox option)
        local adminBypass = JASM_SandboxVars.Get("AdminBypass")
        if adminBypass and KUtilities.IsPlayerAdmin(player) then
            logger:info("Admin bypass access (Source)", {
                player = player:getUsername(),
                item = item:getFullType(),
            })
            return -- No rejection
        end

        -- Rule: Allow if trade is authorized
        if ctx.flags.tradeAuthorized then
            return
        end

        -- Rule: Customers are blocked
        ctx.flags.rejected = true
        ctx.flags.reason = "This item must be purchased."
        -- ctx.callbacks = ctx.callbacks or {}
        -- ctx.callbacks.onRejected = function()
        HaloTextHelper.addBadText(getSpecificPlayer(0), ctx.flags.reason)
        -- end

        logger:info("Purchase required", {
            player = player:getUsername(),
            item = item:getFullType(),
            shop = modData.shopName,
        })
        return
    end

    -- 2. Check if the destination is a Shop (Deposit)
    local destContainer = ctx.dest
    local destParent = destContainer and destContainer:getParent() or nil
    local destModData = destParent and destParent:getModData() or nil

    local function restock_check(isOwner, isAdmin, lockHolder)
        if isOwner or isAdmin then
            return
        end

        ctx.flags.rejected = true
        ctx.flags.reason = "Shop is locked by " .. tostring(lockHolder) .. "."
        -- ctx.callbacks = ctx.callbacks or {}
        -- ctx.callbacks.onRejected = function()
        HaloTextHelper.addBadText(getSpecificPlayer(0), ctx.flags.reason)
        -- end
    end

    if destModData and destModData.isShop then
        local ownerID = destModData.shopOwnerID
        local playerUsername = player:getUsername()

        -- Rule: Lock Check (Destination)
        local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
        local lockHolder = nil

        if lockMethod == 1 then
            -- DUAL mode: JASM modData lock is authoritative
            local globalModData = ModData.getOrCreate("JASM_ServerSession")
            local currentSession = globalModData and globalModData.id

            if
                destModData.shopLockSessionID
                and destModData.shopLockSessionID == currentSession
            then
                lockHolder = destModData.shopLock
            else
                lockHolder = nil -- stale lock from previous server crash
            end
        elseif lockMethod == 2 then
            -- VANILLA mode: entity usage is authoritative
            -- Note: getUsingPlayer is technically from GameEntity/Component in B42, duck-typed here
            local entityUser = destParent and destParent:getUsingPlayer()
            if entityUser then
                lockHolder = entityUser:getUsername()
            end
        end

        -- If locked by someone else, verify if owner/admin can still restock
        if lockHolder and lockHolder ~= playerUsername then
            local adminBypass = JASM_SandboxVars.Get("AdminBypass")
            local isOwner = playerUsername == ownerID
            local isAdmin = adminBypass and KUtilities.IsPlayerAdmin(player)

            -- Even if locked, we allow the owner/admin to "give" (restock) items.
            restock_check(isOwner, isAdmin, lockHolder)
        end

        if ctx.flags.rejected then
            return
        end

        -- Rule: Owners can deposit anything
        if playerUsername == ownerID then
            logger:debug("Owner access granted (Destination)", {
                player = player:getUsername(),
                shop = destModData.shopName,
            })
            return -- No rejection
        end

        -- Rule: Admin bypass
        local adminBypass = JASM_SandboxVars.Get("AdminBypass")
        if adminBypass and KUtilities.IsPlayerAdmin(player) then
            logger:info("Admin bypass access (Destination)", {
                player = player:getUsername(),
                item = item:getFullType(),
            })
            return -- No rejection
        end

        -- Rule: Non-owners cannot deposit items
        ctx.flags.rejected = true
        ctx.flags.reason = "Only the shop owner can deposit items."
        -- ctx.callbacks = ctx.callbacks or {}
        -- ctx.callbacks.onRejected = function()
        HaloTextHelper.addBadText(getSpecificPlayer(0), ctx.flags.reason)
        -- end

        logger:info("Deposit rejected: non-owner", {
            player = player:getUsername(),
            item = item:getFullType(),
            shop = destModData.shopName,
        })
    end
end

return RuleShopProtection
