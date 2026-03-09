--[[
    JASM Client-Side Test Entry Point

    Imports the test runner and registers client-side tests.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Load all client-side test modules
local test_caf_rules = require("jasm_test/test_caf_rules")
local test_player_actions = require("jasm_test/test_player_actions")
local test_context_menu_permissions = require("jasm_test/test_context_menu_permissions")
local test_ui_refresh = require("jasm_test/test_ui_refresh")
local test_issue14 = require("jasm_test/test_issue14_ui_refresh_locked_shop")

local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

---@param playerIndex integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
---@param test boolean
local function DoShopContextMenu(playerIndex, context, worldObjects, test)
    if test then
        return
    end

    -- JASM Management Submenu (Registration/NPC/Management)
    local jOption = context:addOption("JASM Test", worldObjects, nil)
    local jMenu = ISContextMenu:getNew(context)
    context:addSubMenu(jOption, jMenu)

    jMenu:addOption("Client Test", worldObjects, function()
        JASM_TestRunner.runGroup("client")
    end)

    jMenu:addOption("Server Test", nil, function()
        KUtilities.SendClientCommand("jasm_test_server", "run_group", { group = "server" })
    end)
end

-- Expose the test runner globally for access from UI
_G.JASM_TestRunner = JASM_TestRunner

Events.OnGameStart.Add(function()
    test_caf_rules()
    test_player_actions()
    test_context_menu_permissions()
    test_ui_refresh()
    test_issue14()
    print("[JASM_TEST] Client test runner initialized")
end)

Events.OnFillWorldObjectContextMenu.Add(DoShopContextMenu)
