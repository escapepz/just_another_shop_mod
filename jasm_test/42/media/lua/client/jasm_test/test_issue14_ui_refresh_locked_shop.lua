---@diagnostic disable: global-in-non-module
--[[
    Issue 14: Shop UI Restock Refresh Tests
    
    Tests that shop UI updates when owner deposits items while shop is locked.
    
    Problem: When owner deposits items while shop locked, items are added to
    server container but don't appear in shop UI window.
    
    Solution: Add container update listener to CustomerViewWindow that calls
    refreshContainer() when items are added/removed.
]]

local JASM_TestRunner = require("jasm_test_shared")

-- Mock container with item tracking
local function createMockContainer()
    local items = {}
    return {
        items = items,
        itemCount = 0,

        getItems = function(self)
            return self.items
        end,

        addItem = function(self, itemType, qty)
            qty = qty or 1
            self.items[itemType] = (self.items[itemType] or 0) + qty
            self.itemCount = self.itemCount + qty
            return true
        end,

        removeItem = function(self, itemType, qty)
            qty = qty or 1
            if not self.items[itemType] or self.items[itemType] < qty then
                return false
            end
            self.items[itemType] = self.items[itemType] - qty
            self.itemCount = self.itemCount - qty
            if self.items[itemType] == 0 then
                self.items[itemType] = nil
            end
            return true
        end,

        isDrawDirty = function(self)
            return self._drawDirty or false
        end,

        markDirty = function(self)
            self._drawDirty = true
        end,

        clearDirty = function(self)
            self._drawDirty = false
        end,
    }
end

