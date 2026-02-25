-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local serverSidePatch = function()
    -- UI Guards (Client Side)
    local original_isValidCursor = ISMoveableCursor.isValid
    function ISMoveableCursor:isValid(square)
        -- Only block when picking up or scrapping
        if
            JASM_CURSOR_HOOKS_ENABLED
            and (self.moveableMode == "pickup" or self.moveableMode == "scrap")
            and square
        then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local object = objects:get(i)
                if object:getModData().isShop then
                    return false
                end
            end
        end
        return original_isValidCursor(self, square)
    end
end

return serverSidePatch
