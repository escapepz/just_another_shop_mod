require("TimedActions/ISBaseTimedAction")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local pz_utils = require("pz_utils_shared")

-- ============================================================
-- JASM_AcceptTradeAction
-- B42 Networked TimedAction for customer "Accept Trade".
--
-- CLIENT side (per-frame):
--   perform()  -> called after animation/time finishes, CLIENT-ONLY
--
-- SERVER side (authoritative):
--   getDuration() -> returns tick count for the progress bar
--   complete()    -> processes inventory exchange
--
-- NOTE: This handles the duration/animation for the buyer.
-- The class MUST be global and Type MUST match the class name.
-- ============================================================

---@class JASM_AcceptTradeAction : ISBaseTimedAction
---@field character    IsoPlayer
---@field containerObj IsoObject
---@field x            number
---@field y            number
---@field z            number
---@field index        integer
---@field itemType     string
---@field requestItem  string
---@field requestQty   number
---@field offerQty     number
---@field isForceGive  boolean
JASM_AcceptTradeAction = ISBaseTimedAction:derive("JASM_AcceptTradeAction")
JASM_AcceptTradeAction.Type = "JASM_AcceptTradeAction"

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

---@param character    IsoPlayer
---@param containerObj IsoObject
---@param payload      table       { itemType, requestItem, requestQty, isForceGive, [time] }
---@return JASM_AcceptTradeAction
function JASM_AcceptTradeAction:new(character, containerObj, payload)
    local o = ISBaseTimedAction.new(self, character)
    ---@cast o JASM_AcceptTradeAction

    o.character = character
    o.containerObj = containerObj
    o.x = containerObj:getX()
    o.y = containerObj:getY()
    o.z = containerObj:getZ()
    o.index = containerObj:getObjectIndex()

    o.itemType = payload.itemType
    o.requestItem = payload.requestItem
    o.requestQty = payload.requestQty or 1
    o.offerQty = payload.offerQty or 1
    o.isForceGive = payload.isForceGive or false

    o.maxTime = payload.time or 30

    -- Standard properties from B42 TimedAction Guide
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true

    return o
end

-- ============================================================
-- CLIENT - isValid
-- ============================================================

---@return boolean
function JASM_AcceptTradeAction:isValid()
    if self.isForceGive then
        return true -- Admin bypass
    end

    -- Check if container is still valid and close
    if not self.containerObj or not self.containerObj:getContainer() then
        return false
    end

    local sq = self.containerObj:getSquare()
    if not sq then
        return false
    end

    ---@diagnostic disable-next-line: undefined-field
    if self.character:DistTo(sq:getX(), sq:getY()) > 3.0 then
        logger:debug("JASM_AcceptTradeAction:isValid() - distance check failed")
        return false
    end

    -- Verify player still has required items to trade
    local playerInv = self.character:getInventory()
    local hasEnough = playerInv:getItemCount(self.requestItem) >= self.requestQty

    return hasEnough
end

-- ============================================================
-- CLIENT - waitToStart
-- ============================================================

---@return boolean
function JASM_AcceptTradeAction:waitToStart()
    self.character:faceThisObject(self.containerObj)
    return self.character:shouldBeTurning()
end

-- ============================================================
-- CLIENT - start
-- ============================================================

function JASM_AcceptTradeAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
end

-- ============================================================
-- CLIENT - update
-- ============================================================

function JASM_AcceptTradeAction:update()
    self.character:faceThisObject(self.containerObj)
end

-- ============================================================
-- CLIENT - perform
-- ============================================================

function JASM_AcceptTradeAction:perform()
    logger:debug("JASM_AcceptTradeAction:perform() - client side complete")
    ISBaseTimedAction.perform(self)
    if self.onCompleteFunc then
        local args = self.onCompleteArgs or {}
        self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end
end

-- ============================================================
-- CLIENT - stop
-- ============================================================

function JASM_AcceptTradeAction:stop()
    logger:debug("JASM_AcceptTradeAction:stop() - action cancelled")
    ISBaseTimedAction.stop(self)
    if self.onStopFunc then
        local args = self.onStopArgs or {}
        self.onStopFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end
end

-- Helpers for callbacks exactly like Publish
function JASM_AcceptTradeAction:setOnComplete(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

function JASM_AcceptTradeAction:setOnCancel(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    self.onStopFunc = func
    self.onStopArgs = { arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 }
end

-- ============================================================
-- SERVER - getDuration
-- ============================================================

---@return number
function JASM_AcceptTradeAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 30
end

-- ============================================================
-- SERVER - complete
-- ============================================================

---@return boolean
function JASM_AcceptTradeAction:complete()
    logger:info("JASM_AcceptTradeAction:complete() - SERVER processing inventory", {
        itemType = self.itemType,
        offerQty = self.offerQty,
        player = self.character:getUsername(),
        force = self.isForceGive,
    })

    local square = getSquare(self.x, self.y, self.z)
    if not square then
        logger:error("JASM_AcceptTradeAction:complete() - square not found")
        return false
    end

    local containerObj = square:getObjects():get(self.index)
    ---@cast containerObj IsoObject
    if not containerObj or not containerObj:getContainer() then
        logger:error("JASM_AcceptTradeAction:complete() - container not found")
        return false
    end

    local shopContainer = containerObj:getContainer()
    local playerInv = self.character:getInventory()

    -- 1. Check shop stock
    local product = shopContainer:getFirstType(self.itemType)
    if not product then
        logger:error(
            "JASM_AcceptTradeAction:complete() - item out of stock",
            { item = self.itemType }
        )
        return false
    end

    -- 2. Process logic based on mode
    if self.isForceGive then
        -- Admin check (secondary safety)
        if not pz_utils.konijima.Utilities.IsPlayerAdmin(self.character) then
            logger:error("JASM_AcceptTradeAction:complete() - unauthorized force give attempt")
            return false
        end

        for i = 1, self.offerQty do
            local item = shopContainer:getFirstType(self.itemType)
            ---@diagnostic disable-next-line: unnecessary-if
            if item then
                shopContainer:Remove(item)
                playerInv:AddItem(item)
            end
        end
        logger:info(
            "JASM_AcceptTradeAction:complete() - Force Give Success",
            { qty = self.offerQty }
        )
    else
        -- 3. Trade logic
        local playerFunds = playerInv:getItemCount(self.requestItem)
        if playerFunds < self.requestQty then
            logger:error("JASM_AcceptTradeAction:complete() - insufficient funds", {
                has = playerFunds,
                needs = self.requestQty,
            })
            return false
        end

        -- Move currency from player to shop
        for i = 1, self.requestQty do
            playerInv:RemoveOneOf(self.requestItem)
            shopContainer:AddItem(self.requestItem)
        end

        -- Move product from shop to player
        for i = 1, self.offerQty do
            local item = shopContainer:getFirstType(self.itemType)
            ---@diagnostic disable-next-line: unnecessary-if
            if item then
                shopContainer:Remove(item)
                playerInv:AddItem(item)
            end
        end

        logger:info("JASM_AcceptTradeAction:complete() - Trade Success", {
            item = self.itemType,
            qty = self.offerQty,
            price = self.requestQty .. "x " .. self.requestItem,
        })
    end

    return true
end
