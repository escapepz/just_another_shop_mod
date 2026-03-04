local TextureUtils = {}

function TextureUtils.getItemTexture(itemFullID)
    if not itemFullID then
        return nil
    end
    local script = ScriptManager.instance:getItem(itemFullID)
    ---@diagnostic disable-next-line: unnecessary-if
    if script then
        local icon = script:getIcon()
        ---@diagnostic disable-next-line: unnecessary-if
        if icon then
            return getTexture("Item_" .. icon)
        end
    end
    return nil
end

return TextureUtils
