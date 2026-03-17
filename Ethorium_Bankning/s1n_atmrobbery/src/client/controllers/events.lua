RegisterNetEvent("s1n_atmrobbery:startRobbery", function()
    Functions:CheckStartRobbery({
        robberyType = "drill"
    })
end)

RegisterNetEvent('s1n_atmrobbery:plantc4', function(atmNetId)
    Functions:CheckStartRobbery({
        robberyType = "c4",
        atmNetId = atmNetId
    })
end)

RegisterNetEvent('s1n_atmrobbery:attachRopeToAtm', function()
    Helpers:AttachRopeToAtm()
end)

RegisterNetEvent('s1n_atmrobbery:attachRopeToVehicle', function()
    Helpers:AttachRopeToVehicle()
end)

RegisterNetEvent('s1n_atmrobbery:drillAtm', function()
    Helpers:DrillAtm()
end)

RegisterNetEvent('s1n_atmrobbery:detachRopeFromVehicle', function()
    Helpers:DetachAtm()
end)

RegisterNetEvent('s1n_atmrobbery:searchAtm', function()
    Helpers:SearchAtm()
end)

RegisterNetEvent('s1n_atmrobbery:detachRopeFromAtm', function()
    Helpers:DetachRopeFromAtm()
end)

RegisterNetEvent('s1n_atmrobbery:policeAlert', function(coords)
    NotifyPolice(coords)
end)

RegisterNetEvent('s1n_atmrobbery:clearAtm', function(netId)
    Helpers:ClearAtm(netId)
end)

RegisterNetEvent('s1n_atmrobbery:pickupCash', function()
    Helpers:PickupCash()
end)

RegisterNetEvent('s1n_atmrobbery:notification', function(message)
    Helpers:Notification(message)
end)

-- Server sync

RegisterNetEvent('s1n_atmrobbery:addDrilledAtm', function(netId)
    Utils:Debug("Adding drilled atm : " .. netId)

    Storage.DrilledAtms[netId] = true
    Storage.AttachedAtms[netId] = { atm = false, vehicle = false }
end)

RegisterNetEvent('s1n_atmrobbery:updateAttachedAtm', function(atmNetId, type, targetEntityNetId)
    Utils:Debug("Updating attached atm : " .. atmNetId .. " | " .. type)

    Storage.AttachedAtms[atmNetId][type] = not Storage.AttachedAtms[atmNetId][type]

    if type == 'atm' then
        if Storage.AttachedAtms[atmNetId][type] then
            Helpers:NetworkAttachRopeToAtm(atmNetId, targetEntityNetId)
        else
            Helpers:NetworkDetachRopeFromAtm(atmNetId)
        end
    else
        if Storage.AttachedAtms[atmNetId][type] then
            Helpers:NetworkAttachRopeToVehicle(atmNetId, targetEntityNetId)
        else
            Helpers:NetworkDetachRopeFromVehicle(targetEntityNetId)
        end
    end
end)

RegisterNetEvent('s1n_atmrobbery:addCanBeDrilledAtm', function(netId)
    Utils:Debug("Adding can be drilled atm : " .. netId)

    Storage.CanBeDrilledAtms[netId] = true
end)

RegisterNetEvent('s1n_atmrobbery:addBrokenAtm', function(netId)
    Utils:Debug("Adding broken atm : " .. netId)

    Storage.BrokeAtms[netId] = true
end)

RegisterNetEvent('s1n_atmrobbery:addSearchedAtm', function(netId)
    Utils:Debug("Adding searched atm : " .. netId)

    Storage.SearchedAtms[netId] = true
end)

RegisterNetEvent('s1n_atmrobbery:addExplodedAtm', function(netId)
    Utils:Debug("Adding exploded atm : " .. netId)

    Storage.ExplodedAtms[netId] = true
end)