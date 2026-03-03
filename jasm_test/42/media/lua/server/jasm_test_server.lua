--[[
    JASM Server-Side Test Entry Point
    
    Imports the test runner and registers server-side tests.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Load all server-side test modules
require("jasm_test/test_shop_manager")
require("jasm_test/test_shop_server_commands")
require("jasm_test/test_maf_rules")

-- Expose the test runner globally for access from client/UI
_G.JASM_TestRunner = JASM_TestRunner

print("[JASM_TEST] Server test runner initialized")
