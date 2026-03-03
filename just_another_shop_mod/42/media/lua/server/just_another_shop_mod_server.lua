local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local initServer = require("jasm/server")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("just_another_shop_mod")

if KUtilities.IsServerOrSinglePlayer() then
    Events.OnGameBoot.Add(function()
        logger:info("[MAF] Applying server-side rules (Dedicated Server environment)...")

        initServer()
    end)

    if KUtilities.IsSinglePlayer() then
        Events.OnGameStart.Add(function()
            logger:info("[MAF] Applying server-side rules (SP/Local environment)...")

            initServer()
        end)
    end
end
