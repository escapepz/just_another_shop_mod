--[[
    Offline MAF Rules Tests (Lua 5.1)
]]

-- Setup relative package paths for standalone execution
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
if testDir then
    package.path = testDir .. "?.lua;" .. package.path
end

local TestFramework = require("test_framework")
local MockPZ = require("mock_pz")

MockPZ.setupGlobals()

-- Create mock MAF context
local function createMockContext(actionType, object)
    return {
        actionType = actionType,
        object = object,
        flags = { rejected = false },
    }
end

-- Minimal DestroyStuff rule
local function validateDestroyStuff(context)
    if context.actionType ~= "DestroyStuff" then
        return
    end

    local obj = context.object
    if obj then
        local modData = obj:getModData()
        if modData.indestructible then
            context.flags.rejected = true
        end
    end
end

-- Minimal Moveables rule
local function validateMoveables(context)
    if context.actionType ~= "Moveables" then
        return
    end

    local obj = context.object
    if obj then
        local modData = obj:getModData()
        if modData.immovable then
            context.flags.rejected = true
        end
    end
end

-- Test: DestroyStuff rejects indestructible
TestFramework.test("MAFRules", "destroy_stuff_reject_indestructible", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.indestructible = true

    local ctx = createMockContext("DestroyStuff", obj)
    validateDestroyStuff(ctx)

    TestFramework.assert_true(ctx.flags.rejected, "Indestructible should be rejected")
end)

-- Test: DestroyStuff allows destructible
TestFramework.test("MAFRules", "destroy_stuff_allow_destructible", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.indestructible = false

    local ctx = createMockContext("DestroyStuff", obj)
    validateDestroyStuff(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Destructible should be allowed")
end)

-- Test: DestroyStuff ignores other actions
TestFramework.test("MAFRules", "destroy_stuff_ignore_other_action", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.indestructible = true

    local ctx = createMockContext("Moveables", obj) -- Wrong action
    validateDestroyStuff(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Should not affect other actions")
end)

-- Test: Moveables rejects immovable
TestFramework.test("MAFRules", "moveables_reject_immovable", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.immovable = true

    local ctx = createMockContext("Moveables", obj)
    validateMoveables(ctx)

    TestFramework.assert_true(ctx.flags.rejected, "Immovable should be rejected")
end)

-- Test: Moveables allows movable
TestFramework.test("MAFRules", "moveables_allow_movable", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.immovable = false

    local ctx = createMockContext("Moveables", obj)
    validateMoveables(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Movable should be allowed")
end)

-- Test: Moveables ignores other actions
TestFramework.test("MAFRules", "moveables_ignore_other_action", function()
    local obj = MockPZ.createIsoObject()
    obj.modData.immovable = true

    local ctx = createMockContext("DestroyStuff", obj) -- Wrong action
    validateMoveables(ctx)

    TestFramework.assert_false(ctx.flags.rejected, "Should not affect other actions")
end)

-- Test: Rules handle nil object gracefully
TestFramework.test("MAFRules", "handle_nil_object", function()
    local ctx = createMockContext("DestroyStuff", nil)

    -- Should not error
    validateDestroyStuff(ctx)
    TestFramework.assert_false(ctx.flags.rejected)
end)

print("[OFFLINE TESTS] MAFRules tests loaded")
