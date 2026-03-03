--[[
    JASM Offline Test Suite - Main Entry Point
    
    Configures package.path and runs all test modules.
    Usage: lua TESTS/tests/test_all.lua
]]

-- Setup relative package paths
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
package.path = testDir .. "?.lua;" .. package.path

-- Add mod's lua directories to package.path
local modRoot = testDir .. "../../just_another_shop_mod/42/media/lua/"
local testModRoot = testDir .. "../../jasm_test/42/media/lua/"

package.path = modRoot
    .. "client/?.lua;"
    .. modRoot
    .. "shared/?.lua;"
    .. modRoot
    .. "server/?.lua;"
    .. modRoot
    .. "client/jasm/?.lua;"
    .. modRoot
    .. "shared/jasm/?.lua;"
    .. modRoot
    .. "server/jasm/?.lua;"
    .. modRoot
    .. "client/jasm/rules/caf/?.lua;"
    .. modRoot
    .. "server/jasm/rules/maf/?.lua;"
    .. package.path

package.path = testModRoot
    .. "client/?.lua;"
    .. testModRoot
    .. "shared/?.lua;"
    .. testModRoot
    .. "server/?.lua;"
    .. package.path

print("[JASM] Test directory: " .. testDir)
print("[JASM] Mod root: " .. modRoot)
print("[JASM] Test mod root: " .. testModRoot)
print("")

-- Load test framework and mocks first
local MockPZ = require("mock_pz")

-- Setup mocks
MockPZ.setupGlobals()

-- Load JASM Test Runner (the standard in-game runner, used offline here)
local JASM_TestRunner = require("jasm_test_shared")
_G.JASM_TestRunner = JASM_TestRunner

-- Load all test modules from jasm_test
require("jasm_test/test_shop_manager")
require("jasm_test/test_shop_server_commands")
require("jasm_test/test_maf_rules")
require("jasm_test/test_caf_rules")
require("jasm_test/test_player_actions")

print("")
print("=== All Test Modules Loaded ===")
print("")

-- Run all tests
JASM_TestRunner.runAll()
