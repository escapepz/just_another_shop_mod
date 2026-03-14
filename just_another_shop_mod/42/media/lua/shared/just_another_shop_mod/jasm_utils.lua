local JASM_Utils = {}

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
