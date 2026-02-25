-- fuck this shit, use CAF rules and ISObject modData instead, noob

-- local pz_utils = require("pz_utils_shared")
-- local KUtilities = pz_utils.konijima.Utilities

-- require("TimedActions/ISInventoryTransferAction")

-- return function()
--     local original_isValid = ISInventoryTransferAction.isValid
--     function ISInventoryTransferAction:isValid()
--         local src = self.srcContainer
--         ---@diagnostic disable-next-line: unnecessary-if
--         if src then
--             local parent = src:getParent()
--             if parent and parent:getModData().isShop then
--                 local square = parent:getSquare()
--                 ---@diagnostic disable-next-line: unnecessary-if
--                 if square then
--                     local squareID = KUtilities.SquareToString(square)
--                     local lockHolder = _G.JASM_ShopManager
--                         and _G.JASM_ShopManager:getShopLock(squareID)

--                     -- Owner Guard: If someone else is shopping (lock held),
--                     -- prevent owner from REMOVING items.
--                     if lockHolder and lockHolder ~= self.character:getUsername() then
--                         -- If we are trying to take from the shop
--                         -- (src is the shop, dest is anything else)
--                         return false
--                     end
--                 end
--             end
--         end
--         return original_isValid(self)
--     end
-- end
