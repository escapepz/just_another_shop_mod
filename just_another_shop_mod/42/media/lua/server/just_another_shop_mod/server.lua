local ZUL = require("zul")
local MAF = require("manipulation_authority_framework")

-- Initialize Shop Manager
local ShopManager = require("just_another_shop_mod/shop_manager")

-- JASM MAF Rules
local RuleDestroyStuff = require("just_another_shop_mod/rules/maf/shop_destroy_stuff_rule")
local RuleMoveables = require("just_another_shop_mod/rules/maf/shop_moveables_rule")

local ServerCommand = require("just_another_shop_mod/shop_server_commands")
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")

local logger = ZUL.new("just_another_shop_mod")

local function InitMAF()
    MAF:registerRule("validate", "ShopProtection", RuleDestroyStuff.validateDestroyStuff, 10)
    MAF:registerRule("pre", "ShopProtection", RuleDestroyStuff.preActionDestroyStuff, 10)

    MAF:registerRule("validate", "ShopProtection", RuleMoveables.validateMoveables, 10)
    MAF:registerRule("pre", "ShopProtection", RuleMoveables.preActionMoveables, 10)
end

local function Init()
    logger:info("Just Another Shop Mod initializing...")

    InitMAF()

    -- Singleton pattern
    if not _G.JASM_ShopManager then
        ---@diagnostic disable-next-line: global-in-non-module
        ---@type ShopManager
        _G.JASM_ShopManager = ShopManager()
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    Events.OnClientCommand.Add(ServerCommand)

    logger:info("Just Another Shop Mod (CAF-MAF-Based) loaded successfully.")

    return _G.JASM_ShopManager
end

-- Issue 16: Initialize session ID after sandbox vars are ready
local function InitSessionID()
    local lockMethod = JASM_SandboxVars.Get("ShopLockMethod", 1)
    if lockMethod == 1 then
        local sessionData = ModData.getOrCreate("JASM_ServerSession")
        sessionData.id = tostring(getTimeInMillis()) .. "_" .. tostring(ZombRand(100000))
        ModData.transmit("JASM_ServerSession")
        logger:info("DUAL mode: generated new Shop Lock Session ID: " .. sessionData.id)
    end
end

-- Schedule InitSessionID for OnLoadedTileDefinitions (when sandbox vars are ready)
-- might not compatible with SP
if not _G.__JASM_SessionIDInitialized then
    Events.OnLoadedTileDefinitions.Add(function()
        if not _G.__JASM_SessionIDInitialized then
            InitSessionID()
            ---@diagnostic disable-next-line: global-in-non-module
            _G.__JASM_SessionIDInitialized = true
        end
    end)
end

return Init
