local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

if not ISDestroyStuffAction then
    return
end

-- Client side guard (second guard)
local original_isValid = ISDestroyStuffAction.isValid
function ISDestroyStuffAction:isValid()
    local object = self.item
    if object and object:getModData().isShop then
        -- Block EVERYONE (including admins): must unregister shop first
        return false
    end
    return original_isValid(self)
end

-- Server/Client side final guard
local original_complete = ISDestroyStuffAction.complete
function ISDestroyStuffAction:complete()
    local object = self.item
    if object and object:getModData().isShop then
        -- Block EVERYONE (including admins): must unregister shop first
        ---@diagnostic disable-next-line: unnecessary-if
        if self.action then
            self:forceStop()
        end
        return false
    end
    return original_complete(self)
end
