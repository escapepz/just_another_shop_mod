local function OnServerCommand(module, command, args)
    if module ~= "JASM_ShopManager" then
        return
    end

    if command == "UpdateSuccess" then
        local text = (args.action == "REGISTER") and "Shop Registered Successfully"
            or "Shop Removed"
        HaloTextHelper.addGoodText(getSpecificPlayer(0), text)
    end
end

return OnServerCommand
