-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local serverSidePatch = function()
    local original_canDestroy = ISDestroyCursor.canDestroy
    function ISDestroyCursor:canDestroy(object)
        if JASM_CURSOR_HOOKS_ENABLED and object and object:getModData().isShop then
            -- Block EVERYONE (including admins): must unregister shop first
            return false
        end
        return original_canDestroy(self, object)
    end

    local original_isValid = ISDestroyCursor.isValid
    function ISDestroyCursor:isValid(square)
        ---@diagnostic disable-next-line: unnecessary-if
        if JASM_CURSOR_HOOKS_ENABLED and square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if object:getModData().isShop then
                    return false
                end
            end
        end
        return original_isValid(self, square)
    end
end

return serverSidePatch
