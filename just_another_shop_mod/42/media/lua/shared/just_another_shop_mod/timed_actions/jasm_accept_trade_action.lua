require("TimedActions/ISBaseTimedAction")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local pz_utils = require("pz_utils_shared")
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")

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
---@param itemType     string
---@param requestItem  string
---@param requestQty   number
---@param offerQty     number
---@param isForceGive  boolean
---@param time         number|nil
---@return JASM_AcceptTradeAction
function JASM_AcceptTradeAction:new(
    character,
    containerObj,
    itemType,
    requestItem,
    requestQty,
    offerQty,
    isForceGive,
    time
)
    local o = ISBaseTimedAction.new(self, character)
    ---@cast o JASM_AcceptTradeAction

    o.character = character
    o.containerObj = containerObj

    if containerObj then
        o.x = containerObj:getX()
        o.y = containerObj:getY()
        o.z = containerObj:getZ()
        o.index = containerObj:getObjectIndex()
    end

    o.itemType = itemType
    o.requestItem = requestItem
    o.requestQty = requestQty or 1
    o.offerQty = offerQty or 1
    o.isForceGive = isForceGive or false

    o.maxTime = time or 30

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
        local isAdmin = pz_utils.konijima.Utilities.IsPlayerAdmin(self.character)
        local adminBypass = JASM_SandboxVars.Get("AdminBypass")

        if not (isAdmin and adminBypass) then
            logger:error("JASM_AcceptTradeAction:complete() - unauthorized force give attempt")
            return false
        end

        for i = 1, self.offerQty do
            local item = shopContainer:getFirstType(self.itemType)

            if item then
                shopContainer:Remove(item)
                sendRemoveItemFromContainer(shopContainer, item)
                playerInv:AddItem(item)
                sendAddItemToContainer(playerInv, item)
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
            local item = playerInv:getFirstType(self.requestItem)

            if item then
                playerInv:Remove(item)
                sendRemoveItemFromContainer(playerInv, item)
                shopContainer:AddItem(item)
                sendAddItemToContainer(shopContainer, item)
            end
        end

        -- Move product from shop to player
        for i = 1, self.offerQty do
            local item = shopContainer:getFirstType(self.itemType)

            if item then
                shopContainer:Remove(item)
                sendRemoveItemFromContainer(shopContainer, item)
                playerInv:AddItem(item)
                sendAddItemToContainer(playerInv, item)
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
