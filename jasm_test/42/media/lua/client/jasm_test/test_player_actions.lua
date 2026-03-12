---@diagnostic disable: undefined-field, global-in-non-module
local JASM_TestRunner = require("jasm_test_shared")

-- Mock game runtime globals needed for CAF rules
_G.HaloTextHelper = _G.HaloTextHelper or {
    addBadText = function() end,
}
_G.getSpecificPlayer = _G.getSpecificPlayer or function()
    return {}
end
_G.ModData = _G.ModData or {
    getOrCreate = function(key)
        return {}
    end,
}

local function init()
    -- ============================================================
    -- TEST: Context Menu
    -- ============================================================
    JASM_TestRunner.register(
        "player_actions_context_menu_uses_walkToContainer",
        "client",
        function()
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

            -- Mock UI to avoid instantiation during tests (BEFORE requiring shop_context_menu)
            local JASM_ShopView_Customer =
                require("just_another_shop_mod/entity_ui/customer_view_window")
            local originalCustomerOpen = JASM_ShopView_Customer.open
            local customerOpenCalled = false
            local calledEntity = nil
            ---@diagnostic disable-next-line: duplicate-set-field
            JASM_ShopView_Customer.open = function(playerIdx, _, entity)
                customerOpenCalled = true
                calledPlayerIndex = playerIdx
                calledEntity = entity
            end

            local JASM_ShopView_Owner = require("just_another_shop_mod/entity_ui/owner_view_window")
            local originalOwnerOpen = JASM_ShopView_Owner.open
            ---@diagnostic disable-next-line: duplicate-set-field
            JASM_ShopView_Owner.open = function() end

            -- 2. Mock objects (Fully isolated to avoid vanilla in-game side effects)
            local DoShopContextMenu = require("just_another_shop_mod/shop_context_menu")
            local playerIndex = 0

            -- Mock player globals required by DoShopContextMenu
            local mockPlayer = {
                getUsername = function()
                    return "testuser"
                end,
                getX = function()
                    return 10
                end,
                getY = function()
                    return 10
                end,
                getZ = function()
                    return 0
                end,
                getCurrentSquare = function()
                    return {
                        getX = function()
                            return 10
                        end,
                        getY = function()
                            return 10
                        end,
                        getZ = function()
                            return 0
                        end,
                        canReachTo = function()
                            return true
                        end,
                    }
                end,
                DistTo = function(self, x, y)
                    return 0 -- Already in range
                end,
            }
            local original_getSpecificPlayer = _G.getSpecificPlayer
            ---@diagnostic disable-next-line: global-in-non-module
            _G.getSpecificPlayer = function()
                return mockPlayer
            end

            local pz_utils = require("pz_utils_shared")
            local original_IsPlayerAdmin = pz_utils.konijima.Utilities.IsPlayerAdmin
            pz_utils.konijima.Utilities.IsPlayerAdmin = function()
                return false
            end

            -- Mock getPlayerData
            local original_getPlayerData = _G.getPlayerData
            _G.getPlayerData = function(playerIdx)
                return {
                    lootInventory = {
                        refreshBackpacks = function() end,
                    },
                }
            end

            -- Mock JASM_ShopManager for lock check
            local originalShopManager = _G.JASM_ShopManager
            _G.JASM_ShopManager = {
                getShopLock = function()
                    return nil
                end,
            }

            -- Pure mock queue to prevent action execution in-game
            local originalQueueAdd = ISTimedActionQueue.add
            local originalQueueClear = ISTimedActionQueue.clear
            ISTimedActionQueue.add = function(action)
                ---@cast action ISBaseTimedAction
                if action and action.onCompleteFunc then
                    local args = action.onCompleteArgs or {}
                    action.onCompleteFunc(
                        args[1],
                        args[2],
                        args[3],
                        args[4],
                        args[5],
                        args[6],
                        args[7],
                        args[8]
                    )
                end
            end
            ISTimedActionQueue.clear = function(character) end

            -- Mock AdjacentFreeTileFinder to avoid passing Lua mocks to Java
            local originalFind = AdjacentFreeTileFinder.Find
            local originalIsTileOrAdjacent = AdjacentFreeTileFinder.isTileOrAdjacent
            AdjacentFreeTileFinder.Find = function(sq, player)
                return sq
            end
            AdjacentFreeTileFinder.isTileOrAdjacent = function(sq1, sq2)
                return false -- Force walk for testing openShop callback
            end

            -- Pure mock context to avoid ISPlayerData dependency in-game
            local optionsAdded = {}

            local context = {
                player = playerIndex,
                addOption = function(self, name, target, onSelect, ...)
                    local opt =
                        { name = name, target = target, onSelect = onSelect, args = { ... } }
                    table.insert(optionsAdded, opt)
                    return opt
                end,
                addSubMenu = function(self, option, menu) end,
                getNew = function(self, context)
                    return self
                end,
            }

            -- We need to mock a real-ish IsoObject for the context menu check
            local mockContainer = { type = "MockContainer" }

            -- FIX: Properly define all properties/methods on mock container
            mockContainer.getContainer = function()
                return mockContainer
            end
            mockContainer.getObjectIndex = function()
                return 0
            end
            mockContainer.getX = function()
                return 0
            end
            mockContainer.getY = function()
                return 0
            end
            mockContainer.getZ = function()
                return 0
            end

            local containerObj = {
                type = "MockContainer",
                getContainer = function()
                    return mockContainer
                end,
                getModData = function()
                    return { isShop = true, shopType = "PLAYER", shopOwnerID = "testuser" }
                end,
                getObjectName = function()
                    return "Thumpable"
                end,
                getEntityDisplayName = function()
                    return "Wood Crate"
                end,
                getEntityFullTypeDebug = function()
                    return "Base.Wood_Crate_Lvl1"
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
                getSprite = function()
                    return {
                        getName = function()
                            return "constructedobjects_01_44"
                        end,
                    }
                end,
                getSquare = function()
                    return {
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
                end,
            }

            local worldObjects = { containerObj }
            ---@cast worldObjects IsoObject[]
            ---@cast context ISContextMenu

            -- 3. Trigger context menu fill
            local originalGetNew = ISContextMenu.getNew
            ISContextMenu.getNew = function(self, ctx)
                return context
            end

            DoShopContextMenu(playerIndex, context, worldObjects, false)

            ISContextMenu.getNew = originalGetNew

            -- 4. Find and trigger "Open Shop UI"
            local openShopOpt = nil
            for _, opt in ipairs(optionsAdded) do
                if opt.name == "Open Shop UI" then
                    openShopOpt = opt
                    break
                end
            end

            JASM_TestRunner.assert_not_nil(openShopOpt, "Should have 'Open Shop UI' option")

            if openShopOpt then
                openShopOpt.onSelect()
            end

            -- Verify and cleanup
            local success = customerOpenCalled
            -- print("calledPlayerIndex: ", calledPlayerIndex, "expected: ", playerIndex)
            -- print("calledEntity: ", calledEntity, "expected: ", containerObj)
            local correctParams = (
                calledEntity == containerObj and calledPlayerIndex == playerIndex
            )

            luautils.walkToContainer = originalWalkToContainer
            ISTimedActionQueue.add = originalQueueAdd
            ISTimedActionQueue.clear = originalQueueClear
            AdjacentFreeTileFinder.Find = originalFind
            AdjacentFreeTileFinder.isTileOrAdjacent = originalIsTileOrAdjacent
            _G.getSpecificPlayer = original_getSpecificPlayer
            _G.getPlayerData = original_getPlayerData
            pz_utils.konijima.Utilities.IsPlayerAdmin = original_IsPlayerAdmin
            _G.JASM_ShopManager = originalShopManager
            ---@diagnostic disable-next-line: duplicate-set-field
            JASM_ShopView_Customer.open = originalCustomerOpen
            ---@diagnostic disable-next-line: duplicate-set-field
            JASM_ShopView_Owner.open = originalOwnerOpen

            JASM_TestRunner.assert_true(
                success,
                "JASM_ShopView_Customer.open should have been called"
            )
            JASM_TestRunner.assert_true(
                correctParams,
                "Should be called with correct entity and player index"
            )
        end
    )

    -- ============================================================
    -- TEST: ShopItemDetailsPanel
    -- ============================================================
    JASM_TestRunner.register(
        "player_actions_details_panel_uses_walkToContainer",
        "client",
        function()
            -- 1. Setup Tracking
            local originalWalkToContainer = luautils.walkToContainer
            local originalQueueAdd = ISTimedActionQueue.add
            local originalQueueClear = ISTimedActionQueue.clear
            local walkToContainerCalled = false
            luautils.walkToContainer = function(container, playerNum)
                walkToContainerCalled = true
                return true
            end
            ISTimedActionQueue.add = function(action)
                ---@cast action ISBaseTimedAction
                if action and action.onCompleteFunc then
                    local args = action.onCompleteArgs or {}
                    action.onCompleteFunc(
                        args[1],
                        args[2],
                        args[3],
                        args[4],
                        args[5],
                        args[6],
                        args[7],
                        args[8]
                    )
                end
            end
            ISTimedActionQueue.clear = function(character) end

            local originalFind = AdjacentFreeTileFinder.Find
            AdjacentFreeTileFinder.Find = function(sq, player)
                return sq
            end

            -- 2. Mocking ShopItemDetailsPanel dependencies
            local ShopItemDetailsPanel = require(
                "just_another_shop_mod/entity_ui/components/shop/customer/shop_item_details_panel"
            )

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
                    return {
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
                end,
                getModData = function()
                    return { shopTrades = {} }
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
                getObjectIndex = function()
                    return 0
                end,
            }

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
            ISTimedActionQueue.add = originalQueueAdd
            ISTimedActionQueue.clear = originalQueueClear
            AdjacentFreeTileFinder.Find = originalFind
            JASM_TestRunner.assert_true(
                walkToContainerCalled,
                "walkToContainer should have been called in onAcceptTrade"
            )
        end
    )

    print("[JASM_TEST] Player Actions tests registered")
end

return init
