
---@class ManipulationAuthority
---@field private _rules table<string, table>
---@field public ValidateEvent string
---@field public PreActionEvent string
---@field public PostActionEvent string
---@field public context

---@class ManipulationAuthorityContext
---@field actionType string The type of action (e.g., "DestroyStuff", "Dismantle", "Moveables")
---@field action any|nil The ISBaseTimedAction instance, if applicable
---@field object IsoObject|nil The target object being manipulated
---@field character IsoPlayer|nil The player performing the manipulation
---@field square IsoGridSquare|nil The square being targeted
---@field data any|nil Additional data (e.g., mode, tool indices)
---@field flags ManipulationAuthorityContextFlag
---@field metadata

---@class ManipulationAuthorityContextFlag
---@field rejected boolean
---@field reason  string|nil
---@field adminOverride boolean

---@class ManipulationAuthorityRule
---@field phase string The phase ("validate", "pre", "post").
---@field id string A unique identifier for the rule.
---@field callback function The rule logic.
---@field priority number The priority (lower = earlier).
