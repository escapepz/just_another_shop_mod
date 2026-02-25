require("ISUI/ISPanel")
require("ISUI/ISLabel")
require("ISUI/ISButton")
require("Entity/ISUI/Controls/ISTableLayout")

--- Footer panel with error label and publish button.
---@class ShopFooterPanel : ISPanel
---@field errorLabel ISLabel
---@field publishBtn ISButton
---@field target any
---@field onPublish fun(target: any)
---@field xuiSkin any
local ShopFooterPanel = ISPanel:derive("ShopFooterPanel")

function ShopFooterPanel:xuiBuild(style, class, ...)
    local o = ISXuiSkin.build(self.xuiSkin, style, class, ...)
    if o then
        o:initialise()
        o:instantiate()
    end
    return o
end

function ShopFooterPanel:createChildren()
    ISPanel.createChildren(self)

    ---@type ISTableLayout|nil
    self.tableLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, self.height)
    if not self.tableLayout then
        return
    end
    self:addChild(self.tableLayout)

    self.tableLayout:addColumnFill()

    -- 1. Separator Line
    local hrRow = self.tableLayout:addRow()
    if hrRow then
        ---@type ShopFooterPanel|nil
        local footerLine = self:xuiBuild(nil, ISPanel, 0, 0, self.width, 1)
        if footerLine then
            -- footerLine.calculateLayout = function(_self, _w, _h)
            --     _self:setWidth(_w)
            -- end
            footerLine.background = true
            footerLine.backgroundColor = { r = 0.20, g = 0.20, b = 0.20, a = 1.0 }
            self.tableLayout:setElement(0, hrRow:index(), footerLine)
        end
    end

    -- 2. Footer content (Label + Button - Stacked to prevent overlap)
    local footerRow = self.tableLayout:addRow()
    if footerRow then
        ---@diagnostic disable-next-line: inject-field
        footerRow.marginTop = 10
        ---@type ISTableLayout|nil
        local contentLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, self.width, 54)
        if contentLayout then
            contentLayout:addColumnFill()

            -- Top row: Status Label
            local rLabel = contentLayout:addRow()
            if rLabel then
                rLabel.minimumHeight = 20
                ---@type ISLabel|nil
                self.errorLabel = self:xuiBuild(
                    nil,
                    ISLabel,
                    0,
                    0,
                    20,
                    "",
                    1.0,
                    0.27,
                    0.27,
                    1,
                    UIFont.Small,
                    true
                )
                if self.errorLabel then
                    contentLayout:setElement(0, rLabel:index(), self.errorLabel)
                end
            end

            -- Bottom row: Publish Button (Right aligned)
            local rBtn = contentLayout:addRow()
            if rBtn then
                rBtn.minimumHeight = 34
                ---@diagnostic disable-next-line: inject-field
                rBtn.marginTop = 4
                ---@type ISTableLayout|nil
                local btnLayout = self:xuiBuild(nil, ISTableLayout, 0, 0, 10, 34)
                if btnLayout then
                    btnLayout:addColumnFill()
                    local bc = btnLayout:addColumn()
                    bc.minimumWidth = 140
                    local br = btnLayout:addRowFill()
                    if br then
                        ---@type ISButton|nil
                        self.publishBtn = self:xuiBuild(
                            nil,
                            ISButton,
                            0,
                            0,
                            140,
                            34,
                            "PUBLISH TRADE",
                            self.target,
                            self.onPublish
                        )
                        if self.publishBtn then
                            self.publishBtn.backgroundColor =
                                { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }
                            ---@diagnostic disable-next-line: inject-field
                            self.publishBtn.backgroundColorOver =
                                { r = 1.00, g = 0.70, b = 0.28, a = 1.0 }
                            self.publishBtn.borderColor = { r = 0.95, g = 0.61, b = 0.07, a = 1.0 }
                            self.publishBtn.textColor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }

                            -- ── PROGRESS BAR OVERLAY ────────────────────────────────
                            local parent = self
                            local oldRender = self.publishBtn.render
                            self.publishBtn.render = function(btn)
                                -- Draw normal button first
                                ---@diagnostic disable-next-line: redundant-parameter
                                oldRender(btn)

                                -- Draw progress bar if publishing
                                local win = parent.target
                                if win and win.isPublishing and win.currentPublishAction then
                                    local delta = win.currentPublishAction:getJobDelta()
                                    if delta > 0 then
                                        -- Draw semi-transparent overlay
                                        btn:drawRect(
                                            0,
                                            0,
                                            btn.width * delta,
                                            btn.height,
                                            0.4,
                                            0.2,
                                            0.6,
                                            1.0
                                        )
                                    end
                                end

                                -- Anti-spam: disable button while publishing or if no changes
                                btn:setEnable(
                                    not (win and win.isPublishing)
                                        and (win and win.hasUnsavedChanges)
                                )
                            end
                            -- ────────────────────────────────────────────────────────

                            btnLayout:setElement(1, br:index(), self.publishBtn)
                        end
                    end
                    contentLayout:setElement(0, rBtn:index(), btnLayout)
                end
            end

            self.tableLayout:setElement(0, footerRow:index(), contentLayout)
        end
    end
end

function ShopFooterPanel:setError(msg)
    self.errorLabel:setName(msg)
    self.errorLabel.r = 1.0
    self.errorLabel.g = 0.27
    self.errorLabel.b = 0.27
end

function ShopFooterPanel:setSuccess(msg)
    self.errorLabel:setName(msg)
    self.errorLabel.r = 0.30
    self.errorLabel.g = 0.90
    self.errorLabel.b = 0.30
end

function ShopFooterPanel:clearError()
    self.errorLabel:setName("")
end

function ShopFooterPanel:calculateLayout(width, height)
    self:setWidth(width)
    if self.tableLayout then
        self.tableLayout:calculateLayout(width, height)
        self:setHeight(self.tableLayout:getHeight())
    end
end

function ShopFooterPanel:new(x, y, w, h, target, onPublish, xuiSkin)
    ---@type ShopFooterPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.target = target
    o.onPublish = onPublish
    o.xuiSkin = xuiSkin or XuiManager.GetDefaultSkin()
    return o
end

return ShopFooterPanel
