---@diagnostic disable: param-type-mismatch
local JASM_TestRunner = require("jasm_test_shared")

-- ============================================================
-- TEST: Context Menu
-- ============================================================
JASM_TestRunner.register("player_actions_context_menu_uses_walkToContainer", "client", function()
    -- 1. Setup Tracking for walkToContainer (Save original)
    local originalWalkToContainer = luautils.walkToContainer
    local walkToContainerCalled = false
    local calledContainer = nil
    local calledPlayerIndex = nil

    luautils.walkToContainer = function(container, playerIndex)
        walkToContainerCalled = true
        calledContainer = container
        calledPlayerIndex = playerIndex
        return true
    end

    -- 2. Mock objects
    local DoShopContextMenu = require("just_another_shop_mod/shop_context_menu")
    local playerIndex = 0
    local context = {
        options = {},
        addOption = function(self, name, target, onSelect, ...)
            local opt = { name = name, target = target, onSelect = onSelect, args = { ... } }
            table.insert(self.options, opt)
            return opt
        end,
        addSubMenu = function(self, option, menu) end,
        getNew = function(self)
            return self
        end,
    }

    -- We need to mock a real-ish IsoObject for the context menu check
    local mockContainer = { type = "MockContainer" }
    local containerObj = {
        getContainer = function()
            return mockContainer
        end,
        getObjectName = function()
            return "Thumpable"
        end,
        getEntityFullTypeDebug = function()
            return "Base.Wood_Crate_Lvl1"
        end,
        getEntityDisplayName = function()
            return "Wood Crate"
        end,
        getModData = function()
            return { isShop = true }
        end,
        getSquare = function()
            return {}
        end,
        getObjectIndex = function()
            return 0
        end,
        getX = function()
            return 0
        end,
        getY = function()
            return 0
        end,
        getZ = function()
            return 0
        end,
    }

    local worldObjects = { containerObj }
    ---@cast context ISContextMenu
    ---@cast worldObjects IsoObject[]

    -- 3. Trigger context menu fill
    DoShopContextMenu(playerIndex, context, worldObjects, false)

    -- 4. Find and trigger "Open Shop UI"
    local openShopOpt = nil
    for _, opt in ipairs(context.options) do
        if opt.name == "Open Shop UI" then
            openShopOpt = opt
            break
        end
    end

    JASM_TestRunner.assert_not_nil(openShopOpt, "Should have 'Open Shop UI' option")
    ---@diagnostic disable-next-line: unnecessary-if
    if openShopOpt then
        openShopOpt.onSelect()
    end

    -- Verify and cleanup
    local success = walkToContainerCalled
    local correctParams = (
        calledContainer == containerObj:getContainer() and calledPlayerIndex == playerIndex
    )

    luautils.walkToContainer = originalWalkToContainer

    JASM_TestRunner.assert_true(success, "walkToContainer should have been called")
    JASM_TestRunner.assert_true(
        correctParams,
        "Should be called with correct container and player index"
    )
end)

-- ============================================================
-- TEST: ShopItemDetailsPanel
-- ============================================================
JASM_TestRunner.register("player_actions_details_panel_uses_walkToContainer", "client", function()
    -- 1. Setup Tracking
    local originalWalkToContainer = luautils.walkToContainer
    local walkToContainerCalled = false
    luautils.walkToContainer = function(container, playerNum)
        walkToContainerCalled = true
        return true
    end

    -- 2. Mocking ShopItemDetailsPanel dependencies
    local ShopItemDetailsPanel =
        require("jasm/entity_ui/components/shop/customer/shop_item_details_panel")

    local player = {
        getPlayerNum = function()
            return 42
        end,
    }

    local entity = {
        getContainer = function()
            return { type = "MockContainer" }
        end,
        getSquare = function()
            return {}
        end,
        getModData = function()
            return { shopTrades = {} }
        end,
    }

    -- We instantiate with minimal state
    ---@type ShopItemDetailsPanel
    local panel = ShopItemDetailsPanel:new(0, 0, 800, 600, player, {})
    ---@cast panel table
    panel.entity = entity
    panel.product = { type = "Base.Axe", offerQty = 1 }
    panel.requirementsPanel = {
        getSelectedTrade = function()
            return { requestItem = "Base.Money", requestQty = 10 }
        end,
    }

    -- 3. Trigger Action
    ---@cast panel ShopItemDetailsPanel
    panel:onAcceptTrade()

    -- Cleanup and verify
    luautils.walkToContainer = originalWalkToContainer
    JASM_TestRunner.assert_true(
        walkToContainerCalled,
        "walkToContainer should have been called in onAcceptTrade"
    )
end)

print("[JASM_TEST] Player Actions tests registered")
