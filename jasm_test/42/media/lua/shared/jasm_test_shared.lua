--[[ 
    JASM Test Runner - Shared Context
    
    Manages and executes in-game tests for Just Another Shop Mod.
    Works in both client and server contexts.
]]

JASM_TestRunner = JASM_TestRunner or {}

-- Test registry
JASM_TestRunner.tests = {}
JASM_TestRunner.groups = {}

-- Test statistics
JASM_TestRunner.stats = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = 0,
}

---Register a test
---@param name string
---@param group string
---@param testFn function
function JASM_TestRunner.register(name, group, testFn)
    group = group or "general"
    JASM_TestRunner.groups[group] = JASM_TestRunner.groups[group] or {}

    table.insert(JASM_TestRunner.tests, {
        name = name,
        group = group,
        fn = testFn,
    })
    table.insert(JASM_TestRunner.groups[group], {
        name = name,
        fn = testFn,
    })
end

---Assert that a condition is true
---@param condition boolean
---@param message string
function JASM_TestRunner.assert_true(condition, message)
    if not condition then
        error("ASSERT FAILED: " .. (message or "condition is not true"))
    end
end

---Assert that a condition is false
---@param condition boolean
---@param message string
function JASM_TestRunner.assert_false(condition, message)
    if condition then
        error("ASSERT FAILED: " .. (message or "condition is not false"))
    end
end

---Assert that two values are equal
---@param expected any
---@param actual any
---@param message string
function JASM_TestRunner.assert_equals(expected, actual, message)
    if expected ~= actual then
        error(
            "ASSERT FAILED: expected "
                .. tostring(expected)
                .. " but got "
                .. tostring(actual)
                .. (message and " (" .. message .. ")" or "")
        )
    end
end

---Assert that a value is not nil
---@param value any
---@param message string
function JASM_TestRunner.assert_not_nil(value, message)
    if value == nil then
        error("ASSERT FAILED: " .. (message or "value is nil"))
    end
end

---Assert that a value is nil
---@param value any
---@param message string
function JASM_TestRunner.assert_nil(value, message)
    if value ~= nil then
        error("ASSERT FAILED: " .. (message or "value is not nil"))
    end
end

---Run a single test
---@param test table
---@return boolean success
function JASM_TestRunner.runTest(test)
    JASM_TestRunner.stats.total = JASM_TestRunner.stats.total + 1

    local success, err = pcall(test.fn)

    if success then
        JASM_TestRunner.stats.passed = JASM_TestRunner.stats.passed + 1
        print("[PASS] " .. test.group .. " :: " .. test.name)
        return true
    else
        JASM_TestRunner.stats.failed = JASM_TestRunner.stats.failed + 1
        print("[FAIL] " .. test.group .. " :: " .. test.name)
        print("  ERROR: " .. tostring(err))
        return false
    end
end

---Run all tests
function JASM_TestRunner.runAll()
    print("=== JASM Test Runner Starting ===")
    JASM_TestRunner.stats = { total = 0, passed = 0, failed = 0, errors = 0 }

    for _, test in ipairs(JASM_TestRunner.tests) do
        JASM_TestRunner.runTest(test)
    end

    JASM_TestRunner.printResults()
end

---Run tests in a specific group
---@param group string
function JASM_TestRunner.runGroup(group)
    print("=== JASM Test Runner Starting (Group: " .. group .. ") ===")
    JASM_TestRunner.stats = { total = 0, passed = 0, failed = 0, errors = 0 }

    local groupTests = JASM_TestRunner.groups[group]
    if not groupTests then
        print("[ERROR] No tests found for group: " .. group)
        return
    end

    for _, test in ipairs(groupTests) do
        JASM_TestRunner.runTest({
            name = test.name,
            group = group,
            fn = test.fn,
        })
    end

    JASM_TestRunner.printResults()
end

---Print test results summary
function JASM_TestRunner.printResults()
    print("")
    print("=== Test Results ===")
    print("Total: " .. JASM_TestRunner.stats.total)
    print("Passed: " .. JASM_TestRunner.stats.passed)
    print("Failed: " .. JASM_TestRunner.stats.failed)

    ---@diagnostic disable-next-line: unnecessary-if
    if JASM_TestRunner.stats.failed == 0 then
        print("")
        print("OK_ ALL TESTS PASSED")
    else
        print("")
        print("FAIL_ SOME TESTS FAILED")
    end
end

return JASM_TestRunner
