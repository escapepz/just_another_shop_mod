local JASM_TestRunner = require("jasm_test_shared")

local function init()
    local LootPanelSync = require("just_another_shop_mod/loot_panel_sync")
    local JASM_CustomerViewWindow = require("just_another_shop_mod/entity_ui/customer_view_window")

    -- ============================================================
    -- TEST: Shop Window Switches when Loot Panel Container changes
    -- ============================================================
    JASM_TestRunner.register("loot_panel_sync_switch_on_crate_selection", "client", function()
        -- 1. Setup mocks
        local mockShop = {
            getModData = function(self)
                return { isShop = true }
            end,
            getSprite = function(self)
                return {
                    getName = function()
                        return "carpentry_01_16"
                    end,
                }
            end,
        }

        local switchCalledWith = nil
        local mockWindow = {
            isVisible = true,
            getIsVisible = function(self)
                return self.isVisible
            end,
            switchShop = function(self, entity)
                switchCalledWith = entity
            end,
        }

        local originalInstance = JASM_CustomerViewWindow.instance
        JASM_CustomerViewWindow.instance = mockWindow

        -- Mock getSpecificPlayer which is called in loot_panel_sync
        local originalGetSpecificPlayer = _G.getSpecificPlayer
        _G.getSpecificPlayer = function(id)
            return {
                getPlayerNum = function()
                    return id
                end,
            }
        end

        local mockInventoryPage = {
            player = 0,
            inventory = {
                getParent = function(self)
                    return mockShop
                end,
            },
            onCharacter = false, -- IMPORTANT: false means it's the loot panel
        }

        -- 2. Act: Trigger the exposed selection logic
        LootPanelSync.lastSelectedContainer[0] = nil
        LootPanelSync.onLootContainerSelected(getSpecificPlayer(0), mockInventoryPage.inventory)

        -- 3. Verify
        JASM_TestRunner.assert_equals(
            mockShop,
            switchCalledWith,
            "Customer window should switch shop when loot panel selects a shop container"
        )

        -- 4. Test filtering (Selecting the same container twice should not trigger switch)
        switchCalledWith = nil
        LootPanelSync.onLootContainerSelected(getSpecificPlayer(0), mockInventoryPage.inventory)
        JASM_TestRunner.assert_nil(
            switchCalledWith,
            "Subsequent selection of same container should be ignored"
        )

        -- 5. Test Non-Shop Container
        LootPanelSync.lastSelectedContainer[0] = nil
        local mockNonShop = {
            getModData = function(self)
                return {}
            end,
        }
        mockInventoryPage.inventory.getParent = function()
            return mockNonShop
        end
        switchCalledWith = nil
        LootPanelSync.onLootContainerSelected(getSpecificPlayer(0), mockInventoryPage.inventory)
        JASM_TestRunner.assert_nil(
            switchCalledWith,
            "Customer window should NOT switch for non-shop container"
        )

        -- 6. Test Hidden Window (Should NOT switch if window is hidden)
        LootPanelSync.lastSelectedContainer[0] = nil
        mockInventoryPage.inventory.getParent = function()
            return mockShop
        end
        mockWindow.isVisible = false
        switchCalledWith = nil
        LootPanelSync.onLootContainerSelected(getSpecificPlayer(0), mockInventoryPage.inventory)
        JASM_TestRunner.assert_nil(
            switchCalledWith,
            "Customer window should NOT switch if it is not visible"
        )

        -- Cleanup
        JASM_CustomerViewWindow.instance = originalInstance
        _G.getSpecificPlayer = originalGetSpecificPlayer
    end)

    print("[JASM_TEST] Loot Panel Sync tests registered")
end

return init
