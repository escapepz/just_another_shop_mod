local ZUL = require("zul")
local pz_utils = require("pz_utils_shared")

local initClient = require("just_another_shop_mod/client")

local KUtilities = pz_utils.konijima.Utilities
local logger = ZUL.new("just_another_shop_mod")

if KUtilities.IsClientOrSinglePlayer() then
    -- This Client only so why OnGameBoot?
    Events.OnGameStart.Add(function()
        logger:info("[JASM] Applying client-side rules (Client environment)...")

        initClient()
    end)
end
