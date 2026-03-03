local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local initClient = require("jasm/client")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("just_another_shop_mod")

if KUtilities.IsClientOrSinglePlayer() then
    Events.OnGameBoot.Add(function()
        logger:info("[CAF] Applying client-side rules (Client environment)...")

        initClient()
    end)
end
