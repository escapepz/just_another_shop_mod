local TextureUtils = {}

function TextureUtils.getItemTexture(itemFullID)
    local script = ScriptManager.instance:getItem(itemFullID)
    ---@diagnostic disable-next-line: unnecessary-if
    if script then
        local icon = script:getIcon()
        return getTexture("Item_" .. icon)
    end
    return nil
end

return TextureUtils
