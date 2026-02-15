local OnServerCommand = require("jasm/shop_client_commands")
local ShopContextMenu = require("jasm/shop_context_menu")

local function init()
	Events.OnServerCommand.Add(OnServerCommand)
	Events.OnFillWorldObjectContextMenu.Add(ShopContextMenu)
end

return init
