local ZUL = require("ZUL")
local CAF = require("container_authority_framework")

-- Initialize Shop Manager
local ShopManager = require("jasm/shop_manager")

-- Register Rules
local RuleShopProtection = require("jasm/rules/shop_protection_rule")
local RuleShopAudit = require("jasm/rules/shop_audit_rule")

local ServerCommand = require("jasm/shop_server_commands")

local logger = ZUL.new("ShopSystem")

local function Init()
	logger:info("Just Another Shop Mod initializing...")

	-- Register the Shop Rule with CAF
	CAF:registerRule("validation", "ShopProtection", RuleShopProtection, 10) -- Priority 10
	CAF:registerRule("post", "ShopAudit", RuleShopAudit, 100) -- Lower priority for auditing

	-- Singleton pattern
	if not _G.JASM_ShopManager then
		---@diagnostic disable-next-line: global-in-non-module
		---@type ShopManager
		_G.JASM_ShopManager = ShopManager()
	end

	Events.OnClientCommand.Add(ServerCommand)

	logger:info("Just Another Shop Mod (CAF-Based) loaded successfully.")

	return _G.JASM_ShopManager
end

return Init
