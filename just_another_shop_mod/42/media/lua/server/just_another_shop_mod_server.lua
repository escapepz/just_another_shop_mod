local server = require("jasm/server")
local initServer = function()
	if isServer() or not isMultiplayer() then
		return server()
	end
	return nil
end

initServer()
