local interact = exports['qs-interact']

RegisterCommand('interact', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    -- -180 for the camera to face the player
    local heading = GetEntityHeading(ped) - 180
    local coords = vec4(pos.x, pos.y, pos.z, heading)
    interact:openInteractMenu({
        coords = coords,
        title = 'Interact with NPC',
        name = 'NPC',
        options = {
            {
                label = 'Hello',
                onPress = function()
                    -- 'npc' or 'player' for the type of message
                    interact:addMessage('Hello, how are you?', 'npc')
                end
            },
            {
                label = 'Goodbye',
                onPress = function()
                    -- 'npc' or 'player' for the type of message
                    interact:addMessage('Goodbye!', 'npc')
                    Wait(1500)
                    interact:closeMenu()
                end
            }
        }
    })
end)

RegisterCommand('interact2', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local coords = vec4(pos.x, pos.y, pos.z, heading)
    interact:openInteractMenu({
        coords = coords,
        title = 'Interact with NPC',
        name = 'NPC',
        camOffset = vec3(0, 1.0, 0.5), -- You can specify a camera offset
        options = {
            {
                label = 'Hello',
                onPress = function()
                    -- 'npc' or 'player' for the type of message
                    interact:addMessage('Hello, how are you?', 'npc')
                end
            },
            {
                label = 'Goodbye',
                onPress = function()
                    -- 'npc' or 'player' for the type of message
                    interact:addMessage('Goodbye!', 'npc')
                    Wait(1500)
                    interact:closeMenu()
                end
            }
        }
    })
end)
