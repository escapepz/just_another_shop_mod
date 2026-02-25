local server = require("jasm/server")
local patches = require("jasm/patches/server_patches_init")

local initServer = function()
    if isServer() or not isMultiplayer() then
        return server()
    end
    return nil
end

local initPatches = function()
    if isServer() or not isMultiplayer() then
        return patches()
    end
    return nil
end

initServer()
initPatches()
