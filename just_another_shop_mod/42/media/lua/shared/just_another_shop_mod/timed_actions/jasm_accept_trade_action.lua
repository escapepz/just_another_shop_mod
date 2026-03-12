require("TimedActions/ISBaseTimedAction")

local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local pz_utils = require("pz_utils_shared")
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
local JASM_Constants = require("just_another_shop_mod/jasm_constants")

local KUtilities = pz_utils.konijima.Utilities
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

    if self.character:DistTo(sq:getX(), sq:getY()) > JASM_Constants.SHOP_TRADE_RANGE then
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

    -- 1. IDENTIFY ALL ITEMS (ATOMIC PRE-VALIDATION)

    local currencyItems = {}
    local productItems = {}

    -- Collect product items from shop
    local shopItems = shopContainer:getItems()
    for i = 0, shopItems:size() - 1 do
        local item = shopItems:get(i)
        if item and item:getFullType() == self.itemType then
            table.insert(productItems, item)
            if #productItems >= self.offerQty then
                break
            end
        end
    end

    if #productItems < self.offerQty then
        logger:error("Shop has insufficient stock (Atomic check)", {
            shop = containerObj:getName(),
            required = self.offerQty,
            available = #productItems,
            item = self.itemType,
        })
        -- Send halotext command to player on client
        KUtilities.SendServerCommandTo(
            self.character,
            "JASM_ShopManager",
            "TradeDenied",
            { reason = "insufficient_stock" }
        )
        return false
    end

    -- Collect currency items from player (if not admin force)
    if not self.isForceGive then
        local pItems = playerInv:getItems()
        for i = 0, pItems:size() - 1 do
            local item = pItems:get(i)
            if item and item:getFullType() == self.requestItem then
                table.insert(currencyItems, item)
                if #currencyItems >= self.requestQty then
                    break
                end
            end
        end

        if #currencyItems < self.requestQty then
            logger:error("Player has insufficient funds (Atomic check)", {
                player = self.character:getUsername(),
                required = self.requestQty,
                available = #currencyItems,
                item = self.requestItem,
            })
            -- Send halotext command to player on client
            KUtilities.SendServerCommandTo(
                self.character,
                "JASM_ShopManager",
                "TradeDenied",
                { reason = "insufficient_funds" }
            )
            return false
        end
    end

    -- 1.5 CAPACITY VALIDATION (SERVER AUTHORITATIVE)
    if not self.isForceGive then
        local currentWeight = shopContainer:getContentsWeight()
        local currentItemCount = luautils.countItemsRecursive({ shopContainer })

        local weightToGain = 0
        for _, item in ipairs(currencyItems) do
            weightToGain = weightToGain + item:getActualWeight()
        end

        local weightToLose = 0
        for _, item in ipairs(productItems) do
            weightToLose = weightToLose + item:getActualWeight()
        end

        local finalWeight = currentWeight - weightToLose + weightToGain
        local maxWeight = shopContainer:getEffectiveCapacity(self.character)

        -- Follow vanilla MP ItemNumbersLimitPerContainer + mod safety cap
        local vanillaCap = SandboxVars.ItemNumbersLimitPerContainer or 0
        local ITEM_COUNT_CAP = (vanillaCap > 0) and vanillaCap or JASM_Constants.ITEM_COUNT_CAP

        -- Lag Prevention: Item Count Cap (prevent 10,000+ item exploit)
        local finalCount = currentItemCount - #productItems + #currencyItems

        if finalWeight > maxWeight or finalCount > ITEM_COUNT_CAP then
            local reason = (finalWeight > maxWeight) and "shop_full_weight" or "shop_full_count"
            logger:error("Trade rejected: shop container full (Server check)", {
                player = self.character:getUsername(),
                reason = reason,
                finalWeight = finalWeight,
                maxWeight = maxWeight,
                finalCount = finalCount,
                cap = ITEM_COUNT_CAP,
            })
            -- Send halotext command to player on client
            KUtilities.SendServerCommandTo(
                self.character,
                "JASM_ShopManager",
                "TradeDenied",
                { reason = reason }
            )
            return false
        end
    end

    -- 2. PROCESS TRANSFER (NOW SAFE)

    if self.isForceGive then
        -- Admin check (secondary safety)
        local isAdmin = pz_utils.konijima.Utilities.IsPlayerAdmin(self.character)
        local adminBypass = JASM_SandboxVars.Get("AdminBypass")

        if not (isAdmin and adminBypass) then
            logger:error("JASM_AcceptTradeAction:complete() - unauthorized force give attempt")
            KUtilities.SendServerCommandTo(
                self.character,
                "JASM_ShopManager",
                "TradeDenied",
                { reason = "unauthorized" }
            )
            return false
        end

        logger:info(
            "JASM_AcceptTradeAction:complete() - EXECUTE Force Give",
            { qty = self.offerQty }
        )
    else
        -- Transfer currency from player to shop
        for _, item in ipairs(currencyItems) do
            playerInv:Remove(item)
            sendRemoveItemFromContainer(playerInv, item)
            shopContainer:AddItem(item)
            sendAddItemToContainer(shopContainer, item)
        end
    end

    -- Transfer product from shop to player
    for _, item in ipairs(productItems) do
        shopContainer:Remove(item)
        sendRemoveItemFromContainer(shopContainer, item)
        playerInv:AddItem(item)
        sendAddItemToContainer(playerInv, item)
    end

    logger:info("JASM_AcceptTradeAction:complete() - Success", {
        item = self.itemType,
        qty = self.offerQty,
        price = (not self.isForceGive) and (self.requestQty .. "x " .. self.requestItem)
            or "FORCED",
    })

    -- Trigger UI refresh callback (Issue 5)
    if self.onCompleteFunc then
        local args = self.onCompleteArgs or {}
        self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
    end

    return true
end
