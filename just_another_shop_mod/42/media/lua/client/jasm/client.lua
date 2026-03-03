local CAF = require("container_authority_framework")

-- JASM CAF Rules
local RuleShopProtection = require("jasm/rules/caf/shop_protection_rule")
local RuleShopTrade = require("jasm/rules/caf/shop_trade_rule")
local RuleShopAudit = require("jasm/rules/caf/shop_audit_rule")

local OnServerCommand = require("jasm/shop_client_commands")
local ShopContextMenu = require("jasm/shop_context_menu")

local function InitCAF()
    -- Register the Shop Rules with CAF

    -- Trade Rules
    CAF:registerRule("validation", "ShopTradeCheck", RuleShopTrade.Validation, 5) -- Priority 5 (Must run before Protection)
    CAF:registerRule("pre", "ShopPayment", RuleShopTrade.Payment, 5)

    -- Protection Rules
    CAF:registerRule("validation", "ShopProtection", RuleShopProtection, 10) -- Priority 10

    -- Audit Rules
    CAF:registerRule("post", "ShopAudit", RuleShopAudit, 100) -- Lower priority for auditing
end

local function Init()
    InitCAF()

    Events.OnServerCommand.Add(OnServerCommand)
    Events.OnFillWorldObjectContextMenu.Add(ShopContextMenu)
end

return Init
