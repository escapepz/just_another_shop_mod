-- ============================================================================
-- test.lua
-- Test file for shop_view_owner.lua
-- ============================================================================

require("shop_view_owner")

-- ============================================================================
-- TEST FUNCTION
-- ============================================================================

function TestShopViewOwner()
	print("Loading shop_view_owner.lua...")
	
	-- The JASM_ShopView_Owner class is now available
	-- You can create instances and test methods here
	
	print("✓ shop_view_owner.lua loaded successfully")
	print("JASM_ShopView_Owner class is available")
	
	-- Example usage:
	-- local shopView = JASM_ShopView_Owner:new(0, 0, 800, 600, player, entity)
	-- shopView:initialise()
	-- shopView:createChildren()
end

return {
	TestShopViewOwner = TestShopViewOwner
}
