---@diagnostic disable: global-in-non-module
local JASM_TestRunner = require("jasm_test_shared")
local DoShopContextMenu = require("just_another_shop_mod/shop_context_menu")

-- Helper to mock the context menu
local function createMockContext()
    local context = {
        options = {},
        addOption = function(self, name, target, onSelect, ...)
            local opt =
                { name = name, target = target, onSelect = onSelect, args = { ... }, subMenu = nil }
            table.insert(self.options, opt)
            return opt
        end,
        addSubMenu = function(self, option, menu)
            option.subMenu = menu
        end,
        getNew = function(self)
            return {
                options = {},
                addOption = self.addOption,
                addSubMenu = self.addSubMenu,
                getNew = self.getNew,
            }
        end,
    }
    return context
end

-- Helper to mock an IsoObject (Shop Crate)
local function createMockShopCrate(isShop, shopType, ownerID)
    return {
        getContainer = function()
            return {}
        end,
        getObjectName = function()
            return "Thumpable"
        end,
        getEntityFullTypeDebug = function()
            return "Base.Wood_Crate_Lvl1"
        end,
        getEntityDisplayName = function()
            return "Wood Crate"
        end,
        getModData = function()
            return {
                isShop = isShop,
                shopType = shopType,
                shopOwnerID = ownerID,
            }
        end,
        getObjectIndex = function()
            return 0
        end,
        getX = function()
            return 0
        end,
        getY = function()
            return 0
        end,
        getZ = function()
            return 0
        end,
    }
end

-- ============================================================
-- TEST: Non-owner cannot see UnRegister
-- ============================================================
JASM_TestRunner.register(
    "non_owner_cannot_unregister_player_shop",
    "context_menu_permissions",
    function()
        -- 1. Setup mocks
        local playerObj = {
            getUsername = function()
                return "PlayerB"
            end,
        }

        -- Mock getSpecificPlayer and IsPlayerAdmin
        local original_getSpecificPlayer = _G.getSpecificPlayer
        local original_IsPlayerAdmin = require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin

        _G.getSpecificPlayer = function()
            return playerObj
        end
        require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = function()
            return false
        end

        ---@type ISContextMenu
        local context = createMockContext()
        ---@type IsoObject
        local crate = createMockShopCrate(true, "PLAYER", "PlayerA") -- Owned by PlayerA
        local worldObjects = { crate }

        -- 2. Run logic
        DoShopContextMenu(0, context, worldObjects, false)

        -- 3. Verify
        local jasmOption = nil
        for _, opt in ipairs(context.options) do
            if opt.name == "JASM Shop" then
                jasmOption = opt
                break
            end
        end

        local playerShopOption = nil
        JASM_TestRunner.assert_not_nil(jasmOption, "JASM Shop option should exist")
        ---@diagnostic disable-next-line: unnecessary-if
        if jasmOption then
            local jMenu = jasmOption.subMenu
            JASM_TestRunner.assert_not_nil(jMenu, "JASM Shop should have a submenu")

            if jMenu then
                for _, opt in ipairs(jMenu.options) do
                    if opt.name == "Player Shop" then
                        playerShopOption = opt
                        break
                    end
                end
            end
        end

        local unregisterOption = nil
        JASM_TestRunner.assert_not_nil(playerShopOption, "Player Shop option should exist")
        ---@diagnostic disable-next-line: unnecessary-if
        if playerShopOption then
            local pMenu = playerShopOption.subMenu
            JASM_TestRunner.assert_not_nil(pMenu, "Player Shop should have a submenu")
            for _, opt in ipairs(pMenu.options) do
                if string.find(opt.name, "UnRegister Shop") then
                    unregisterOption = opt
                    break
                end
            end
        end

        -- Cleanup
        _G.getSpecificPlayer = original_getSpecificPlayer
        require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = original_IsPlayerAdmin

        JASM_TestRunner.assert_nil(
            unregisterOption,
            "Non-owner should NOT see UnRegister Shop option"
        )
    end
)

-- ============================================================
-- TEST: Owner CAN see UnRegister
-- ============================================================
JASM_TestRunner.register("owner_can_unregister_player_shop", "context_menu_permissions", function()
    -- 1. Setup mocks
    local playerObj = {
        getUsername = function()
            return "PlayerA"
        end,
    }

    local original_getSpecificPlayer = _G.getSpecificPlayer
    local original_IsPlayerAdmin = require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin

    _G.getSpecificPlayer = function()
        return playerObj
    end
    require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = function()
        return false
    end

    ---@type ISContextMenu
    local context = createMockContext()
    ---@type IsoObject
    local crate = createMockShopCrate(true, "PLAYER", "PlayerA")
    local worldObjects = { crate }

    -- 2. Run logic
    DoShopContextMenu(0, context, worldObjects, false)

    -- 3. Verify
    local jasmOption = nil
    for _, opt in ipairs(context.options) do
        if opt.name == "JASM Shop" then
            jasmOption = opt
            break
        end
    end

    local playerShopOption = nil
    ---@diagnostic disable-next-line: unnecessary-if
    if jasmOption then
        local jMenu = jasmOption.subMenu
        for _, opt in ipairs(jMenu.options) do
            if opt.name == "Player Shop" then
                playerShopOption = opt
                break
            end
        end
    end

    local unregisterOption = nil
    ---@diagnostic disable-next-line: unnecessary-if
    if playerShopOption then
        local pMenu = playerShopOption.subMenu
        for _, opt in ipairs(pMenu.options) do
            if string.find(opt.name, "UnRegister Shop") then
                unregisterOption = opt
                break
            end
        end
    end

    -- Cleanup
    _G.getSpecificPlayer = original_getSpecificPlayer
    require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = original_IsPlayerAdmin

    JASM_TestRunner.assert_not_nil(unregisterOption, "Owner SHOULD see UnRegister Shop option")
end)

print("[JASM_TEST] Context Menu Permissions tests registered")
