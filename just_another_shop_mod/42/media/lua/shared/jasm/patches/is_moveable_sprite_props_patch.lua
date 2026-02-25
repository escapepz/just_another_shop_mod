-- Set to false to disable cursor hooks for testing the server :complete() method hooks
local JASM_CURSOR_HOOKS_ENABLED = false

local patches = {}

function patches.clientSidePatch()
    -- UI Guards (Client Side)
    local original_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
    function ISMoveableSpriteProps:canPickUpMoveableInternal(_character, _square, _object, _isMulti)
        if JASM_CURSOR_HOOKS_ENABLED and _object and _object:getModData().isShop then
            return false
        end
        return original_canPickUpMoveableInternal(self, _character, _square, _object, _isMulti)
    end

    local original_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
    function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
        if JASM_CURSOR_HOOKS_ENABLED and _object and _object:getModData().isShop then
            ---@diagnostic disable-next-line: unnecessary-if
            if _result then
                _result.canScrap = false
            end
            return false
        end
        return original_canScrapObjectInternal(self, _result, _object)
    end
end

return patches
