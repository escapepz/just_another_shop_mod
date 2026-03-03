--[[
    MAF (Manipulation Authority Framework) Rules Tests
    
    Tests DestroyStuff and Moveables rules logic.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Mock MAF context object
local function createMockContext(actionType, object)
    return {
        actionType = actionType,
        object = object,
        flags = { rejected = false },
    }
end

-- Mock IsoObject
local function createMockObject(isIndestructible, isImmovable)
    return {
        modData = {
            indestructible = isIndestructible or false,
            immovable = isImmovable or false,
        },
        getModData = function(self)
            return self.modData
        end,
    }
end

-- Test: DestroyStuff rejects indestructible objects
JASM_TestRunner.register("maf_destroy_stuff_reject", "server", function()
    local RuleDestroyStuff = require("just_another_shop_mod/rules/maf/shop_destroy_stuff_rule")

    local indestructibleObj = createMockObject(true, false)
    local ctx = createMockContext("DestroyStuff", indestructibleObj)

    -- Simulate validation
    RuleDestroyStuff.validateDestroyStuff(ctx)

    JASM_TestRunner.assert_true(ctx.flags.rejected, "Indestructible object should be rejected")
end)

-- Test: DestroyStuff allows destructible objects
JASM_TestRunner.register("maf_destroy_stuff_allow", "server", function()
    local RuleDestroyStuff = require("just_another_shop_mod/rules/maf/shop_destroy_stuff_rule")

    local destructibleObj = createMockObject(false, false)
    local ctx = createMockContext("DestroyStuff", destructibleObj)

    -- Simulate validation
    RuleDestroyStuff.validateDestroyStuff(ctx)

    JASM_TestRunner.assert_false(ctx.flags.rejected, "Destructible object should not be rejected")
end)

-- Test: DestroyStuff ignores wrong action type
JASM_TestRunner.register("maf_destroy_stuff_wrong_action", "server", function()
    local RuleDestroyStuff = require("just_another_shop_mod/rules/maf/shop_destroy_stuff_rule")

    local indestructibleObj = createMockObject(true, false)
    local ctx = createMockContext("Moveables", indestructibleObj) -- Wrong action type

    -- Simulate validation
    RuleDestroyStuff.validateDestroyStuff(ctx)

    JASM_TestRunner.assert_false(ctx.flags.rejected, "Wrong action type should not affect result")
end)

-- Test: Moveables rejects immovable objects
JASM_TestRunner.register("maf_moveables_reject", "server", function()
    local RuleMoveables = require("just_another_shop_mod/rules/maf/shop_moveables_rule")

    local immovableObj = createMockObject(false, true)
    local ctx = createMockContext("Moveables", immovableObj)

    -- Simulate validation
    RuleMoveables.validateMoveables(ctx)

    JASM_TestRunner.assert_true(ctx.flags.rejected, "Immovable object should be rejected")
end)

-- Test: Moveables allows movable objects
JASM_TestRunner.register("maf_moveables_allow", "server", function()
    local RuleMoveables = require("just_another_shop_mod/rules/maf/shop_moveables_rule")

    local movableObj = createMockObject(false, false)
    local ctx = createMockContext("Moveables", movableObj)

    -- Simulate validation
    RuleMoveables.validateMoveables(ctx)

    JASM_TestRunner.assert_false(ctx.flags.rejected, "Movable object should not be rejected")
end)

-- Test: Moveables pre-action phase
JASM_TestRunner.register("maf_moveables_preaction", "server", function()
    local RuleMoveables = require("just_another_shop_mod/rules/maf/shop_moveables_rule")

    local immovableObj = createMockObject(false, true)
    local ctx = createMockContext("Moveables", immovableObj)

    -- Simulate pre-action
    RuleMoveables.preActionMoveables(ctx)

    JASM_TestRunner.assert_true(
        ctx.flags.rejected,
        "Pre-action should also reject immovable objects"
    )
end)

print("[JASM_TEST] MAF Rules tests registered")
