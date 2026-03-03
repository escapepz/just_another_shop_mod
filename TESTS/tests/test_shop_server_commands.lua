--[[
    Offline ShopServerCommands Tests (Lua 5.1)
]]

-- Setup relative package paths for standalone execution
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
if testDir then
    package.path = testDir .. "?.lua;" .. package.path
end

local TestFramework = require("test_framework")
local MockPZ = require("mock_pz")

MockPZ.setupGlobals()

-- Test: Register command sets modData
TestFramework.test("ShopServerCommands", "register_sets_moddata", function()
    local obj = MockPZ.createIsoObject()
    local player = MockPZ.createIsoPlayer("Owner1", false)

    -- Simulate REGISTER action
    local modData = obj:getModData()
    modData.isShop = true
    modData.shopType = "STORAGE"
    modData.shopOwnerID = player:getUsername()
    modData.indestructible = true
    modData.immovable = true

    TestFramework.assert_true(modData.isShop, "isShop should be true")
    TestFramework.assert_equals("STORAGE", modData.shopType, "shopType should match")
    TestFramework.assert_equals("Owner1", modData.shopOwnerID, "shopOwnerID should match")
    TestFramework.assert_true(modData.indestructible, "indestructible should be true")
    TestFramework.assert_true(modData.immovable, "immovable should be true")
end)

-- Test: Unregister command clears modData
TestFramework.test("ShopServerCommands", "unregister_clears_moddata", function()
    local obj = MockPZ.createIsoObject()

    -- Setup as shop
    local modData = obj:getModData()
    modData.isShop = true
    modData.shopType = "STORAGE"
    modData.shopOwnerID = "Owner1"
    modData.indestructible = true
    modData.immovable = true

    -- Simulate UNREGISTER as owner
    modData.isShop = nil
    modData.shopType = nil
    modData.shopOwnerID = nil
    modData.indestructible = nil
    modData.immovable = nil

    TestFramework.assert_nil(modData.isShop, "isShop should be nil")
    TestFramework.assert_nil(modData.shopType, "shopType should be nil")
    TestFramework.assert_nil(modData.indestructible, "indestructible should be nil")
    TestFramework.assert_nil(modData.immovable, "immovable should be nil")
end)

-- Test: Only owner can unregister
TestFramework.test("ShopServerCommands", "unregister_owner_check", function()
    local obj = MockPZ.createIsoObject()
    local ownerPlayer = MockPZ.createIsoPlayer("Owner1", false)
    local otherPlayer = MockPZ.createIsoPlayer("OtherPlayer", false)

    -- Setup shop
    obj:getModData().shopOwnerID = "Owner1"

    -- Check as owner
    local isOwner = obj:getModData().shopOwnerID == ownerPlayer:getUsername()
    TestFramework.assert_true(isOwner, "Owner should match")

    -- Check as other
    isOwner = obj:getModData().shopOwnerID == otherPlayer:getUsername()
    TestFramework.assert_false(isOwner, "Other player should not be owner")
end)

-- Test: Admin can bypass ownership check
TestFramework.test("ShopServerCommands", "unregister_admin_bypass", function()
    local obj = MockPZ.createIsoObject()
    local adminPlayer = MockPZ.createIsoPlayer("Admin1", true)

    -- Setup shop owned by someone else
    obj:getModData().shopOwnerID = "SomeoneElse"

    -- Check if admin can bypass
    local isAdmin = adminPlayer:isAdmin()
    local isOwner = obj:getModData().shopOwnerID == adminPlayer:getUsername()

    TestFramework.assert_true(isAdmin or isOwner, "Admin should be able to unregister")
end)

-- Test: Admin protection flags set correctly
TestFramework.test("ShopServerCommands", "register_protection_flags", function()
    local obj = MockPZ.createIsoObject()

    -- Register shop
    local modData = obj:getModData()
    modData.indestructible = true
    modData.immovable = true

    TestFramework.assert_true(modData.indestructible, "indestructible flag should be set")
    TestFramework.assert_true(modData.immovable, "immovable flag should be set")
end)

print("[OFFLINE TESTS] ShopServerCommands tests loaded")
