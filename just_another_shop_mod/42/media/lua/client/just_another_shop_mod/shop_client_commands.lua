local function OnServerCommand(module, command, args)
    if module ~= "JASM_ShopManager" then
        return
    end

    if command == "UpdateSuccess" then
        local text = (args.action == "REGISTER") and "Shop Registered Successfully"
            or "Shop Removed"
        HaloTextHelper.addGoodText(getSpecificPlayer(0), text)
    elseif command == "RegisterDenied" then
        local reason = args.reason or "unknown"
        local errorTexts = {
            already_registered = "Shop already registered! Unregister first.",
        }
        local text = errorTexts[reason] or "Registration denied."
        HaloTextHelper.addBadText(getSpecificPlayer(0), text)
    elseif command == "UnregisterDenied" then
        local reason = args.reason or "unknown"
        local errorTexts = {
            not_owner_or_admin = "You are not the owner or authorized admin.",
            container_not_empty = "Shop contains items. Empty it before unregistering.",
        }
        local text = errorTexts[reason] or "Unregistration denied."
        HaloTextHelper.addBadText(getSpecificPlayer(0), text)
    end
end

return OnServerCommand
