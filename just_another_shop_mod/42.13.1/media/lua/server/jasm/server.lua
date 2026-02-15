local ZUL = require("ZUL")

local logger = ZUL.new("ShopSystem")

-- Initialize Shop Manager
local ShopManager = require("jasm/shop_manager")

-- Register Rules
local ruleShopProtection = require("jasm/rules/shop_protection_rule")
local ruleShopAudit = require("jasm/rules/shop_audit_rule")

local CAF = require("container_authority_framework")

local function init()
	logger:info("Just Another Shop Mod initializing...")

	-- Register the Shop Rule with CAF
	CAF:registerRule("validation", "ShopProtection", ruleShopProtection, 10) -- Priority 10
	CAF:registerRule("post", "ShopAudit", ruleShopAudit, 100) -- Lower priority for auditing

	-- Singleton pattern
	if not _G.JASM_ShopManager then
		---@diagnostic disable-next-line: global-in-non-module
		---@type ShopManager
		_G.JASM_ShopManager = ShopManager()
	end

	logger:info("Just Another Shop Mod (CAF-Based) loaded successfully.")

	return _G.JASM_ShopManager
end

return init
