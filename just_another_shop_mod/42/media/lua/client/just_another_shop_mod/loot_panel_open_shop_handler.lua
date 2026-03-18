require("ISUI/LootWindow/ISLootWindowObjectControlHandler")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities
local JASM_ShopView_Customer = require("just_another_shop_mod/entity_ui/customer_view_window")
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
local JASM_Utils = require("just_another_shop_mod/jasm_utils")
local JASM_Constants = require("just_another_shop_mod/jasm_constants")

local math_floor = math.floor
local math_abs = math.abs

-- ------------------------------------------------
-- Helpers (Local)
-- ------------------------------------------------

local function isInLootPanelRange(player, sq)
    local px = math_floor(player:getX())
    local py = math_floor(player:getY())
    local pz = math_floor(player:getZ())
    if math_abs(px - sq:getX()) > 1 or math_abs(py - sq:getY()) > 1 or pz ~= sq:getZ() then
        return false
    end
    local currentSq = player:getCurrentSquare()
    if currentSq ~= sq and not currentSq:canReachTo(sq) then
        return false
    end
    return true
end

local function refreshLootPanel(playerIndex)
    local pData = getPlayerData(playerIndex)
    if pData then
        pData.lootInventory:refreshBackpacks()
    end
end

local function checkLock(shopOption, containerObj, playerObj)
    local modData = containerObj:getModData()
    local isOwner = playerObj:getUsername() == modData.shopOwnerID
    local isAdmin = KUtilities.IsPlayerAdmin(playerObj)
    local adminBypass = JASM_SandboxVars.Get("AdminBypass")
    local effectivelyAdmin = isAdmin and adminBypass

    local lockHolder = modData.shopLock
    local lockSession = modData.shopLockSessionID
    local currentSession = JASM_Utils.GetSessionID()

    if lockSession ~= currentSession then
        lockHolder = nil
    end

    local isLockedByOther = lockHolder and lockHolder ~= playerObj:getUsername()

    if isLockedByOther and not (isOwner or effectivelyAdmin) then
        shopOption.enable = false
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setName("Shop Occupied")
        tooltip.description = "This shop is currently being used by " .. tostring(lockHolder) .. "."
        shopOption.toolTip = tooltip
    else
        shopOption.enable = true
        shopOption.toolTip = nil
    end
end

local function openShop(containerObj, playerObj)
    local playerIndex = playerObj:getPlayerNum()
    local sq = containerObj:getSquare()

    if isInLootPanelRange(playerObj, sq) then
        refreshLootPanel(playerIndex)
        JASM_ShopView_Customer.open(playerIndex, nil, containerObj)
        return
    end

    local adjacent = AdjacentFreeTileFinder.Find(sq, playerObj)
    if adjacent then
        ISTimedActionQueue.clear(playerObj)
        local action = ISWalkToTimedAction:new(playerObj, adjacent)
        action:setOnComplete(function()
            refreshLootPanel(playerIndex)
            JASM_ShopView_Customer.open(playerIndex, nil, containerObj)
        end)
        ISTimedActionQueue.add(action)
    end
end

-- ------------------------------------------------
-- Handler Class
-- ------------------------------------------------

---@type JASM_LootPanelOpenShopHandler
local JASM_LootPanelOpenShopHandler =
    ISLootWindowObjectControlHandler:derive("JASM_LootPanelOpenShopHandler")
local Handler = JASM_LootPanelOpenShopHandler

function Handler:shouldBeVisible()
    if not self.object then
        return false
    end

    local modData = self.object:getModData()
    if not modData.isShop then
        return false
    end

    local sprite = self.object:getSprite()
    if not sprite then
        return false
    end

    local isShopContainer = JASM_Constants:isValidShopContainer(sprite:getName(), self.object)

    return isShopContainer
end

function Handler:getControl()
    self.control = self:getButtonControl("Open Shop")
    checkLock(self.control, self.object, self.playerObj)
    -- Custom colors:
    -- Golden Yellow (#FFDD00)
    self.control:setBackgroundRGBA(1.0, 0.87, 0.0, 0.3)
    self.control:setBackgroundColorMouseOverRGBA(1.0, 0.87, 0.0, 0.6)
    self.control:setBorderRGBA(1.0, 0.87, 0.0, 0.8)
    self.control.textColor = { r = 1.0, g = 0.96, b = 0.8, a = 1.0 }
    -- Or use the built-in accept/cancel presets:
    -- self.control:enableAcceptColor()
    -- self.control:enableCancelColor()
    return self.control
end

function Handler:perform()
    if isGamePaused() then
        return
    end

    local player = self.playerObj
    if not player then
        return
    end

    if self.control and not self.control.enable then
        return
    end

    openShop(self.object, player)
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    -- o.altColor = true
    return o
end

-- Register handler with Loot Panel
ISLootWindowContainerControls.AddHandler(JASM_LootPanelOpenShopHandler)
