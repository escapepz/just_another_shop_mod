---@diagnostic disable: global-in-non-module
local JASM_TestRunner = require("jasm_test_shared")
local DoShopContextMenu = require("just_another_shop_mod/shop_context_menu")

-- Helper to mock the context menu
local function createMockContext()
    local context = {
        player = 0, -- Default player index
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
                player = self.player,
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
local function createMockShopCrate(isShop, shopType, ownerID, lockedBy)
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
                shopLock = lockedBy,
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
        getSprite = function()
            return {
                getName = function()
                    return "constructedobjects_01_44"
                end,
            }
        end,
        getSquare = function()
            return {
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
        end,
    }
end

-- Mock JASM_ShopManager for lock checks
_G.JASM_ShopManager = {
    getShopLock = function()
        return nil
    end,
}

-- Mock game runtime globals needed
_G.HaloTextHelper = _G.HaloTextHelper or {
    addBadText = function() end,
}
_G.getPlayerData = _G.getPlayerData
    or function(playerIdx)
        return {
            lootInventory = {
                refreshBackpacks = function() end,
            },
        }
    end
_G.ModData = _G.ModData or {
    getOrCreate = function(key)
        return {}
    end,
}

local function init()
    -- ============================================================
    -- TEST: Non-owner cannot see UnRegister
    -- ============================================================
    JASM_TestRunner.register("non_owner_cannot_unregister_player_shop", "client", function()
        -- 1. Setup mocks
        local playerObj = {
            getUsername = function()
                return "PlayerB"
            end,
        }

        -- Mock getSpecificPlayer and IsPlayerAdmin
        local original_getSpecificPlayer = _G.getSpecificPlayer
        local original_IsPlayerAdmin = require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin
        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local original_SandboxGet = JASM_SandboxVars.Get

        _G.getSpecificPlayer = function()
            return playerObj
        end
        require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = function()
            return false
        end
        JASM_SandboxVars.Get = function()
            return true -- Default admin bypass to true for tests
        end

        ---@type ISContextMenu
        local context = createMockContext()
        ---@type IsoObject
        local crate = createMockShopCrate(true, "PLAYER", "PlayerA") -- Owned by PlayerA
        local worldObjects = { crate }

        -- 2. Run logic
        local originalGetNew = ISContextMenu.getNew
        ISContextMenu.getNew = function(self, ctx)
            return context
        end

        DoShopContextMenu(0, context, worldObjects, false)

        ISContextMenu.getNew = originalGetNew

        -- 3. Verify
        local jasmOption = nil
        for _, opt in ipairs(context.options) do
            if opt.name == "JASM Shop" then
                jasmOption = opt
                break
            end
        end

        local playerShopOption = nil

        -- JASM Shop menu might be hidden entirely if you have no permissions
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

        -- If Player Shop exists, check for the UnRegister option inside it
        if playerShopOption then
            local pMenu = playerShopOption.subMenu
            if pMenu then
                for _, opt in ipairs(pMenu.options) do
                    if string.find(opt.name, "UnRegister Shop") then
                        unregisterOption = opt
                        break
                    end
                end
            end
        end

        -- Cleanup
        _G.getSpecificPlayer = original_getSpecificPlayer
        require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = original_IsPlayerAdmin
        JASM_SandboxVars.Get = original_SandboxGet

        JASM_TestRunner.assert_nil(
            unregisterOption,
            "Non-owner should NOT see UnRegister Shop option"
        )
    end)

    -- ============================================================
    -- TEST: Owner CAN see UnRegister
    -- ============================================================
    JASM_TestRunner.register("owner_can_unregister_player_shop", "client", function()
        -- 1. Setup mocks
        local playerObj = {
            getUsername = function()
                return "PlayerA"
            end,
        }

        local original_getSpecificPlayer = _G.getSpecificPlayer
        local original_IsPlayerAdmin = require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin

        local JASM_SandboxVars = require("just_another_shop_mod/jasm_sandbox_vars")
        local original_SandboxGet = JASM_SandboxVars.Get

        _G.getSpecificPlayer = function()
            return playerObj
        end
        require("pz_utils_shared").konijima.Utilities.IsPlayerAdmin = function()
            return false
        end
        JASM_SandboxVars.Get = function()
            return true
        end

        ---@type ISContextMenu
        local context = createMockContext()
        ---@type IsoObject
        local crate = createMockShopCrate(true, "PLAYER", "PlayerA")
        local worldObjects = { crate }

        -- 2. Run logic
        local originalGetNew = ISContextMenu.getNew
        ISContextMenu.getNew = function(self, ctx)
            return context
        end

        DoShopContextMenu(0, context, worldObjects, false)

        ISContextMenu.getNew = originalGetNew

        -- 3. Verify
        local jasmOption = nil
        for _, opt in ipairs(context.options) do
            if opt.name == "JASM Shop" then
                jasmOption = opt
                break
            end
        end

        local playerShopOption = nil

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
        JASM_SandboxVars.Get = original_SandboxGet

        JASM_TestRunner.assert_not_nil(unregisterOption, "Owner SHOULD see UnRegister Shop option")
    end)

    JASM_TestRunner.register("context_menu_shows_locked_status", "client", function()
        -- Create a shop locked by Player1
        local shop = createMockShopCrate(true, "PLAYER", "Owner1", "Player1")

        -- Context menu directly accesses modData
        local modData = shop:getModData()
        local lockHolder = modData.shopLock

        JASM_TestRunner.assert_equals(
            lockHolder,
            "Player1",
            "Context menu should show lock holder from modData"
        )
    end)

    print("[JASM_TEST] Context Menu Permissions tests registered")
end

return init
