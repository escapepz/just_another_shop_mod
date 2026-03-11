---@diagnostic disable: global-in-non-module
local JASM_TestRunner = require("jasm_test_shared")

local function init()
    local ShopItemDetailsPanel =
        require("just_another_shop_mod/entity_ui/components/shop/customer/shop_item_details_panel")
    local ShopItemRequirementsPanel = require(
        "just_another_shop_mod/entity_ui/components/shop/customer/shop_item_requirements_panel"
    )

    -- ============================================================
    -- TEST: item_type_inventory_lookup_mismatch
    -- Shop item details panel should properly resolve short names into full names
    -- ============================================================
    JASM_TestRunner.register("item_type_inventory_lookup_mismatch", "client", function()
        -- Save original ScriptManager
        local originalScriptManager = _G.ScriptManager

        -- Mock ScriptManager
        _G.ScriptManager = {
            instance = {
                getItem = function(self, itemName)
                    if itemName == "Sledgehammer" then
                        return {
                            getFullName = function()
                                return "Base.Sledgehammer"
                            end,
                        }
                    end
                    return nil
                end,
            },
        }

        ---@type any
        local panel = ShopItemDetailsPanel:new(0, 0, 10, 10, nil, nil)

        -- Mock UI components
        panel.requirementsPanel = {
            setTrades = function(self, trades)
                self.tradesReceived = trades
            end,
        }

        panel.headerPanel = { setItem = function() end }
        panel.givesPanel = { setItem = function() end }
        panel.footerPanel = { setTradeEnabled = function() end, setError = function() end }

        panel.entity = {
            getModData = function()
                return {
                    shopTrades = {
                        ["Base.Axe"] = {
                            offerQty = 1,
                            paths = {
                                { requestItem = "Sledgehammer", requestQty = 1 },
                            },
                        },
                    },
                }
            end,
        }

        panel.inventory = {
            map = {
                ["Base.Sledgehammer"] = { count = 5, icon = "sledge_icon" },
            },
        }

        -- Act
        panel.calculateLayout = function() end
        panel.updateTradeButton = function() end

        ---@type any
        local product = { type = "Base.Axe", name = "Axe" }
        panel:setProduct(product)

        ---@type any
        local trades = panel.requirementsPanel.tradesReceived

        JASM_TestRunner.assert_not_nil(trades, "should receive trades")
        JASM_TestRunner.assert_equals(1, #trades, "should receive 1 trade path")
        JASM_TestRunner.assert_equals(
            "Base.Sledgehammer",
            trades[1].requestItem,
            "requestItem should be normalized to full name"
        )
        JASM_TestRunner.assert_equals(
            5,
            trades[1].hasCount,
            "hasCount should be successfully resolved via normalized lookup"
        )
        JASM_TestRunner.assert_equals(
            "sledge_icon",
            trades[1].icon,
            "icon should be resolved via normalized lookup"
        )

        -- Cleanup
        _G.ScriptManager = originalScriptManager
    end)

    -- ============================================================
    -- TEST: customer_view_ambiguous_item_types
    -- Customer option items should explicitly state their full name, not display name
    -- ============================================================
    JASM_TestRunner.register("customer_view_ambiguous_item_types", "client", function()
        local originalScriptManager = _G.ScriptManager
        local textureUtilsLoaded, TextureUtils =
            pcall(require, "just_another_shop_mod/entity_ui/utils/texture_utils")
        local originalGetItemTexture = nil

        if textureUtilsLoaded and TextureUtils then
            originalGetItemTexture = TextureUtils.getItemTexture
            TextureUtils.getItemTexture = function()
                return nil
            end
        end

        -- Mock ScriptManager
        _G.ScriptManager = {
            instance = {
                getItem = function(self, itemName)
                    if itemName == "Base.Sledgehammer" then
                        return {
                            getFullName = function()
                                return "Base.Sledgehammer"
                            end,
                        }
                    end
                    return nil
                end,
            },
        }

        ---@type any
        local mockListbox = {
            selected = -1,
            mouseoverselected = -1,
            width = 100,
            drawRect = function() end,
            drawRectBorder = function() end,
            drawTextureScaled = function() end,
            drawText = function(self, text, x, y, r, g, b, a, font)
                self.lastDrawnNames = self.lastDrawnNames or {}
                table.insert(self.lastDrawnNames, text)
            end,
        }

        local mockFont = {}
        local originalUIFont = _G.UIFont
        _G.UIFont = { Small = mockFont, Large = mockFont }

        ---@type any
        local item = {
            height = 20,
            item = {
                requestItem = "Base.Sledgehammer",
                hasCount = 1,
                requestQty = 1,
            },
        }

        -- Act
        ShopItemRequirementsPanel.doDrawReqItem(mockListbox, 0, item, false)

        JASM_TestRunner.assert_not_nil(mockListbox.lastDrawnNames, "drawText should be called")
        JASM_TestRunner.assert_equals(
            "Base.Sledgehammer",
            mockListbox.lastDrawnNames[1],
            "Name should be the full name to prevent UI ambiguity"
        )

        -- Cleanup
        _G.ScriptManager = originalScriptManager
        _G.UIFont = originalUIFont

        if textureUtilsLoaded and TextureUtils and originalGetItemTexture then
            TextureUtils.getItemTexture = originalGetItemTexture
        end
    end)
end

return init
