--[[
    JASM Server-Side Test Entry Point

    Imports the test runner and registers server-side tests.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Load all server-side test modules
local test_shop_manager = require("jasm_test/test_shop_manager")
local test_shop_server_commands = require("jasm_test/test_shop_server_commands")
local test_maf_rules = require("jasm_test/test_maf_rules")

-- Expose the test runner globally for access from client/UI
_G.JASM_TestRunner = JASM_TestRunner

Events.OnGameBoot.Add(function()
    test_shop_manager()
    test_shop_server_commands()
    test_maf_rules()
    print("[JASM_TEST] Server test runner initialized")
end)

Events.OnClientCommand.Add(function(module, command, _player, _args)
    if module == "jasm_test_server" then
        JASM_TestRunner.runGroup("server")
    end
end)
