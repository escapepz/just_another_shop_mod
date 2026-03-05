---@diagnostic disable: unnecessary-if
local TextureUtils = {}

function TextureUtils.getItemTexture(itemFullID)
    if not itemFullID then
        return nil
    end
    local script = ScriptManager.instance:getItem(itemFullID)
    if script then
        local icon = script:getIcon()
        if icon then
            return getTexture("Item_" .. icon)
        end
    end
    return nil
end

return TextureUtils
