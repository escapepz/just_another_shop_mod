local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")
local pz_utils = require("pz_utils_shared")
local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
local KUtilities = pz_utils.konijima.Utilities

local RuleDestroyStuff = {}

---Validation rule
function RuleDestroyStuff.validateDestroyStuff(context)
    local ctx = context ---@type ManipulationAuthorityContext
    if ctx.actionType ~= "DestroyStuff" then
        return
    end

    local _object = ctx.object
    if _object then
        local modData = _object:getModData()
        if modData.indestructible then
            local player = ctx.character
            local isAdmin = KUtilities.IsPlayerAdmin(player)
            local adminBypass = JASM_SandboxVars.Get("AdminBypass")

            if not (isAdmin and adminBypass) then
                ctx.flags.rejected = true
            end
        end
    end

    logger:info("[JASM:MAF:DestroyStuffExample] Validate phase executed")
end

---Pre-action rule
function RuleDestroyStuff.preActionDestroyStuff(context)
    local ctx = context ---@type ManipulationAuthorityContext
    if ctx.actionType ~= "DestroyStuff" then
        return
    end

    local _object = ctx.object
    if _object then
        local modData = _object:getModData()
        if modData.indestructible then
            local player = ctx.character
            local isAdmin = KUtilities.IsPlayerAdmin(player)
            local adminBypass = JASM_SandboxVars.Get("AdminBypass")

            if not (isAdmin and adminBypass) then
                ctx.flags.rejected = true
            end
        end
    end

    logger:info("[JASM:MAF:DestroyStuffExample] PreAction phase executed")
end

-- local MAF = require("manipulation_authority_framework")
-- return function()
--     if not MAF then
--         logger:error("MAF singleton missing during JASM rule registration!")
--         return
--     end

--     MAF:registerRule("validate", "destroy_stuff_example_validate", validateDestroyStuff, 100)
--     MAF:registerRule("pre", "destroy_stuff_example_pre", preActionDestroyStuff, 100)

--     logger:info("[JASM] MAF Destroy Stuff Rules loaded.")
-- end

return RuleDestroyStuff