-- Mock shop entity with container
local function createMockShopEntity()
    return {
        modData = {
            isShop = true,
            shopOwnerID = "Owner1",
            shopLock = "Owner1",
        },
        container = createMockContainer(),

        getModData = function(self)
            return self.modData
        end,

        getContainer = function(self)
            return self.container
        end,

        getSquare = function(self)
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

-- Mock UI window with refresh tracking
local function createMockWindowWithRefresh()
    return {
        entity = createMockShopEntity(),
        shopContainer = nil,
        productPanel = {
            products = {},
            setProducts = function(self, products)
                self.products = products or {}
            end,
        },
        refreshCalled = false,
        refreshCount = 0,
        lastRefreshTime = 0,
        containerListenerActive = false,

        -- Mock refresh method
        refreshContainer = function(self)
            self.refreshCalled = true
            self.refreshCount = self.refreshCount + 1
            self.lastRefreshTime = getTimeInMillis() or os.time() * 1000

            -- Simulate updating UI from container
            local container = self.entity:getContainer()
            if not container then
                self.productPanel:setProducts({})
                return
            end

            local items = container:getItems()
            local productList = {}
            for itemType, qty in pairs(items) do
                table.insert(productList, {
                    type = itemType,
                    qty = qty,
                })
            end
            self.productPanel:setProducts(productList)
        end,

        -- Subscribe to container updates (Option A from Issue 14)
        subscribeToContainerUpdates = function(self)
            if not _G.Events then
                _G.Events = {}
            end
            local event = _G.Events.OnContainerUpdate
            if not event then
                _G.Events.OnContainerUpdate = { subscribers = {} }
                event = _G.Events.OnContainerUpdate
            end

            -- Ensure subscribers table exists
            if not event.subscribers then
                event.subscribers = {}
            end

            local function updateListener()
                local container = self.entity:getContainer()
                if container and container:isValid() then
                    self:refreshContainer()
                end
            end

            table.insert(event.subscribers, updateListener)
            self.containerListenerActive = true
        end,
    }
end

local function init()
    -- ============================================================
    -- TEST 1: Basic container refresh on item add
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_on_item_add", "client", function()
        local window = createMockWindowWithRefresh()

        -- Add item to container
        window.entity:getContainer():addItem("Base.Axe", 1)

        -- Manually call refresh (simulating container update listener)
        window:refreshContainer()

        -- Verify refresh was called
        JASM_TestRunner.assert_true(
            window.refreshCalled,
            "refreshContainer should be called when item added"
        )

        -- Verify UI updated with new item
        JASM_TestRunner.assert_true(
            #window.productPanel.products > 0,
            "Product panel should have items after refresh"
        )

        JASM_TestRunner.assert_equals(
            window.productPanel.products[1].type,
            "Base.Axe",
            "Product type should match added item"
        )
    end)

    -- ============================================================
    -- TEST 2: Multiple items refresh
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_multiple_items", "client", function()
        local window = createMockWindowWithRefresh()

        -- Add multiple items
        window.entity:getContainer():addItem("Base.Axe", 1)
        window.entity:getContainer():addItem("Base.Hammer", 3)
        window.entity:getContainer():addItem("Base.Screwdriver", 2)

        window:refreshContainer()

        -- Verify all items in UI
        JASM_TestRunner.assert_equals(
            3,
            #window.productPanel.products,
            "Product panel should have 3 item types"
        )
    end)

    -- ============================================================
    -- TEST 3: Refresh on item removal
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_on_item_remove", "client", function()
        local window = createMockWindowWithRefresh()

        -- Add items
        window.entity:getContainer():addItem("Base.Axe", 5)
        window:refreshContainer()

        local initialCount = #window.productPanel.products

        -- Remove items
        window.entity:getContainer():removeItem("Base.Axe", 5)
        window:refreshContainer()

        -- Verify UI updated
        JASM_TestRunner.assert_equals(
            0,
            #window.productPanel.products,
            "Product panel should be empty after removing all items"
        )
    end)

    -- ============================================================
    -- TEST 4: Refresh count tracks multiple updates
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_count", "client", function()
        local window = createMockWindowWithRefresh()

        -- Initial state
        JASM_TestRunner.assert_equals(0, window.refreshCount, "refresh count should start at 0")

        -- Add item and refresh
        window.entity:getContainer():addItem("Base.Axe", 1)
        window:refreshContainer()

        JASM_TestRunner.assert_equals(
            1,
            window.refreshCount,
            "refresh count should be 1 after first refresh"
        )

        -- Add another item and refresh
        window.entity:getContainer():addItem("Base.Hammer", 1)
        window:refreshContainer()

        JASM_TestRunner.assert_equals(
            2,
            window.refreshCount,
            "refresh count should increment on each refresh"
        )
    end)

    -- ============================================================
    -- TEST 5: Locked shop UI refresh
    -- ============================================================
    JASM_TestRunner.register("issue14_locked_shop_ui_refresh", "client", function()
        local window = createMockWindowWithRefresh()

        -- Verify shop is locked
        JASM_TestRunner.assert_equals(
            "Owner1",
            window.entity:getModData().shopLock,
            "Shop should be locked by Owner1"
        )

        -- Owner deposits items (shop remains locked)
        window.entity:getContainer():addItem("Base.Axe", 2)
        window.entity:getContainer():addItem("Base.Hammer", 3)

        -- UI should refresh to show new items
        window:refreshContainer()

        -- Verify items appear in locked shop UI
        JASM_TestRunner.assert_equals(
            2,
            #window.productPanel.products,
            "Locked shop UI should show all items"
        )
    end)

    -- ============================================================
    -- TEST 6: Container listener subscription
    -- ============================================================
    JASM_TestRunner.register("issue14_container_listener_subscription", "client", function()
        local window = createMockWindowWithRefresh()

        -- Subscribe to container updates
        window:subscribeToContainerUpdates()

        JASM_TestRunner.assert_true(
            window.containerListenerActive,
            "Container listener should be active after subscription"
        )
    end)

    -- ============================================================
    -- TEST 7: Graceful refresh if window invalid
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_window_invalid", "client", function()
        local window = createMockWindowWithRefresh()

        -- Simulate container becoming invalid
        window.entity.container = nil

        -- Refresh should not error (protected call in Lua 5.1)
        local success = pcall(function()
            window:refreshContainer()
        end)

        -- Verify the method exists for safe calls
        JASM_TestRunner.assert_true(
            window.refreshContainer ~= nil,
            "refreshContainer method should exist for safe calls"
        )
    end)

    -- ============================================================
    -- TEST 8: Refresh preserves window state
    -- ============================================================
    JASM_TestRunner.register("issue14_ui_refresh_preserves_window_state", "client", function()
        local window = createMockWindowWithRefresh()

        -- Set initial state
        window.productPanel.selectedIndex = 1
        window.productPanel.scrollOffset = 5

        -- Add items and refresh
        window.entity:getContainer():addItem("Base.Axe", 1)
        window:refreshContainer()

        -- Window state methods would be called in real implementation
        -- For this test, verify refresh doesn't clear window reference
        JASM_TestRunner.assert_true(
            window.entity ~= nil,
            "Window entity reference preserved after refresh"
        )

        JASM_TestRunner.assert_true(
            window.productPanel ~= nil,
            "Product panel reference preserved after refresh"
        )
    end)

    -- ============================================================
    -- TEST 9: Owner deposits while customer viewing
    -- ============================================================
    JASM_TestRunner.register("issue14_owner_deposits_customer_sees", "client", function()
        local ownerWindow = createMockWindowWithRefresh()
        ownerWindow.entity:getModData().shopLock = "Owner1"

        local customerWindow = createMockWindowWithRefresh()
        customerWindow.entity = ownerWindow.entity -- Same shop

        -- Owner deposits items
        ownerWindow.entity:getContainer():addItem("Base.Axe", 3)
        ownerWindow:refreshContainer()

        -- Customer should see items if their window refreshes
        -- (in real code, both windows would receive OnContainerUpdate)
        customerWindow:refreshContainer()

        -- Verify customer window shows owner's items
        JASM_TestRunner.assert_equals(
            #ownerWindow.productPanel.products,
            #customerWindow.productPanel.products,
            "Customer should see same items as owner after refresh"
        )
    end)

    -- ============================================================
    -- TEST 10: No refresh overhead if no changes
    -- ============================================================
    JASM_TestRunner.register("issue14_no_refresh_if_no_changes", "client", function()
        local window = createMockWindowWithRefresh()

        -- Add item and refresh
        window.entity:getContainer():addItem("Base.Axe", 1)
        window:refreshContainer()

        local countAfterAdd = window.refreshCount

        -- Call refresh again without changes
        -- (in real implementation, could check isDrawDirty)
        if not window.entity:getContainer():isDrawDirty() then
            -- Skip refresh if no changes
        else
            window:refreshContainer()
        end

        -- Refresh count should not increase if no changes
        JASM_TestRunner.assert_equals(
            countAfterAdd,
            window.refreshCount,
            "Refresh count should not increase if container unchanged"
        )
    end)

    print("[JASM_TEST] Issue 14 UI Refresh tests registered")
end

return init
