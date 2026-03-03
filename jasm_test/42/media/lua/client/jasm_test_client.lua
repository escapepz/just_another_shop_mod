--[[
    JASM Client-Side Test Entry Point
    
    Imports the test runner and registers client-side tests.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Load all client-side test modules
require("jasm_test/test_caf_rules")

-- Expose the test runner globally for access from UI
_G.JASM_TestRunner = JASM_TestRunner

print("[JASM_TEST] Client test runner initialized")
