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

        getParent = function(self)
            return self.parent
        end,

        setParent = function(self, parent)
            self.parent = parent
        end,

        getType = function(self)
            return self.type
        end,

        getItemCount = function(self, itemType)
            if not self.items[itemType] then
                return 0
            end
            return #self.items[itemType]
        end,

        contains = function(self, item)
            if not self.items[item] then
                return false
            end
            return #self.items[item] > 0
        end,

        addItem = function(self, itemType)
            self.items[itemType] = self.items[itemType] or {}
            table.insert(self.items[itemType], { type = itemType })
        end,

        removeItem = function(self, itemType)
            if self.items[itemType] and #self.items[itemType] > 0 then
                table.remove(self.items[itemType], 1)
            end
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

        getUsername = function(self)
            return self.username
        end,

        isAdmin = function(self)
            return self.admin
        end,

        getInventory = function(self)
            return self.inventory
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

        getFullType = function(self)
            return self.type
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
                __methods = {},
            }

            function class:__index(key)
                if class.__methods[key] then
                    return class.__methods[key]
                end
            end

            function class.new()
                local instance = {}
                setmetatable(instance, { __index = class.__methods })
                if instance.initialize then
                    instance:initialize()
                end
                return instance
            end

            -- Allow direct call syntax: MyClass()
            setmetatable(class, {
                __call = function()
                    return class.new()
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
