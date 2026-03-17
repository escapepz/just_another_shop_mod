local JASM_CustomerViewWindow = require("just_another_shop_mod/entity_ui/customer_view_window")
local JASM_Constants = require("just_another_shop_mod/jasm_constants")
local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local LootPanelSync = {}
LootPanelSync.lastSelectedContainer = {}

---@param player IsoPlayer
---@param inventory ItemContainer
function LootPanelSync.onLootContainerSelected(player, inventory)
    if not player or not inventory then
        return
    end

    local playerNum = player:getPlayerNum()
    local entity = inventory:getParent()

    -- Filter out no-op changes
    if LootPanelSync.lastSelectedContainer[playerNum] == entity then
        return
    end

    LootPanelSync.lastSelectedContainer[playerNum] = entity

    -- Verify if selected container is a valid JASM shop container
    if not entity or not entity:getModData().isShop then
        return
    end

    local sprite = entity:getSprite()
    if not sprite or not JASM_Constants:isValidShopContainer(sprite:getName()) then
        return
    end

    -- Trigger refresh only if the Customer View is already open
    local instance = JASM_CustomerViewWindow.instance
    if instance and instance:getIsVisible() then
        instance:switchShop(entity)
    end
end

-- 1. Hook into Events.OnRefreshInventoryWindowContainers ("end" phase)
---@param inventoryPage ISInventoryPage
---@param state string
function LootPanelSync.onRefreshLootPanel(inventoryPage, state)
    -- We only care about the "end" phase after refreshBackpacks() has finished
    if state ~= "end" then
        return
    end

    -- Guard: Vanilla TimedActions force container selection, causing infinite switch loops
    -- if we don't ignore forced selections.
    if inventoryPage.forceSelectedContainer then
        return
    end

    local playerObj = getSpecificPlayer(inventoryPage.player)

    -- SECONDARY GUARD: Ignore if player is performing a JASM trade action.
    -- (Safety layer to prevent flickering during trade interactions/animations)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    local currentAction = actionQueue and actionQueue.queue and actionQueue.queue[1]
    if currentAction and currentAction.Type == "JASM_AcceptTradeAction" then
        return
    end

    local inventory = inventoryPage.inventory

    LootPanelSync.onLootContainerSelected(playerObj, inventory)
end

Events.OnRefreshInventoryWindowContainers.Add(LootPanelSync.onRefreshLootPanel)

-- 2. Hook into ISInventoryPage:setNewContainer to capture direct world clicks
local original_setNewContainer = ISInventoryPage.setNewContainer
function ISInventoryPage:setNewContainer(inventory)
    original_setNewContainer(self, inventory)

    -- Guard: Ignore if this page is not the loot panel (onCharacter = true means backpack panel)
    if self.onCharacter then
        return
    end

    local playerObj = getSpecificPlayer(self.player)
    LootPanelSync.onLootContainerSelected(playerObj, inventory)
end

return LootPanelSync
