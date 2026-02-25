-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local patches = {}

function patches.clientSidePatch()
    -- Action Guards (Mid-Execution)
    local original_ISDismantleAction_isValid = ISDismantleAction.isValid
    function ISDismantleAction:isValid()
        ---@diagnostic disable-next-line: unnecessary-if
        if JASM_CURSOR_HOOKS_ENABLED then
            local object = self.thumpable
            if object and object:getModData().isShop then
                return false
            end
        end
        return original_ISDismantleAction_isValid(self)
    end
end

function patches.serverSidePatch()
    -- Server Protection (Final Guard) - ALWAYS ENABLED
    local original_ISDismantleAction_complete = ISDismantleAction.complete
    function ISDismantleAction:complete()
        local object = self.thumpable
        if object and object:getModData().isShop then
            ---@diagnostic disable-next-line: unnecessary-if
            if self.action then
                self:forceStop()
            end
            return false
        end
        return original_ISDismantleAction_complete(self)
    end
end

return patches
