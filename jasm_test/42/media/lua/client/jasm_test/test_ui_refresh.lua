local JASM_TestRunner = require("jasm_test_shared")

local function init()
    -- Load the real UI classes
    local ShopItemDetailsPanel =
        require("just_another_shop_mod/entity_ui/components/shop/customer/shop_item_details_panel")
    local OwnerViewWindow = require("just_another_shop_mod/entity_ui/owner_view_window")

    -- ============================================================
    -- TEST: UI Refresh After Customer Accepts Trade
    -- ============================================================
    JASM_TestRunner.register("ui_refresh_customer_accept_trade", "client", function()
        -- 1. Save originals
        local originalWalkToContainer = luautils.walkToContainer
        local originalISTimedActionQueue = ISTimedActionQueue
        local originalAcceptTradeAction = _G.JASM_AcceptTradeAction

        -- 2. Setup mocks
        local mockDataManager = {
            scanContainer = function(self, container)
                return {
                    list = { { id = "item1", qty = 5 } },
                }
            end,
        }

        local mockProductPanel = {
            productsCalled = false,
            productsArg = nil,
            setProducts = function(self, products)
                self.productsCalled = true
                self.productsArg = products
            end,
        }

        local mockParent = {
            dataManager = mockDataManager,
            productPanel = mockProductPanel,
            inventory = { list = {} },
        }

        local mockAction = {
            onCompleteCb = nil,
            setOnComplete = function(self, cb, arg)
                self.onCompleteCb = cb
            end,
            setOnCancel = function(self, cb, arg) end,
            setOnStart = function(self, cb, arg) end,
        }

        ---@diagnostic disable-next-line: global-in-non-module
        _G.JASM_AcceptTradeAction = {
            new = function(self, ...)
                return mockAction
            end,
        }

        luautils.walkToContainer = function()
            return true
        end

        ISTimedActionQueue = {
            add = function(action) end,
        }

        -- MOCK SELF for ShopItemDetailsPanel
        ---@type any
        local mockSelf = {
            player = {
                getPlayerNum = function()
                    return 0
                end,
            },
            entity = {
                getSquare = function()
                    return {}
                end,
                getContainer = function()
                    return {}
                end,
                getModData = function()
                    return {}
                end,
            },
            product = { type = "Base.Axe", offerQty = 1 },
            requirementsPanel = {
                getSelectedTrade = function()
                    return { requestItem = "Base.Money", requestQty = 10 }
                end,
            },
            parent = mockParent,
            target = {
                refresh = function()
                    mockProductPanel:setProducts({})
                end,
            },
            -- REQUIRED MEMBERS FOR ShopItemDetailsPanel implementation
            updateTradeButton = function(self) end,
            calculateLayout = function(self) end,
        }

        -- 3. Act: Trigger the UI method
        ShopItemDetailsPanel.onAcceptTrade(mockSelf)

        -- 4. Simulate callback execution (set by onAcceptTrade)
        if mockSelf.parent and mockAction.onCompleteCb then
            mockAction.onCompleteCb()
        end

        -- 5. Verify refresh happened
        JASM_TestRunner.assert_true(
            mockProductPanel.productsCalled,
            "Product panel setProducts should be called after customer trade refresh"
        )
        JASM_TestRunner.assert_not_nil(
            mockProductPanel.productsArg,
            "Product panel should receive inventory list"
        )

        -- 6. Cleanup
        luautils.walkToContainer = originalWalkToContainer
        ISTimedActionQueue = originalISTimedActionQueue
        _G.JASM_AcceptTradeAction = originalAcceptTradeAction
    end)

    -- ============================================================
    -- TEST: UI Refresh After Owner Publishes Trade
    -- ============================================================
    JASM_TestRunner.register("ui_refresh_owner_publish_trade", "client", function()
        -- 1. Save originals
        local originalPublishTradeAction = _G.JASM_PublishTradeAction
        local originalISTimedActionQueue = ISTimedActionQueue

        -- 2. Setup mocks
        local mockDataManager = {
            scanContainer = function(self, container)
                return {
                    list = { { id = "item1", qty = 10 } },
                }
            end,
        }

        local mockProductPanel = {
            productsCalled = false,
            productsArg = nil,
            setProducts = function(self, products)
                self.productsCalled = true
                self.productsArg = products
            end,
        }

        local mockAction = {
            onCompleteCb = nil,
            setOnComplete = function(self, cb, arg)
                self.onCompleteCb = cb
            end,
            setOnCancel = function(self, cb, arg) end,
            setOnStart = function(self, cb, arg) end,
        }

        ---@diagnostic disable-next-line: global-in-non-module
        _G.JASM_PublishTradeAction = {
            new = function(self, ...)
                return mockAction
            end,
        }

        ISTimedActionQueue = {
            add = function(action) end,
        }

        -- MOCK SELF for OwnerViewWindow
        ---@type any
        local mockSelf = {
            player = {},
            entity = {
                getX = function()
                    return 0
                end,
                getY = function()
                    return 0
                end,
                getZ = function()
                    return 0
                end,
                getObjectIndex = function()
                    return 0
                end,
                getContainer = function()
                    return {}
                end,
                getModData = function()
                    return {}
                end,
            },
            selectedItem = { type = "Base.Axe", name = "Axe", stock = 10 },
            offerPanel = {
                getQty = function()
                    return 1
                end,
                setYieldInfo = function(self, text) end,
            },
            requirementPaths = { { itemType = "Base.Money", requestQty = 10, name = "Money" } },
            dataManager = mockDataManager,
            productPanel = mockProductPanel,
            inventory = { list = {} },
            footerPanel = {
                setError = function(self, msg) end,
                clearError = function(self) end,
                setSuccess = function(self, msg) end,
            },
            clearError = function(self) end,
            showError = function(self, msg)
                print("Test Error: " .. msg)
            end,
            -- REQUIRED MEMBERS FOR OwnerViewWindow implementation
            hasUnsavedChanges = false,
            isPublishing = false,
            currentPublishAction = nil,
            calculateLayout = function(self) end,
            refresh = function(self)
                self.productPanel:setProducts({})
            end,
        }

        -- 3. Act: Trigger the UI method
        OwnerViewWindow.onPublishClicked(mockSelf)

        -- 4. Simulate callback execution
        if mockAction.onCompleteCb then
            mockAction.onCompleteCb()
        end

        -- 5. Verify refresh happened
        JASM_TestRunner.assert_true(
            mockProductPanel.productsCalled,
            "Product panel setProducts should be called after owner publish refresh"
        )
        JASM_TestRunner.assert_not_nil(
            mockProductPanel.productsArg,
            "Product panel should receive inventory list"
        )

        -- 6. Cleanup
        _G.JASM_PublishTradeAction = originalPublishTradeAction
        ISTimedActionQueue = originalISTimedActionQueue
    end)

    -- ============================================================
    -- TEST: UI Refresh Does Not Fail Without Parent/dataManager
    -- ============================================================
    JASM_TestRunner.register("ui_refresh_graceful_fallback", "client", function()
        -- 1. Save originals
        local originalAcceptTradeAction = _G.JASM_AcceptTradeAction
        local originalWalkToContainer = luautils.walkToContainer
        local originalISTimedActionQueue = ISTimedActionQueue

        -- 2. Setup mock that specifically lacks parent
        local mockAction = {
            onCompleteCb = nil,
            setOnComplete = function(self, cb, arg)
                self.onCompleteCb = cb
            end,
            setOnCancel = function(self, cb, arg) end,
            setOnStart = function(self, cb, arg) end,
        }

        ---@diagnostic disable-next-line: global-in-non-module
        _G.JASM_AcceptTradeAction = {
            new = function(self, ...)
                return mockAction
            end,
        }

        luautils.walkToContainer = function()
            return true
        end
        ISTimedActionQueue = {
            add = function() end,
        }

        -- MOCK SELF for ShopItemDetailsPanel (No Parent)
        ---@type any
        local mockSelf = {
            player = {
                getPlayerNum = function()
                    return 0
                end,
            },
            entity = {
                getSquare = function()
                    return {}
                end,
                getContainer = function()
                    return {}
                end,
                getModData = function()
                    return {}
                end,
            },
            product = { type = "Base.Axe", offerQty = 1 },
            requirementsPanel = {
                getSelectedTrade = function()
                    return { requestItem = "Base.Money", requestQty = 10 }
                end,
            },
            parent = nil, -- CRITICAL: No parent/dataManager
            -- REQUIRED MEMBERS
            updateTradeButton = function(self) end,
            calculateLayout = function(self) end,
        }

        -- 3. Act: Trigger completion logic
        ShopItemDetailsPanel.onAcceptTrade(mockSelf)

        -- 4. Test callback doesn't crash without parent
        local callbackExecuted = false
        local callbackError = nil
        if mockAction.onCompleteCb then
            ---@diagnostic disable-next-line: param-type-mismatch
            if pcall(mockAction.onCompleteCb) then
                callbackExecuted = true
            else
                callbackError = "Callback failed"
            end
        end

        -- 5. Verify safety
        JASM_TestRunner.assert_true(
            callbackExecuted,
            "Callback should execute safely even if parent UI is closed"
        )
        JASM_TestRunner.assert_nil(callbackError, "Callback should not error")

        -- 6. Cleanup
        luautils.walkToContainer = originalWalkToContainer
        ISTimedActionQueue = originalISTimedActionQueue
        _G.JASM_AcceptTradeAction = originalAcceptTradeAction
    end)

    print("[JASM_TEST] UI Refresh tests registered")
end

return init
