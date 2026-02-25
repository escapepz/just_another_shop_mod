local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

-- UI Guards (Client Side)
local original_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
function ISMoveableSpriteProps:canPickUpMoveableInternal(_character, _square, _object, _isMulti)
    if _object and _object:getModData().isShop then
        local isOwner = _object:getModData().shopOwnerID == _character:getUsername()
        ---@diagnostic disable-next-line: unnecessary-if
        if not (isOwner or KUtilities.IsPlayerAdmin(_character)) then
            return false
        end
    end
    return original_canPickUpMoveableInternal(self, _character, _square, _object, _isMulti)
end

local original_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
    if _object and _object:getModData().isShop then
        ---@diagnostic disable-next-line: unnecessary-if
        if _result then
            _result.canScrap = false
        end
        return false
    end
    return original_canScrapObjectInternal(self, _result, _object)
end

-- Server Protection (Final Guard)
local original_ISDismantleAction_complete = ISDismantleAction.complete
function ISDismantleAction:complete()
    local object = self.thumpable
    if object and object:getModData().isShop then
        if not KUtilities.IsPlayerAdmin(self.character) then
            ---@diagnostic disable-next-line: unnecessary-if
            if self.action then
                self:forceStop()
            end
            return false
        end
    end
    return original_ISDismantleAction_complete(self)
end

local original_ISMoveablesAction_complete = ISMoveablesAction.complete
function ISMoveablesAction:complete()
    local object = self.object
    if object and object:getModData().isShop then
        local isOwner = object:getModData().shopOwnerID == self.character:getUsername()
        ---@diagnostic disable-next-line: unnecessary-if
        if not (isOwner or KUtilities.IsPlayerAdmin(self.character)) then
            -- Block Pickup and Scrap
            if self.mode == "pickup" or self.mode == "scrap" then
                ---@diagnostic disable-next-line: unnecessary-if
                if self.action then
                    self:forceStop()
                end
                return false
            end
        end
    end
    return original_ISMoveablesAction_complete(self)
end
