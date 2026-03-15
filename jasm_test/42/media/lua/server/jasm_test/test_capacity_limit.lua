---@diagnostic disable: global-in-non-module
--[[
    AcceptTradeAction Capacity Limit Tests (Exploit Fix)
]]

local JASM_TestRunner = require("jasm_test_shared")

local function init()
    -- Load the real action class
    require("just_another_shop_mod/timed_actions/jasm_accept_trade_action")

    JASM_TestRunner.register("accept_trade_capacity_limit", "server", function()
        -- 1. Mock Globals & Utilities
        local originalGetSquare = _G.getSquare
        local originalSendRemove = _G.sendRemoveItemFromContainer
        local originalSendAdd = _G.sendAddItemToContainer
        local originalSendServerCommand = _G.sendServerCommand

        _G.sendRemoveItemFromContainer = function(container, item) end
        _G.sendAddItemToContainer = function(container, item) end
        _G.sendServerCommand = function(...) end

        local pz_utils = require("pz_utils_shared")
        local originalIsAdmin = pz_utils.konijima.Utilities.IsPlayerAdmin
        pz_utils.konijima.Utilities.IsPlayerAdmin = function()
            return false
        end

        _G.sendAddItemToContainer = function(container, item)
            container:AddItem(item)
        end
        _G.sendRemoveItemFromContainer = function(container, item)
            container:Remove(item)
        end

        -- 2. Mock Inventory & Objects
        local function createItem(type, weight)
            return {
                getFullType = function()
                    return type
                end,
                getActualWeight = function()
                    return weight or 0.1
                end,
                getCategory = function()
                    return "Item"
                end,
                getInventory = function()
                    return nil
                end,
                isContainer = function()
                    return false
                end,
            }
        end

        local function createInventoryMock()
            local inv = {
                items = {},
                capacityWeight = 50.0,
            }
            inv.getCapacityWeight = function()
                return inv:getContentsWeight()
            end
            inv.getItemsFromCategory = function()
                return {
                    size = function()
                        return 0
                    end,
                    get = function(_, i)
                        return nil
                    end,
                }
            end
            inv.getCapacity = function()
                return inv.capacityWeight
            end
            inv.getEffectiveCapacity = function()
                return inv:getCapacity()
            end
            inv.getCountRecurse = function()
                return inv:getItems():size()
            end
            inv.getContentsWeight = function()
                local weight = 0
                for _, it in ipairs(inv.items) do
                    weight = weight + it:getActualWeight()
                end
                return weight
            end
            inv.getInventory = function()
                return inv
            end
            inv.isExplored = function()
                return true
            end
            inv.setExplored = function() end
            inv.getItemCount = function(self, type)
                local count = 0
                for _, it in ipairs(inv.items) do
                    if it:getFullType() == type then
                        count = count + 1
                    end
                end
                return count
            end
            inv.getItems = function()
                return {
                    size = function()
                        return #inv.items
                    end,
                    get = function(_, i)
                        return inv.items[i + 1]
                    end,
                }
            end
            inv.Remove = function(self, it)
                for i, item in ipairs(inv.items) do
                    if item == it then
                        table.remove(inv.items, i)
                        return
                    end
                end
            end
            inv.AddItem = function(self, it)
                table.insert(inv.items, it)
            end
            return inv
        end

        local mockPlayer = {
            getUsername = function()
                return "test_buyer"
            end,
            getInventory = function(self)
                return self.inventory
            end,
            inventory = createInventoryMock(),
        }

        local mockShopContainer = createInventoryMock()

        local mockContainerObj = {
            getContainer = function()
                return mockShopContainer
            end,
            getName = function()
                return "Test Shop"
            end,
            getSquare = function()
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
                }
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
            getObjectIndex = function()
                return 0
            end,
        }

        local mockSquare = {
            getObjects = function()
                return {
                    get = function(self, index)
                        return mockContainerObj
                    end,
                }
            end,
        }
        _G.getSquare = function(x, y, z)
            return mockSquare
        end

        -- 3. Setup Action
        -- Buying 1 Axe (weight 3.0) for 10 Money (weight 0.1 each = 1.0 total)
        local action = JASM_AcceptTradeAction:new(
            ---@diagnostic disable-next-line: param-type-mismatch
            mockPlayer,
            ---@diagnostic disable-next-line: param-type-mismatch
            mockContainerObj,
            "Base.Axe",
            "Base.Money",
            10,
            1,
            false
        )
        action.x = 10
        action.y = 10
        action.z = 0
        action.index = 0

        -- Scenario: Weight Limit - Shop Full
        -- Shop has 50.0 capacity.
        -- Current atoms in shop: 49.0 weight.
        -- Buying 1 Axe (removes 3.0 from shop), giving 10 Heavy Money (adds 10.0 to shop).
        -- Final Result weight: 49.0 - 3.0 + 10.0 = 56.0 (EXCEEDS 50.0) -> FAIL

        mockShopContainer.capacityWeight = 50.0
        mockShopContainer.items = {}
        for i = 1, 46 do
            table.insert(mockShopContainer.items, createItem("Base.Plank", 1.0))
        end -- 46.0 weight
        table.insert(mockShopContainer.items, createItem("Base.Axe", 3.0)) -- 49.0 weight total

        action.requestItem = "Base.HeavyMoney"
        action.requestQty = 10
        mockPlayer.inventory.items = {}
        for i = 1, 10 do
            table.insert(mockPlayer.inventory.items, createItem("Base.HeavyMoney", 1.0))
        end

        local result = action:complete()
        JASM_TestRunner.assert_false(result, "Trade should fail due to weight limit")
        JASM_TestRunner.assert_equals(
            10,
            mockPlayer.inventory:getItemCount("Base.HeavyMoney"),
            "Player should keep money"
        )
        JASM_TestRunner.assert_equals(
            47,
            mockShopContainer:getItems():size(),
            "Shop items count should be same (No atomic movement)"
        )

        -- Scenario: Item Count Limit (500 items)
        -- Shop has 490 items.
        -- Buying 1 item (removes 1), paying 20 items (adds 20).
        -- Final: 490 - 1 + 20 = 509 (EXCEEDS 500)
        action.requestItem = "Base.Money"
        action.requestQty = 20
        mockShopContainer.items = {}
        for i = 1, 489 do
            table.insert(mockShopContainer.items, createItem("Base.Nail", 0.01))
        end
        table.insert(mockShopContainer.items, createItem("Base.Axe", 3.0)) -- 490 items total

        mockPlayer.inventory.items = {}
        for i = 1, 20 do
            table.insert(mockPlayer.inventory.items, createItem("Base.Money", 0.1))
        end

        result = action:complete()
        JASM_TestRunner.assert_false(result, "Trade should fail due to item count limit (500)")

        -- Cleanup
        _G.getSquare = originalGetSquare
        _G.sendRemoveItemFromContainer = originalSendRemove
        _G.sendAddItemToContainer = originalSendAdd
        _G.sendServerCommand = originalSendServerCommand
        if originalIsAdmin then
            pz_utils.konijima.Utilities.IsPlayerAdmin = originalIsAdmin
        else
            -- If original was nil, reload from fresh require
            pz_utils.konijima.Utilities.IsPlayerAdmin =
                require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin
        end
    end)

    print("[JASM_TEST] Capacity Limit tests registered")
end

return init
