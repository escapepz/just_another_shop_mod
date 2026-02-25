local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

if not ISDestroyCursor then
    return
end

local original_canDestroy = ISDestroyCursor.canDestroy
function ISDestroyCursor:canDestroy(object)
    if object and object:getModData().isShop then
        -- Block EVERYONE (including admins): must unregister shop first
        return false
    end
    return original_canDestroy(self, object)
end
