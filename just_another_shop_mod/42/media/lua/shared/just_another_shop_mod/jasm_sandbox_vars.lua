--- JASM Sandbox Variables Configuration
--- Centralizes all mod sandbox variable defaults.
--- Uses pz_utils.escape.SandboxVarsModule for safe, namespaced access.
---
--- Access via:
---   local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
---   local val = JASM_SandboxVars.Get("AdminBypass")
---
---@class JASM_SandboxVars

local pz_utils = require("pz_utils_shared")

local SandboxVarsModule = pz_utils.escape.SandboxVarsModule

--- Mod-specific sandbox defaults
local DEFAULTS = {
    --- Whether admins bypass the shop ownership check on UNREGISTER.
    --- Even when true, admins still cannot unregister a shop that has items inside.
    ---@type boolean
    AdminBypass = true,
}

local NAMESPACE = "JASM"

--- Initialize sandbox vars (safe to call multiple times; second call is a no-op
--- because SandboxVarsModule.Init would overwrite — use a guard).
if not _G.__JASM_SandboxVarsInitialized then
    SandboxVarsModule.Init(NAMESPACE, DEFAULTS)
    _G.__JASM_SandboxVarsInitialized = true
end

--- Bound accessor (ergonomic: no namespace parameter needed)
local JASM_SandboxVars = {
    ---@param key string
    ---@param defaultValue any
    ---@return any
    Get = function(key, defaultValue)
        return SandboxVarsModule.Get(NAMESPACE, key, defaultValue)
    end,

    ---@return table
    GetAll = function()
        return SandboxVarsModule.GetAll(NAMESPACE)
    end,
}

return JASM_SandboxVars
