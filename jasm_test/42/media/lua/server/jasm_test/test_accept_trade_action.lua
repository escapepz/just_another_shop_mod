---@diagnostic disable: global-in-non-module
--[[
    AcceptTradeAction Atomicity Tests
]]

local JASM_TestRunner = require("jasm_test_shared")

local function init()
    -- Load the real action class to overwrite the mock from mock_pz.lua
    require("just_another_shop_mod/timed_actions/jasm_accept_trade_action")

    JASM_TestRunner.register("accept_trade_atomicity", "server", function()
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

        -- 2. Mock JASM_AcceptTradeAction dependencies
        -- (Already loaded in the test environment usually)

        -- 3. Create Mock Objects
        local function createInventoryMock()
            return {
                items = {},
                capacityWeight = 50.0,
                getCapacityWeight = function(self)
                    return self.capacityWeight
                end,
                getContentsWeight = function(self)
                    local weight = 0
                    for _, it in ipairs(self.items) do
                        if it.getActualWeight then
                            weight = weight + it:getActualWeight()
                        else
                            weight = weight + (it.weight or 0.1)
                        end
                    end
                    return weight
                end,
                getItemCount = function(self, type)
                    local count = 0
                    for _, it in ipairs(self.items) do
                        if it:getFullType() == type then
                            count = count + 1
                        end
                    end
                    return count
                end,
                getFirstType = function(self, type)
                    for i, it in ipairs(self.items) do
                        if it:getFullType() == type then
                            return it
                        end
                    end
                    return nil
                end,
                Remove = function(self, it)
                    for i, item in ipairs(self.items) do
                        if item == it then
                            table.remove(self.items, i)
                            return
                        end
                    end
                end,
                AddItem = function(self, it)
                    table.insert(self.items, it)
                end,
                getItems = function(self)
                    local _items = self.items
                    return {
                        size = function()
                            return #_items
                        end,
                        get = function(_, i)
                            return _items[i + 1]
                        end,
                    }
                end,
            }
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

        -- 4. Setup Items helper
        local function createItem(type, weight)
            return {
                getFullType = function()
                    return type
                end,
                getActualWeight = function()
                    return weight or 0.1
                end,
            }
        end

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
        action.x = 0
        action.y = 0
        action.z = 0
        action.index = 0

        -- Scenario 1: Insufficient funds
        mockPlayer.inventory.items = {}
        for i = 1, 5 do
            table.insert(mockShopContainer.items, createItem("Base.Axe"))
        end

        local result = action:complete()
        JASM_TestRunner.assert_false(result, "Trade should fail due to insufficient funds")
        JASM_TestRunner.assert_equals(
            5,
            mockShopContainer:getItemCount("Base.Axe"),
            "Shop should still have 5 axes"
        )

        -- Scenario 2: Insufficient shop stock
        mockPlayer.inventory.items = {}
        for i = 1, 10 do
            table.insert(mockPlayer.inventory.items, createItem("Base.Money"))
        end
        mockShopContainer.items = {} -- Out of stock

        result = action:complete()
        JASM_TestRunner.assert_false(result, "Trade should fail due to insufficient shop stock")
        JASM_TestRunner.assert_equals(
            10,
            mockPlayer.inventory:getItemCount("Base.Money"),
            "Player should still have 10 money"
        )

        -- Scenario 3: Successful Trade
        mockPlayer.inventory.items = {}
        for i = 1, 10 do
            table.insert(mockPlayer.inventory.items, createItem("Base.Money"))
        end
        mockShopContainer.items = {}
        for i = 1, 5 do
            table.insert(mockShopContainer.items, createItem("Base.Axe"))
        end

        result = action:complete()
        JASM_TestRunner.assert_true(result, "Trade should succeed")
        JASM_TestRunner.assert_equals(
            0,
            mockPlayer.inventory:getItemCount("Base.Money"),
            "Player should have 0 money"
        )
        JASM_TestRunner.assert_equals(
            10,
            mockShopContainer:getItemCount("Base.Money"),
            "Shop should have 10 money"
        )
        JASM_TestRunner.assert_equals(
            4,
            mockShopContainer:getItemCount("Base.Axe"),
            "Shop should have 4 axes remaining"
        )
        JASM_TestRunner.assert_equals(
            1,
            mockPlayer.inventory:getItemCount("Base.Axe"),
            "Player should have 1 axe"
        )

        -- Scenario 4: Atomicity (Currency vanishes mid-discovery)
        mockPlayer.inventory.items = {}
        for i = 1, 10 do
            table.insert(mockPlayer.inventory.items, createItem("Base.Money"))
        end
        mockShopContainer.items = {}
        for i = 1, 5 do
            table.insert(mockShopContainer.items, createItem("Base.Axe"))
        end

        local originalGetItems = mockPlayer.inventory.getItems
        mockPlayer.inventory.getItems = function(self)
            local items = originalGetItems(self)
            local _items = self.items
            return {
                size = function()
                    return #_items
                end,
                get = function(self2, i)
                    if i == 4 then
                        return nil
                    end -- Fails on 5th item
                    return _items[i + 1]
                end,
            }
        end

        result = action:complete()
        JASM_TestRunner.assert_false(result, "Trade should fail during pre-validation")
        JASM_TestRunner.assert_equals(
            10,
            mockPlayer.inventory:getItemCount("Base.Money"),
            "Player should still have 10 money (No items should be moved if pre-validation fails)"
        )
        JASM_TestRunner.assert_equals(
            0,
            mockPlayer.inventory:getItemCount("Base.Axe"),
            "Player should NOT have received any axes"
        )
        JASM_TestRunner.assert_equals(
            5,
            mockShopContainer:getItemCount("Base.Axe"),
            "Shop should still have all axes"
        )

        -- Cleanup
        mockPlayer.inventory.getItems = originalGetItems
        ---@diagnostic disable-next-line: assign-type-mismatch
        _G.getSquare = originalGetSquare
        _G.sendRemoveItemFromContainer = originalSendRemove
        _G.sendAddItemToContainer = originalSendAdd
        _G.sendServerCommand = originalSendServerCommand
        pz_utils.konijima.Utilities.IsPlayerAdmin = originalIsAdmin
    end)

    print("[JASM_TEST] AcceptTradeAction tests registered")
end

return init
