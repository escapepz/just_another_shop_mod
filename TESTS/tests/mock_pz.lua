---@diagnostic disable: global-in-non-module
--[[
    Project Zomboid API Mocks
    
    Provides stubs for PZ classes and globals used in tests.
    Mocks: ItemContainer, IsoPlayer, IsoObject, modData, etc.
]]

local MockPZ = {}

-- Global stubs
_G.print = _G.print or function(...) end

---Mock ItemContainer
function MockPZ.createItemContainer()
    return {
        items = {},
        parent = nil,
        type = "container",
        capacityWeight = 50.0,

        getParent = function(self)
            return self.parent
        end,

        setParent = function(self, parent)
            self.parent = parent
        end,

        getType = function(self)
            return self.type
        end,

        getCapacityWeight = function(self)
            return self.capacityWeight
        end,

        getContentsWeight = function(self)
            local weight = 0.0
            for _, list in pairs(self.items) do
                for _, item in ipairs(list) do
                    if item.getActualWeight then
                        weight = weight + item:getActualWeight()
                    elseif item.weight then
                        weight = weight + item.weight
                    else
                        weight = weight + 0.1
                    end
                end
            end
            return weight
        end,

        getItems = function(self)
            local flat = {}
            for _, list in pairs(self.items) do
                for _, item in ipairs(list) do
                    table.insert(flat, item)
                end
            end
            return {
                size = function()
                    return #flat
                end,
                get = function(_, i)
                    return flat[i + 1]
                end,
            }
        end,

        getItemCount = function(self, itemType)
            if not self.items[itemType] then
                return 0
            end
            return #self.items[itemType]
        end,

        contains = function(self, item)
            local itemType = type(item) == "table" and item:getFullType() or item
            if not self.items[itemType] then
                return false
            end
            if type(item) == "table" then
                for _, it in ipairs(self.items[itemType]) do
                    if it == item then
                        return true
                    end
                end
                return false
            end
            return #self.items[itemType] > 0
        end,

        addItem = function(self, itemOrType)
            local item
            local itemType
            if type(itemOrType) == "table" then
                item = itemOrType
                itemType = item:getFullType()
            else
                itemType = itemOrType
                item = MockPZ.createInventoryItem(itemType)
            end
            self.items[itemType] = self.items[itemType] or {}
            table.insert(self.items[itemType], item)
        end,

        AddItem = function(self, itemOrType)
            return self:addItem(itemOrType)
        end,

        removeItem = function(self, itemOrType)
            local itemType = type(itemOrType) == "table" and itemOrType:getFullType() or itemOrType
            if self.items[itemType] and #self.items[itemType] > 0 then
                if type(itemOrType) == "table" then
                    for i, it in ipairs(self.items[itemType]) do
                        if it == itemOrType then
                            table.remove(self.items[itemType], i)
                            return
                        end
                    end
                else
                    table.remove(self.items[itemType], 1)
                end
            end
        end,

        Remove = function(self, itemOrType)
            return self:removeItem(itemOrType)
        end,

        getContainer = function(self)
            return self
        end,
    }
end

---Mock IsoObject (furniture, appliances, etc.)
function MockPZ.createIsoObject()
    return {
        modData = {},
        square = nil,
        sprite = "test_object",

        getModData = function(self)
            return self.modData
        end,

        getSquare = function(self)
            return self.square
        end,

        setSquare = function(self, square)
            self.square = square
        end,

        getSprite = function(self)
            return self.sprite
        end,

        getContainer = function(self)
            return nil -- Not all objects have containers
        end,
    }
end

---Mock IsoPlayer
function MockPZ.createIsoPlayer(username, isAdmin)
    return {
        username = username or "TestPlayer",
        admin = isAdmin or false,
        inventory = MockPZ.createItemContainer(),
        playerNum = 0,

        getUsername = function(self)
            return self.username
        end,

        isAdmin = function(self)
            return self.admin
        end,

        getInventory = function(self)
            return self.inventory
        end,

        getPlayerNum = function(self)
            return self.playerNum
        end,

        getSquare = function(self)
            return self.square
        end,

        DistTo = function(self, x, y)
            if type(x) == "table" then
                return IsoUtils.DistanceTo(
                    self.x or 0,
                    self.y or 0,
                    self.z or 0,
                    x:getX(),
                    x:getY(),
                    x:getZ()
                )
            end
            return IsoUtils.DistanceTo2D(self.x or 0, self.y or 0, x, y)
        end,

        DistTo2D = function(self, x, y)
            return IsoUtils.DistanceTo2D(self.x or 0, self.y or 0, x, y)
        end,
    }
