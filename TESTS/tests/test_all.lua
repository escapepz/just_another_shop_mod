--[[
    JASM Offline Test Suite - Main Entry Point
    
    Configures package.path and runs all test modules.
    Usage: lua TESTS/tests/test_all.lua
]]

-- Setup relative package paths
local testDir = debug.getinfo(1).source:match("@?(.*[/\\])")
package.path = testDir .. "?.lua;" .. package.path

print("[JASM] Test directory: " .. testDir)
print("")

-- Load test framework and mocks first
local TestFramework = require("test_framework")
local MockPZ = require("mock_pz")

-- Setup mocks
MockPZ.setupGlobals()

-- Load all test modules
require("test_shop_manager")
require("test_shop_server_commands")
require("test_maf_rules")
require("test_caf_rules")

print("")
print("=== All Test Modules Loaded ===")
print("")

-- Run all tests
TestFramework.runAll()
