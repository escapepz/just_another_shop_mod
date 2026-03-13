--- JASM Sandbox Variables Configuration
--- Centralizes all mod sandbox variable defaults.
--- Uses pz_utils.escape.SandboxVarsModule for safe, namespaced access.
---
--- Access via:
---   local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
---   local val = JASM_SandboxVars.Get("AdminBypass")
---
---@class JASM_SandboxVars

local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local SandboxVarsModule = pz_utils.escape.SandboxVarsModule

--- Mod-specific sandbox defaults
local DEFAULTS = {
    --- Whether admins bypass the shop ownership check on UNREGISTER.
    --- Even when true, admins still cannot unregister a shop that has items inside.
    ---@type boolean
    AdminBypass = true,

    --- Shop lock protection method.
    --- 1 "DUAL"    = JASM application lock (modData) + vanilla entity:getUsingPlayer() engine lock.
    ---             Fast client-side conflict detection with player-name feedback in halotext.
    --- 2 "VANILLA" = Vanilla engine lock only. No JASM lock state is written.
    ---             Uses built-in ISEntityWindow/ISEntityUI conflict detection.
    ---@type number
    ShopLockMethod = 1,

    --- Max player-owned shops per player
    ---@type number
    MaxPlayerShopsPerPlayer = 5,
}

local NAMESPACE = "JASM"
local logger = ZUL.new("just_another_shop_mod")

if not _G.__JASM_SandboxVarsInitialized then
    -- Client-side event for loaded sandbox vars
    Events.OnGameStart.Add(function()
        --- Initialize sandbox vars (safe to call multiple times; second call is a no-op
        --- because SandboxVarsModule.Init would overwrite — use a guard).
        SandboxVarsModule.Init(NAMESPACE, DEFAULTS)
    end)
    -- Server-side event for loaded sandbox vars
    Events.OnLoadedTileDefinitions.Add(function()
        SandboxVarsModule.Init(NAMESPACE, DEFAULTS)
    end)
    _G.__JASM_SandboxVarsInitialized = true
end

--- Bound accessor (ergonomic: no namespace parameter needed)
local JASM_SandboxVars = {
    ---@param key string
    ---@param defaultValue any
    ---@return any
    Get = function(key, defaultValue)
        local fallback = defaultValue or DEFAULTS[key]
        local val = SandboxVarsModule.Get(NAMESPACE, key, fallback)
        logger:debug(
            "JASM_SandboxVars.Get key="
                .. key
                .. " fallback="
                .. tostring(fallback)
                .. " result="
                .. tostring(val)
        )
        return val
    end,

    ---@return table
    GetAll = function()
        return SandboxVarsModule.GetAll(NAMESPACE)
    end,
}

return JASM_SandboxVars