end

---Mock Square (grid position)
function MockPZ.createSquare(x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        objects = {},

        getObjects = function(self)
            return self.objects
        end,

        addObject = function(self, obj)
            table.insert(self.objects, obj)
        end,

        getX = function(self)
            return self.x
        end,
        getY = function(self)
            return self.y
        end,
        getZ = function(self)
            return self.z
        end,
    }
end

---Mock InventoryItem
function MockPZ.createInventoryItem(itemType, count)
    return {
        type = itemType or "Base.Item",
        count = count or 1,
        weight = 0.1,

        getFullType = function(self)
            return self.type
        end,

        getActualWeight = function(self)
            return self.weight
        end,

        setWeight = function(self, weight)
            self.weight = weight
        end,

        getCount = function(self)
            return self.count
        end,
    }
end

---Mock global utilities
function MockPZ.setupGlobals()
    -- Mock middleclass for OOP
    if not _G.middleclass then
        _G.middleclass = function(name)
            local class = {
                __name = name,
            }
            class.__index = class

            function class.new(...)
                local instance = setmetatable({}, class)
                if instance.initialize then
                    instance:initialize(...)
                end
                return instance
            end

            -- Allow direct call syntax: MyClass()
            setmetatable(class, {
                __call = function(cls, ...)
                    return cls.new(...)
                end,
            })

            return class
        end
    end

    -- Mock getSquare function
    if not _G.getSquare then
        _G.getSquare = function(x, y, z)
            return MockPZ.createSquare(x, y, z)
        end
    end

    -- Mock ModData
    if not _G.ModData then
        local globalModData = {}
        _G.ModData = {
            getOrCreate = function(key)
                if not globalModData[key] then
                    globalModData[key] = {}
                end
                return globalModData[key]
            end,
            get = function(key)
                return globalModData[key]
            end,
            add = function(key, val)
                globalModData[key] = val
            end,
            exists = function(key)
                return globalModData[key] ~= nil
            end,
            transmit = function(key) end,
            request = function(key) end,
        }
    end

    -- Mock networking and system globals
    _G.isClient = _G.isClient or function()
        return false
    end
    _G.isServer = _G.isServer or function()
        return false
    end

    -- Mock time function
    _G.getTimeInMillis = _G.getTimeInMillis or function()
        return os.time() * 1000
    end

    _G.sendClientCommand = _G.sendClientCommand or function(...) end
    _G.sendServerCommand = _G.sendServerCommand or function(...) end
    _G.triggerEvent = _G.triggerEvent or function(...) end

    -- Mock IsoUtils
    if not _G.IsoUtils then
        _G.IsoUtils = {
            DistanceTo = function(x1, y1, z1, x2, y2, z2)
                return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2 + (z1 - z2) ^ 2)
            end,
            DistanceTo2D = function(x1, y1, x2, y2)
                return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
            end,
        }
    end

    -- Mock getSpecificPlayer
    if not _G.getSpecificPlayer then
        _G.getSpecificPlayer = function(id)
            local p = MockPZ.createIsoPlayer("TestPlayer_" .. tostring(id), false)
            p.playerNum = id
            return p
        end
    end

    -- Mock luautils
    if not _G.luautils then
        _G.luautils = {
            walkAdj = function(player, square, isWalk) end,
            walkToContainer = function(container, playerNum)
                return true
            end,
            okModal = function(text, centerX, centerY, target, onOk) end,
        }
    end

    -- Mock AdjacentFreeTileFinder
    if not _G.AdjacentFreeTileFinder then
        _G.AdjacentFreeTileFinder = {
            isTileOrAdjacent = function(sq1, sq2)
                return true
            end,
            Find = function(sq, player)
                return sq
            end,
        }
    end

    -- Mock ISWorldObjectContextMenu
    if not _G.ISWorldObjectContextMenu then
        _G.ISWorldObjectContextMenu = {
            addToolTip = function()
                return {
                    setName = function(self, name) end,
                }
            end,
        }
    end

    -- Mock ISContextMenu
    if not _G.ISContextMenu then
        _G.ISContextMenu = {
            getNew = function(self, playerOrParent)
                local o = {
                    player = (type(playerOrParent) == "table" and playerOrParent.player)
                        or playerOrParent
                        or 0,
                    addOption = function(self, name, target, onSelect, ...) end,
                    addSubMenu = function(self, option, menu) end,
                }
                o.getNew = self.getNew
                return o
            end,
        }
    end

    -- Mock ISTimedActionQueue
    if not _G.ISTimedActionQueue then
        _G.ISTimedActionQueue = {
            add = function(action) end,
        }
    end

    -- Mock Events system
    if not _G.Events then
        _G.Events = setmetatable({}, {
            __index = function(t, k)
                t[k] = {
                    Add = function(fn) end,
                    Remove = function(fn) end,
                    subscribers = {}, -- For OnContainerUpdate listeners in tests
                }
                return t[k]
            end,
        })
    end

    -- Mock ScriptManager
    if not _G.ScriptManager then
        _G.ScriptManager = {
            instance = {
                getItem = function(self, type)
                    return {
                        getActualWeight = function()
                            return 0.1
                        end,
                    }
                end,
            },
        }
    end

    -- Mock getCore
    if not _G.getCore then
        _G.getCore = function()
            return {
                getGameVersion = function()
                    return "v42"
                end,
            }
        end
    end

    -- Mock HaloTextHelper
    if not _G.HaloTextHelper then
        _G.HaloTextHelper = {
            addBadText = function(player, text) end,
            addText = function(player, text) end,
        }
    end

    -- Mock JASM_AcceptTradeAction and JASM_PublishTradeAction
    _G.JASM_AcceptTradeAction = {
        new = function(self, player, entity, payload)
            return {}
        end,
    }
    _G.JASM_PublishTradeAction = {
        new = function(self, player, entity, payload)
            return {}
        end,
    }

    -- Mock required mod/PZ modules via package.preload
    package.preload["pz_utils_shared"] = function()
        return {
            konijima = {
                Utilities = {
                    IsPlayerAdmin = function(player)
                        return false
                    end,
                    SendClientCommand = function(...) end,
                    SendServerCommandTo = function(...) end,
                    SquareToString = function(square)
                        return "0,0,0"
                    end,
                },
            },
            escape = {
                SandboxVarsModule = (function()
                    local _store = {}
                    return {
                        Init = function(namespace, defaults)
                            _store[namespace] = _store[namespace] or {}
                            for k, v in pairs(defaults) do
                                if _store[namespace][k] == nil then
                                    _store[namespace][k] = v
                                end
                            end
                        end,
                        Create = function(name, defaults)
                            _store[name] = _store[name] or {}
                            for k, v in pairs(defaults) do
                                if _store[name][k] == nil then
                                    _store[name][k] = v
                                end
                            end
                            local ns = name
                            return {
                                Get = function(key, default)
                                    if _store[ns][key] ~= nil then
                                        return _store[ns][key]
                                    end
                                    return default
                                end,
                            }
                        end,
                        Get = function(namespace, key, default)
                            if _store[namespace] and _store[namespace][key] ~= nil then
                                return _store[namespace][key]
                            end
                            return default
                        end,
                        GetAll = function(namespace)
                            return _store[namespace] or {}
                        end,
                    }
                end)(),
            },
        }
    end

    package.preload["pz_lua_commons_shared"] = function()
        return {
            kikito = {
                middleclass = _G.middleclass,
            },
        }
    end

    package.preload["zul"] = function()
        local ZUL = {}
        ZUL.new = function(name)
            return {
                info = function(...) end,
                error = function(...) end,
                debug = function(...) end,
                trace = function(...) end,
                warn = function(...) end,
                setLevel = function(...) end,
            }
        end
        return ZUL
    end

    package.preload["Entity/ISUI/Windows/ISEntityWindow"] = function()
        _G.ISEntityWindow = {
            derive = function(self, name)
                return {
                    initialise = function() end,
                    createChildren = function() end,
                }
            end,
            initialise = function(self) end,
            createChildren = function(self) end,
            prerender = function(self) end,
            new = function(self, x, y, width, height, player, entity, style)
                return {}
            end,
        }
        return _G.ISEntityWindow
    end

    package.preload["Entity/ISUI/Controls/ISTableLayout"] = function()
        _G.ISTableLayout = {
            new = function(self)
                return {
                    initialise = function() end,
                    instantiate = function() end,
                }
            end,
            addColumn = function(self)
                return {}
            end,
            addColumnFill = function(self)
                return {}
            end,
            addRow = function(self)
                return {
                    index = function()
                        return 0
                    end,
                }
            end,
            addRowFill = function(self)
                return {}
            end,
            setElement = function(self) end,
        }
        return _G.ISTableLayout
    end

    -- Move ISPanel definition outside of preload so it exists when other classes derive from it
    _G.ISPanel = {
        derive = function(self, name)
            local derived = { __name = name }
            setmetatable(derived, { __index = self })
            return derived
        end,
        new = function(self, x, y, width, height)
            local o = {}
            setmetatable(o, { __index = self })
            o.x = x
            o.y = y
            o.width = width
            o.height = height
            return o
        end,
        initialise = function(self) end,
        instantiate = function(self) end,
        createChildren = function(self) end,
        setVisible = function(self, visible) end,
        addToUIManager = function(self) end,
    }

    package.preload["ISUI/ISPanel"] = function()
        return _G.ISPanel
    end

    _G.ISButton = ISPanel:derive("ISButton")
    package.preload["ISUI/ISButton"] = function()
        return _G.ISButton
    end

    _G.ISScrollingListBox = ISPanel:derive("ISScrollingListBox")
    package.preload["ISUI/ISScrollingListBox"] = function()
        return _G.ISScrollingListBox
    end

    _G.ISImage = ISPanel:derive("ISImage")
    package.preload["ISUI/ISImage"] = function()
        return _G.ISImage
    end

    _G.ISTableLayout = ISPanel:derive("ISTableLayout")
    _G.ISTableLayout.calculateLayout = function() end
    package.preload["Entity/ISUI/Controls/ISTableLayout"] = function()
        return _G.ISTableLayout
    end

    _G.ISEntityWindow = ISPanel:derive("ISEntityWindow")
    package.preload["Entity/ISUI/Windows/ISEntityWindow"] = function()
        return _G.ISEntityWindow
    end

    _G.ISLabel = ISPanel:derive("ISLabel")
    package.preload["ISUI/ISLabel"] = function()
        return _G.ISLabel
    end

    _G.ISComboBox = ISPanel:derive("ISComboBox")
    package.preload["ISUI/ISComboBox"] = function()
        return _G.ISComboBox
    end

    _G.ISTiledIconListBox = ISPanel:derive("ISTiledIconListBox")
    package.preload["Entity/ISUI/CraftRecipe/ISTiledIconListBox"] = function()
        return _G.ISTiledIconListBox
    end

    -- Timed Actions
    _G.ISBaseTimedAction = {
        derive = function(self, name)
            local derived = { __name = name }
            setmetatable(derived, { __index = self })
            return derived
        end,
        new = function(self, character)
            local o = {
                character = character,
                onCompleteFunc = nil,
                onCompleteArgs = nil,
            }
            setmetatable(o, { __index = self })
            return o
        end,
        setOnComplete = function(self, func, ...)
            self.onCompleteFunc = func
            self.onCompleteArgs = { n = select("#", ...), ... }
        end,
    }

    _G.ISWalkToTimedAction = ISBaseTimedAction:derive("ISWalkToTimedAction")

    package.preload["TimedActions/ISBaseTimedAction"] = function()
        return _G.ISBaseTimedAction
    end

    package.preload["TimedActions/ISWalkToTimedAction"] = function()
        return _G.ISWalkToTimedAction
    end
    _G.ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
    package.preload["ISUI/ISTextEntryBox"] = function()
        return _G.ISTextEntryBox
    end

    package.preload["TimedActions/ISTimedActionQueue"] = function()
        return _G.ISTimedActionQueue
    end

    -- Also mock the mod's internal dependencies to avoid recursive issues or missing files
    package.preload["just_another_shop_mod/entity_ui/customer_view_window"] = function()
        return { open = function() end }
    end
    package.preload["just_another_shop_mod/entity_ui/owner_view_window"] = function()
        return { open = function() end }
    end
    package.preload["just_another_shop_mod/entity_ui/models/shop_data_manager"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/shared/shop_search_filter_panel"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/product/product_list_panel"] = function()
        return {}
    end
    -- package.preload["just_another_shop_mod/entity_ui/components/shop/customer/shop_item_details_panel"] is omitted to load the real file
    package.preload["just_another_shop_mod/entity_ui/components/shop/customer/shop_item_header"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/customer/shop_item_gives_panel"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/customer/shop_item_requirements_panel"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/customer/shop_item_action_footer"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/owner/shop_trade_offer_panel"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/owner/shop_requirement_panel"] = function()
        return {}
    end
    package.preload["just_another_shop_mod/entity_ui/components/shop/owner/shop_footer_panel"] = function()
        return {}
    end

    -- Mock debug info
    if not _G.debug then
        _G.debug = {
            getinfo = function()
                return { source = "@./TESTS/tests/" }
            end,
        }
    end
end

return MockPZ
