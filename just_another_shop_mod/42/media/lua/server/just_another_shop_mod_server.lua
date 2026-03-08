local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local initServer = require("just_another_shop_mod/server")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("just_another_shop_mod")

local serverInitialized = false

if KUtilities.IsServerOrSinglePlayer() then
    Events.OnGameBoot.Add(function()
        if serverInitialized then
            return
        end
        logger:info("[MAF] Applying server-side rules (Dedicated Server environment)...")

        initServer()
        serverInitialized = true
    end)

    if KUtilities.IsSinglePlayer() then
        Events.OnGameStart.Add(function()
            if serverInitialized then
                return
            end
            logger:info("[MAF] Applying server-side rules (SP/Local environment)...")

            initServer()
            serverInitialized = true
        end)
    end
end
