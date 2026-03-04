local ZUL = require("zul")
local logger = ZUL.new("just_another_shop_mod")

local RuleMoveables = {}

---Validation rule example
function RuleMoveables.validateMoveables(context)
    local ctx = context ---@type ManipulationAuthorityContext
    if context.actionType ~= "Moveables" then
        return
    end

    local _object = ctx.object
    if _object then
        local modData = _object:getModData()
        if modData.immovable then
            context.flags.rejected = true
        end
    end

    logger:info("[JASM:MAF:MoveablesExample] Validate phase executed")
end

---Pre-action rule example
function RuleMoveables.preActionMoveables(context)
    local ctx = context ---@type ManipulationAuthorityContext
    if context.actionType ~= "Moveables" then
        return
    end

    local _object = ctx.object
    if _object then
        local modData = _object:getModData()
        if modData.immovable then
            context.flags.rejected = true
        end
    end

    logger:info("[JASM:MAF:MoveablesExample] PreAction phase executed")
end

return RuleMoveables

-- local MAF = require("manipulation_authority_framework")
-- return function()
--     if not MAF then
--         logger:error("MAF singleton missing during JASM rule registration!")
--         return
--     end

--     MAF:registerRule("validate", "moveables_example_validate", validateMoveables, 200)
--     MAF:registerRule("pre", "moveables_example_pre", preActionMoveables, 200)

--     logger:info("[JASM] MAF Moveables Rules loaded.")
-- end
