---@type fun(): any
local client = require("jasm/client")
local initClient = function()
	if isClient() or not isMultiplayer() then
		return client()
	end
	return nil
end

initClient()
