local ZUL = require("zul")
local CAF = require("container_authority_framework")

-- Initialize Shop Manager
local ShopManager = require("jasm/shop_manager")

-- Register Rules
local RuleShopProtection = require("jasm/rules/shop_protection_rule")
local RuleShopTrade = require("jasm/rules/shop_trade_rule")
local RuleShopAudit = require("jasm/rules/shop_audit_rule")

local ServerCommand = require("jasm/shop_server_commands")

local logger = ZUL.new("just_another_shop_mod")

local function Init()
    logger:info("Just Another Shop Mod initializing...")

    -- Register the Shop Rules with CAF

    -- Trade Rules
    CAF:registerRule("validation", "ShopTradeCheck", RuleShopTrade.Validation, 5) -- Priority 5 (Must run before Protection)
    CAF:registerRule("pre", "ShopPayment", RuleShopTrade.Payment, 5)

    -- Protection Rules
    CAF:registerRule("validation", "ShopProtection", RuleShopProtection, 10) -- Priority 10

    -- Audit Rules
    CAF:registerRule("post", "ShopAudit", RuleShopAudit, 100) -- Lower priority for auditing

    -- Singleton pattern
    if not _G.JASM_ShopManager then
        ---@diagnostic disable-next-line: global-in-non-module
        ---@type ShopManager
        _G.JASM_ShopManager = ShopManager()
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    Events.OnClientCommand.Add(ServerCommand)

    logger:info("Just Another Shop Mod (CAF-Based) loaded successfully.")

    return _G.JASM_ShopManager
end

return Init
