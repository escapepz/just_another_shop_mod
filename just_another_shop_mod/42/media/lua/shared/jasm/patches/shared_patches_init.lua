local is_destroy_stuff_action = require("jasm/patches/is_destroy_stuff_action_patch")
local is_dismantle_action = require("jasm/patches/is_dismantle_action_patch")
local is_moveables_action = require("jasm/patches/is_moveables_action_patch")

local is_moveable_sprite_props = require("jasm/patches/is_moveable_sprite_props_patch")

return function()
    Events.OnGameStart.Add(function()
        -- is_destroy_stuff_action.clientSidePatch()
        -- is_dismantle_action.clientSidePatch()
        -- is_moveables_action.clientSidePatch()
        -- is_moveable_sprite_props.clientSidePatch()
    end)

    Events.OnGameBoot.Add(function()
        is_destroy_stuff_action.serverSidePatch()
        is_dismantle_action.serverSidePatch()
        is_moveables_action.serverSidePatch()
    end)
end
