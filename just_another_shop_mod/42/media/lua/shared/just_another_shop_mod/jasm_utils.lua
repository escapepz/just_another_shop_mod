local pz_utils = require("pz_utils_shared")
local KUtilities = pz_utils.konijima.Utilities

local JASM_Utils = {}

---@type string|nil
JASM_Utils.SessionId = nil

---Get the current JASM server session ID (Client only)
---@return string|nil
function JASM_Utils.GetSessionID()
    if JASM_Utils.SessionId ~= nil then
        return JASM_Utils.SessionId
    end

    -- Request from server
    KUtilities.SendClientCommand("JASM_ShopManager", "JASM_RequestSessionId", {})

    return JASM_Utils.SessionId
end

---Check if an object is a player-built container
---@param object IsoObject
---@return boolean
function JASM_Utils.isPlayerBuiltContainer(object)
    -- Must be IsoThumpable
    if not instanceof(object, "IsoThumpable") then
        return false
    end

    -- Must have modData
    if not object:hasModData() then
        return false
    end

    -- Check for "need:*" keys (player construction marker)
    local modData = object:getModData()
    for k, _ in pairs(modData) do
        if type(k) == "string" and luautils.stringStarts(k, "need:") then
            return true -- Built by player
        end
    end

    return false
end

return JASM_Utils
