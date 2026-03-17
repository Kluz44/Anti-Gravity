if not Framework == "esx" then return end
local changePin = function(source, newPin)
    local identifier = RRP.GetIdentifier(source)
    if not newPin then
        return false
    end
    local affectedRows = MySQL.update.await('UPDATE users SET pincode = ? WHERE identifier = ?', { newPin, identifier })
    if affectedRows > 0 then
        print('Pincode changed successfully')
        --notify(source, 'Pincode changed successfully')
    else
        print('Failed to change pincode')
        --notify(source, 'Failed to change pincode')
        return false
    end
    --PINCODES[identifier] = newPin
    return true
end

ESXOverride = {
    changePin = changePin,
}
