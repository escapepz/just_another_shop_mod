require("TimedActions/ISBaseTimedAction")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

-- ============================================================
-- JASM_PublishTradeAction
-- B42 Networked TimedAction for owner "Publish Trade".
--
-- CLIENT side (per-frame):
--   perform()  -> called after animation/time finishes, CLIENT-ONLY
--
-- SERVER side (authoritative):
--   getDuration() -> returns tick count for the progress bar
--   complete()    -> writes modData + transmitModData()
--
-- NOTE: This file is in shared/ so the class table is visible to
-- both client (queues the action) and server (runs complete()).
-- The class MUST be global and Type MUST match the class name.
-- ============================================================

---@class JASM_PublishTradeAction : ISBaseTimedAction
---@field entity     IsoObject   Shop container object
---@field x          number
---@field y          number
---@field z          number
---@field index      integer     Object index on the square
---@field itemType   string      Full item type string (e.g. "Base.Axe")
---@field trades     table       Array of trade paths [{requestItem, requestQty, name}]
---@field offerQty   integer
local JASM_PublishTradeAction = ISBaseTimedAction:derive("JASM_PublishTradeAction")
JASM_PublishTradeAction.Type = "JASM_PublishTradeAction"

-- Assign to global for the engine's serialization logic (B42 Networking)
_G[JASM_PublishTradeAction.Type] = JASM_PublishTradeAction

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

---@param character  IsoPlayer
---@param entity     IsoObject     The shop IsoObject
---@param payload    table         { x, y, z, index, itemType, trades, offerQty }
---@return JASM_PublishTradeAction
function JASM_PublishTradeAction:new(character, entity, payload)
    local o = ISBaseTimedAction.new(self, character)
    ---@cast o JASM_PublishTradeAction

    o.entity = entity
    o.x = payload.x -- serialised to server via field name matching
    o.y = payload.y
    o.z = payload.z
    o.index = payload.index
    o.itemType = payload.itemType
    o.trades = payload.trades
    o.offerQty = payload.offerQty or 1

    -- Progress bar behaviour
    o.maxTime = 30 -- ~3 s at 10 ticks/s; server can override via getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true

    return o
end

-- ============================================================
-- CLIENT - isValid
-- Called every tick; returning false cancels the action.
-- ============================================================

---@return boolean
function JASM_PublishTradeAction:isValid()
    if not self.entity then
        logger:error("JASM_PublishTradeAction:isValid() - entity is nil")
        return false
    end
    -- Entity must still be in the world
    ---@cast self.entity IsoObject
    local sq = self.entity:getSquare()
    if not sq then
        logger:error("JASM_PublishTradeAction:isValid() - entity has no square")
        return false
    end

    if self.character:DistTo(sq:getX(), sq:getY()) > 3.0 then
        logger:debug("JASM_PublishTradeAction:isValid() - distance check failed")
        return false
    end
    return true
end

-- ============================================================
-- CLIENT - waitToStart
-- Face the shop object before the bar starts.
-- ============================================================

---@return boolean  true = still turning (keep waiting)
function JASM_PublishTradeAction:waitToStart()
    self.character:faceLocation(self.x, self.y)
    return self.character:shouldBeTurning()
end

-- ============================================================
-- CLIENT - start
-- Called once when the action officially begins (bar appears).
-- ============================================================

function JASM_PublishTradeAction:start()
    logger:debug("JASM_PublishTradeAction:start() - itemType=" .. tostring(self.itemType))
end

-- ============================================================
-- CLIENT - update  (called every tick)
-- ============================================================

function JASM_PublishTradeAction:update()
    self.character:faceLocation(self.x, self.y)
end

-- ============================================================
-- CLIENT - perform
-- Called on the CLIENT after the action duration completes,
-- BEFORE complete() runs on the server.
-- Use for client-side visual feedback only.
-- ============================================================

function JASM_PublishTradeAction:perform()
    logger:debug("JASM_PublishTradeAction:perform() - client side complete")
    ISBaseTimedAction.perform(self)
    if self.onCompleteFunc then
        local args = self.onCompleteArgs or {}
        self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end
end

-- ============================================================
-- CLIENT - stop
-- Called when the action is cancelled (player moved, etc.).
-- ============================================================

function JASM_PublishTradeAction:stop()
    logger:debug("JASM_PublishTradeAction:stop() - action cancelled")
    ISBaseTimedAction.stop(self)
    if self.onStopFunc then
        local args = self.onStopArgs or {}
        self.onStopFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end
end

function JASM_PublishTradeAction:setOnComplete(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

function JASM_PublishTradeAction:setOnCancel(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onStopFunc = func
    self.onStopArgs = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

-- ============================================================
-- SERVER - getDuration
-- Returns tick count for the progress bar.
-- 10 ticks ~ 1 second.  Server is authoritative.
-- ============================================================

---@return number
function JASM_PublishTradeAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1 -- instant for cheat/admin
    end
    return 30 -- normal duration
end

-- ============================================================
-- SERVER - complete
-- Called on the server when the action finishes successfully.
-- This is the ONLY place that writes and syncs modData.
-- Fields on self (x, y, z, index, itemType, trades, offerQty)
-- are automatically deserialised from the client payload.
-- ============================================================

---@return boolean
function JASM_PublishTradeAction:complete()
    logger:info("JASM_PublishTradeAction:complete() - SERVER writing modData", {
        itemType = self.itemType,
        tradeCount = self.trades and #self.trades or 0,
    })

    local square = getSquare(self.x, self.y, self.z)
    if not square then
        logger:error(
            "JASM_PublishTradeAction:complete() - square not found at "
                .. tostring(self.x)
                .. ","
                .. tostring(self.y)
                .. ","
                .. tostring(self.z)
        )
        return false
    end

    local containerObj = square:getObjects():get(self.index)
    if not containerObj then
        logger:error(
            "JASM_PublishTradeAction:complete() - object not found at index "
                .. tostring(self.index)
        )
        return false
    end

    -- Ownership check: only the registered shop owner may publish
    local modData = containerObj:getModData()
    if modData.shopOwnerID and modData.shopOwnerID ~= self.character:getUsername() then
        logger:error(
            "JASM_PublishTradeAction:complete() - ownership mismatch: "
                .. tostring(self.character:getUsername())
                .. " vs "
                .. tostring(modData.shopOwnerID)
        )
        return false
    end

    -- Wait... enforce max 5 paths per shopTrades
    local pathCount = self.trades and #self.trades or 0
    if pathCount > 5 then
        logger:error(
            "JASM_PublishTradeAction:complete() - exceeding max 5 paths ("
                .. tostring(pathCount)
                .. ")"
        )
        return false
    end

    -- Write trade data server-side (authoritative write)
    modData.shopTrades = modData.shopTrades or {}
    modData.shopTrades[self.itemType] = {
        offerQty = self.offerQty,
        paths = self.trades,
    }

    -- Sync to ALL clients (broadcasts the updated modData to everyone)
    containerObj:transmitModData()

    logger:info("JASM_PublishTradeAction:complete() - transmitModData sent", {
        shop = modData.shopName,
        item = self.itemType,
        offerQty = self.offerQty,
        paths = pathCount,
    })

    return true
end
