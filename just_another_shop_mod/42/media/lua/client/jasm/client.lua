---@diagnostic disable-next-line: redundant-parameter
local OnServerCommand = require("jasm/shop_client_commands")
---@type Callback_OnFillWorldObjectContextMenu
local ShopContextMenu = require("jasm/shop_context_menu")

local function Init()
	Events.OnServerCommand.Add(OnServerCommand)
	Events.OnFillWorldObjectContextMenu.Add(ShopContextMenu)
end

return Init
