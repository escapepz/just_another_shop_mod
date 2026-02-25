-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local patches = {}

function patches.clientSidePatch()
    local original_ISMoveablesAction_isReachableObjectType = ISMoveablesAction.isReachableObjectType
    function ISMoveablesAction:isReachableObjectType()
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
        return original_ISMoveablesAction_isReachableObjectType(self)
    end

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

    local original_ISMoveablesAction_isValidObject = ISMoveablesAction.isValidObject
    function ISMoveablesAction:isValidObject()
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
        return original_ISMoveablesAction_isValidObject(self)
    end
end

function patches.serverSidePatch()
    -- Server Protection (Final Guard) - ALWAYS ENABLED
    local original_ISMoveablesAction_getDuration = ISMoveablesAction.getDuration
    function ISMoveablesAction:getDuration()
        local object = self.object
        if object and object:getModData().isShop then
            return 1 --0 * 60 * 1000 -- 600000 ticks/10 ticks/s = 1000 minutes
        end
        return original_ISMoveablesAction_getDuration(self)
    end

    local original_ISMoveablesAction_complete = ISMoveablesAction.complete
    function ISMoveablesAction:complete()
        local object = self.object
        if object and object:getModData().isShop then
            -- Block Pickup and Scrap
            if self.mode == "pickup" or self.mode == "scrap" then
                ---@diagnostic disable-next-line: unnecessary-if
                if self.action then
                    self:stop()
                end
                return false
            end
        end
        return original_ISMoveablesAction_complete(self)
    end
end

return patches
