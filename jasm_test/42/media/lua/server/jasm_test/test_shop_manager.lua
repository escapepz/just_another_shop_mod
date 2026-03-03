--[[
    ShopManager Unit Tests
    
    Tests basic ShopManager functionality: registration, locking, unlocking.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Mock ItemContainer and parent objects
local function createMockContainer()
    local mockParent = {
        modData = {},
        square = nil,
        getModData = function(self)
            return self.modData
        end,
        getSquare = function(self)
            return self.square
        end,
    }

    return {
        parent = mockParent,
        getParent = function(self)
            return self.parent
        end,
        getContainer = function(self)
            return true
        end,
    }
end

-- Test: Shop registration
JASM_TestRunner.register("shop_register", "server", function()
    local ShopManager = require("just_another_shop_mod/shop_manager")
    local manager = ShopManager()
    local container = createMockContainer()

    manager:registerShop(container, "TestPlayer", "Test Shop")

    local modData = container:getParent():getModData()
    JASM_TestRunner.assert_true(modData.isShop, "isShop should be true")
    JASM_TestRunner.assert_equals("TestPlayer", modData.shopOwnerID, "shopOwnerID mismatch")
    JASM_TestRunner.assert_equals("Test Shop", modData.shopName, "shopName mismatch")
end)

-- Test: Shop unregistration
JASM_TestRunner.register("shop_unregister", "server", function()
    local ShopManager = require("just_another_shop_mod/shop_manager")
    local manager = ShopManager()
    local container = createMockContainer()

    manager:registerShop(container, "TestPlayer", "Test Shop")
    manager:unregisterShop(container)

    local modData = container:getParent():getModData()
    JASM_TestRunner.assert_nil(modData.isShop, "isShop should be nil after unregister")
    JASM_TestRunner.assert_nil(modData.shopOwnerID, "shopOwnerID should be nil after unregister")
end)

-- Test: Shop locking
JASM_TestRunner.register("shop_lock", "server", function()
    local ShopManager = require("just_another_shop_mod/shop_manager")
    local manager = ShopManager()

    local success = manager:lockShop("square_123", "Player1")
    JASM_TestRunner.assert_true(success, "First lock should succeed")

    local lock = manager:getShopLock("square_123")
    JASM_TestRunner.assert_equals("Player1", lock, "Lock holder mismatch")
end)

-- Test: Shop lock conflict
JASM_TestRunner.register("shop_lock_conflict", "server", function()
    local ShopManager = require("just_another_shop_mod/shop_manager")
    local manager = ShopManager()

    manager:lockShop("square_456", "Player1")
    local success = manager:lockShop("square_456", "Player2")
    JASM_TestRunner.assert_false(success, "Second lock from different player should fail")
end)

-- Test: Shop unlock
JASM_TestRunner.register("shop_unlock", "server", function()
    local ShopManager = require("just_another_shop_mod/shop_manager")
    local manager = ShopManager()

    manager:lockShop("square_789", "Player1")
    manager:unlockShop("square_789", "Player1")

    local lock = manager:getShopLock("square_789")
    JASM_TestRunner.assert_nil(lock, "Lock should be cleared after unlock")
end)

print("[JASM_TEST] ShopManager tests registered")
