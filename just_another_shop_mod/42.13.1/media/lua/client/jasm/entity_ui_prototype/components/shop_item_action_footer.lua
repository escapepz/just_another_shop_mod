require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")

---@class ShopItemActionFooter : ISPanel
---@field errorLabel ISLabel
---@field acceptButton ISButton
---@field debugButton ISButton
---@field target any
---@field onAccept fun(target: any)
---@field onDebug fun(target: any)
---@field xuiSkin any
local ShopItemActionFooter = ISPanel:derive("ShopItemActionFooter")

local UI_BORDER_SPACING = 12

function ShopItemActionFooter:createChildren()
    ISPanel.createChildren(self)

    -- Subtle top border
    self.backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 1.0 }
    self.borderColor = { r = 0.20, g = 0.20, b = 0.20, a = 1.0 }

    ---@type ISLabel
    self.errorLabel = ISXuiSkin.build(
        self.xuiSkin,
        nil,
        ISLabel,
        0,
        5,
        20,
        "",
        1.0,
        0.27,
        0.27,
        1,
        UIFont.Small,
        true
    )
    ---@diagnostic disable-next-line: unnecessary-if
    if self.errorLabel then
        self.errorLabel:initialise()
        self.errorLabel:instantiate()
        self.errorLabel.center = true
        self:addChild(self.errorLabel)
    end

    ---@type ISButton
    self.acceptButton = ISXuiSkin.build(
        self.xuiSkin,
        nil,
        ISButton,
        (self.width - 200) / 2,
        24,
        200,
        30,
        "ACCEPT TRADE",
        self.target,
        self.onAccept
    )
    ---@diagnostic disable-next-line: unnecessary-if
    if self.acceptButton then
        self.acceptButton:initialise()
        self.acceptButton:instantiate()
        self.acceptButton.enable = false
        self:addChild(self.acceptButton)
    end

    ---@type ISButton
    self.debugButton = ISXuiSkin.build(
        self.xuiSkin,
        nil,
        ISButton,
        (self.width - 200) / 2,
        58,
        200,
        26,
        "DEBUG: Force Give",
        self.target,
        self.onDebug
    )
    ---@diagnostic disable-next-line: unnecessary-if
    if self.debugButton and isDebugEnabled() then
        self.debugButton:initialise()
        self.debugButton:instantiate()
        -- Muted admin style
        self.debugButton.backgroundColor = { r = 0.10, g = 0.10, b = 0.10, a = 1.0 }
        self.debugButton.textColor = { r = 0.53, g = 0.53, b = 0.53, a = 1.0 }
        self:addChild(self.debugButton)
    end
end

function ShopItemActionFooter:setError(msg)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.errorLabel then
        self.errorLabel:setName(msg or "")
    end
end

function ShopItemActionFooter:setTradeEnabled(enabled)
    if not self.acceptButton then
        return
    end
    self.acceptButton:setEnable(enabled)
    if enabled then
        self.acceptButton.backgroundColor = { r = 0.95, g = 0.61, b = 0.07, a = 1 }
        self.acceptButton.textColor = { r = 0, g = 0, b = 0, a = 1 }
    else
        self.acceptButton.backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 }
        self.acceptButton.textColor = { r = 0.8, g = 0.8, b = 0.8, a = 1 }
    end
end

function ShopItemActionFooter:calculateLayout(width, height)
    self:setWidth(width)
    self:setHeight(height)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.errorLabel then
        self.errorLabel:setX(width / 2)
        self.errorLabel:setWidth(1)
    end

    local btnW = math.min(200, width - UI_BORDER_SPACING * 2)
    ---@diagnostic disable-next-line: unnecessary-if
    if self.acceptButton then
        self.acceptButton:setWidth(btnW)
        self.acceptButton:setX((width - btnW) / 2)
    end
    ---@diagnostic disable-next-line: unnecessary-if
    if self.debugButton then
        self.debugButton:setWidth(btnW)
        self.debugButton:setX((width - btnW) / 2)
    end
end

function ShopItemActionFooter:new(x, y, w, h, target, onAccept, onDebug, xuiSkin)
    ---@type ShopItemActionFooter
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.onAccept = onAccept
    o.onDebug = onDebug
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopItemActionFooter
