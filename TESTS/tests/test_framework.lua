--[[
    Minimal Test Framework for Lua 5.1
    
    Provides assertion helpers and a test runner for offline unit tests.
]]

local TestFramework = {}

-- Test registry
TestFramework.tests = {}
TestFramework.suites = {}

-- Statistics
TestFramework.stats = {
    total = 0,
    passed = 0,
    failed = 0,
}

---Register a test in a suite
---@param suiteName string
---@param testName string
---@param testFn function
function TestFramework.test(suiteName, testName, testFn)
    TestFramework.suites[suiteName] = TestFramework.suites[suiteName] or {}

    local test = {
        suite = suiteName,
        name = testName,
        fn = testFn,
    }

    table.insert(TestFramework.tests, test)
    table.insert(TestFramework.suites[suiteName], test)
end

---Assert condition is true
---@param condition boolean
---@param message string
function TestFramework.assert_true(condition, message)
    if not condition then
        error("ASSERT FAILED: " .. (message or "condition is not true"))
    end
end

---Assert condition is false
---@param condition boolean
---@param message string
function TestFramework.assert_false(condition, message)
    if condition then
        error("ASSERT FAILED: " .. (message or "condition is not false"))
    end
end

---Assert equality
---@param expected any
---@param actual any
---@param message string
function TestFramework.assert_equals(expected, actual, message)
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

---Assert not nil
---@param value any
---@param message string
function TestFramework.assert_not_nil(value, message)
    if value == nil then
        error("ASSERT FAILED: " .. (message or "value is nil"))
    end
end

---Assert nil
---@param value any
---@param message string
function TestFramework.assert_nil(value, message)
    if value ~= nil then
        error("ASSERT FAILED: " .. (message or "value is not nil"))
    end
end

---Assert table contains value
---@param t table
---@param value any
---@param message string
function TestFramework.assert_contains(t, value, message)
    for _, v in ipairs(t) do
        if v == value then
            return
        end
    end
    error("ASSERT FAILED: " .. (message or "value not found in table"))
end

---Run a single test
---@param test table
---@return boolean success
function TestFramework.runTest(test)
    TestFramework.stats.total = TestFramework.stats.total + 1

    local success, err = pcall(test.fn)

    if success then
        TestFramework.stats.passed = TestFramework.stats.passed + 1
        print("  OK_ " .. test.name)
        return true
    else
        TestFramework.stats.failed = TestFramework.stats.failed + 1
        print("  FAIL_ " .. test.name)
        print("    ERROR: " .. tostring(err))
        return false
    end
end

---Run all tests
function TestFramework.runAll()
    print("\n=== JASM Offline Test Suite ===\n")
    TestFramework.stats = { total = 0, passed = 0, failed = 0 }

    for suiteName, tests in pairs(TestFramework.suites) do
        print(suiteName .. ":")
        for _, test in ipairs(tests) do
            TestFramework.runTest(test)
        end
        print("")
    end

    TestFramework.printResults()
end

---Run tests in a specific suite
---@param suiteName string
function TestFramework.runSuite(suiteName)
    print("\n=== JASM Offline Test Suite (" .. suiteName .. ") ===\n")
    TestFramework.stats = { total = 0, passed = 0, failed = 0 }

    if not TestFramework.suites[suiteName] then
        print("ERROR: Suite not found: " .. suiteName)
        return
    end

    print(suiteName .. ":")
    for _, test in ipairs(TestFramework.suites[suiteName]) do
        TestFramework.runTest(test)
    end
    print("")

    TestFramework.printResults()
end

---Print results summary
function TestFramework.printResults()
    print("=== Test Results ===")
    print("Total:  " .. TestFramework.stats.total)
    print("Passed: " .. TestFramework.stats.passed)
    print("Failed: " .. TestFramework.stats.failed)
    print("")

    ---@diagnostic disable-next-line: unnecessary-if
    if TestFramework.stats.failed == 0 then
        print("OK_ ALL TESTS PASSED")
    else
        print("FAIL_ SOME TESTS FAILED")
    end
    print("")
end

return TestFramework
