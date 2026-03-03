--[[
    Offline ShopManager Unit Tests (Lua 5.1)
]]

-- Setup relative package paths for standalone execution
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
if testDir then
    package.path = testDir .. "?.lua;" .. package.path
end

local TestFramework = require("test_framework")
local MockPZ = require("mock_pz")

MockPZ.setupGlobals()

-- Create a minimal ShopManager mock for offline testing
local function createShopManager()
    return {
        shops = {},
        locks = {},

        registerShop = function(self, container, ownerID, shopName)
            local parent = container:getParent()
            local modData = parent:getModData()
            modData.isShop = true
            modData.shopOwnerID = ownerID
            modData.shopName = shopName or "A Shop"

            if parent:getSquare() then
                local squareID = tostring(parent:getSquare().x)
                    .. ","
                    .. tostring(parent:getSquare().y)
                self.shops[squareID] = true
            end
        end,

        unregisterShop = function(self, container)
            local parent = container:getParent()
            local modData = parent:getModData()
            modData.isShop = nil
            modData.shopOwnerID = nil
            modData.shopName = nil

            if parent:getSquare() then
                local squareID = tostring(parent:getSquare().x)
                    .. ","
                    .. tostring(parent:getSquare().y)
                self.shops[squareID] = nil
                self.locks[squareID] = nil
            end
        end,

        lockShop = function(self, squareID, username)
            if self.locks[squareID] and self.locks[squareID] ~= username then
                return false
            end
            self.locks[squareID] = username
            return true
        end,

        unlockShop = function(self, squareID, username)
            if self.locks[squareID] == username then
                self.locks[squareID] = nil
            end
        end,

        getShopLock = function(self, squareID)
            return self.locks[squareID]
        end,
    }
end

-- Test: Register shop
TestFramework.test("ShopManager", "register_shop", function()
    local manager = createShopManager()
    local obj = MockPZ.createIsoObject()
    local container = MockPZ.createItemContainer()
    container:setParent(obj)

    manager:registerShop(container, "Owner1", "Test Shop")

    TestFramework.assert_true(obj.modData.isShop)
    TestFramework.assert_equals("Owner1", obj.modData.shopOwnerID)
    TestFramework.assert_equals("Test Shop", obj.modData.shopName)
end)

-- Test: Unregister shop
TestFramework.test("ShopManager", "unregister_shop", function()
    local manager = createShopManager()
    local obj = MockPZ.createIsoObject()
    local container = MockPZ.createItemContainer()
    container:setParent(obj)

    manager:registerShop(container, "Owner1", "Test Shop")
    manager:unregisterShop(container)

    TestFramework.assert_nil(obj.modData.isShop)
    TestFramework.assert_nil(obj.modData.shopOwnerID)
    TestFramework.assert_nil(obj.modData.shopName)
end)

-- Test: Lock shop
TestFramework.test("ShopManager", "lock_shop", function()
    local manager = createShopManager()

    local success = manager:lockShop("square_1", "Player1")
    TestFramework.assert_true(success)

    local lock = manager:getShopLock("square_1")
    TestFramework.assert_equals("Player1", lock)
end)

-- Test: Lock conflict
TestFramework.test("ShopManager", "lock_conflict", function()
    local manager = createShopManager()

    manager:lockShop("square_2", "Player1")
    local success = manager:lockShop("square_2", "Player2")

    TestFramework.assert_false(success, "Different player should not be able to lock")
end)

-- Test: Unlock shop
TestFramework.test("ShopManager", "unlock_shop", function()
    local manager = createShopManager()

    manager:lockShop("square_3", "Player1")
    manager:unlockShop("square_3", "Player1")

    local lock = manager:getShopLock("square_3")
    TestFramework.assert_nil(lock)
end)

print("[OFFLINE TESTS] ShopManager tests loaded")
