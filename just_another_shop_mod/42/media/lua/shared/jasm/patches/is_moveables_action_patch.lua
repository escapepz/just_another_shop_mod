-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local patches = {}

function patches.clientSidePatch()
    local original_ISMoveablesAction_isValid = ISMoveablesAction.isValid
    function ISMoveablesAction:isValid()
        ---@diagnostic disable-next-line: unnecessary-if
        if JASM_CURSOR_HOOKS_ENABLED then
            local object = self.object
            if object and object:getModData().isShop then
                -- Block Pickup and Scrap
                if self.mode == "pickup" or self.mode == "scrap" then
                    return false
                end
            end
        end
        return original_ISMoveablesAction_isValid(self)
    end
end

function patches.serverSidePatch()
    local original_ISMoveablesAction_complete = ISMoveablesAction.complete
    function ISMoveablesAction:complete()
        local object = self.object
        if object and object:getModData().isShop then
            -- Block Pickup and Scrap
            if self.mode == "pickup" or self.mode == "scrap" then
                ---@diagnostic disable-next-line: unnecessary-if
                if self.action then
                    self:forceStop()
                end
                return false
            end
        end
        return original_ISMoveablesAction_complete(self)
    end
end

return patches
