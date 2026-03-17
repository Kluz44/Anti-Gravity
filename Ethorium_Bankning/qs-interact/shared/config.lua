Config = {}

Config.Target = true          -- Targeting system: 'qb-target', 'qtarget', or false (use 'qtarget' for 'ox_target')
Config.Talk = 'Talk with'      -- Text displayed before the NPC's name
Config.PlayerNotVisible = true -- Player becomes invisible when interacting with NPC (only for themselves)

Config.Hud = {
    Enable = function()
        DisplayRadar(true) -- Enables radar display on HUD
        -- exports['qs-interface']:ToggleHud(true) -- Uncomment if using an external HUD
    end,
    Disable = function()
        DisplayRadar(false) -- Disables radar display on HUD
        -- exports['qs-interface']:ToggleHud(false) -- Uncomment if using an external HUD
    end
}
 
RegisterCommand('express', function(source, args)
    exports['qs-interact']:setEntityExpression(args[1])
end)

Config.Peds = {
    {
        npc = 's_m_m_scientist_01',
        coords = vector3(-1876.1138, 3752.3926, -98.8454),
        heading = 224.4701,
        name = 'Wissenschaftler',
        animName = 'idle_cough',
        animDict = 'timetable@gardener@smoking_joint',
        blip = {
            coords = vector3(-200.98, -1378.69, 30.26),
            sprite = 1,
            color = 0,
            name = 'Quasar',
            scale = 0.8
        },
        intro = 'Hey, champ! Looks like it’s your first time using QS-Interact. How can I assist you today?',

        interactions = {
            {
                label = 'Welche Laufbahn willst du einschlagen',
                onPress = function(menu, actionData)
                    if actionData.ped then
                        menu.playAnim(actionData.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle')
                        -- RequestAnimDict('timetable@jimmy@doorknock@')
                        -- while not HasAnimDictLoaded('timetable@jimmy@doorknock@') do
                        --     Wait(1)
                        -- end
                        -- TaskPlayAnim(actionData.ped, 'timetable@jimmy@doorknock@', 'knockdoor_idle', 8.0, 0.0, -1, 1, 0, 0, 0, 0)
                    end
                    menu.addMessage('Want to see how an event trigger works? Check out config.lua! I’ll wait 3.5 seconds so you can read this...', 'npc')
                    Wait(1500)
                    menu.close()
                    menu.removeBlip()
                    TriggerClientEvent('ata_einreise:ShowJoin:client', src)
                end,
            },
            {
                label = 'Teach me how to open a store from this script!',
                onPress = function(menu, actionData)
                    menu.updateBlip({
                        coords = vector3(-200.98, -1378.69, 29.26),
                        sprite = 52,
                        color = 2,
                        name = 'Quasar Store blip 2',
                        scale = 0.8
                    })
                    menu.setEntityExpression('happy')
                    menu.addMessage('Alright, let me show you... Oh, look! A PRO Smartphone just for you!', 'npc')
                    Wait(1500)
                    -- Check types.lua for expressions
                    menu.setEntityExpression('excited')
                    menu.addMessage('Come on, don’t keep me waiting all day!', 'player')
                    Wait(3500)
                    menu.setEntityExpression('shocked')
                    menu.close()
                    local shop = 'shop'
                    local Items = {
                        label = 'Quasar Store',
                        items = {
                            {
                                name = 'phone',
                                amount = 50,
                                price = 1500,
                                slot = 1
                            },
                        },
                    }
                    TriggerServerEvent('inventory:server:OpenInventory', 'shop', 'Itemshop_' .. shop, Items)
                    menu.updateBlip({
                        coords = vector3(-200.98, -1378.69, 30.26),
                        sprite = 52,
                        color = 2,
                        name = 'Quasar Store blip 2',
                        scale = 0.8
                    })
                end,
            },
            {
                label = 'Show me a simple crafting example',
                onPress = function(menu, actionData)
                    menu.addMessage('Sure! Here’s a quick crafting example for you.', 'npc')
                    Wait(3500)
                    menu.close()
                    local CustomCrafting = {
                        [1] = {
                            name = 'weapon_pistol',
                            amount = 50,
                            info = {},
                            costs = {
                                ['tosti'] = 1,
                            },
                            type = 'weapon',
                            slot = 1,
                            rep = 'attachmentcraftingrep',
                            points = 1,
                            threshold = 0,
                            time = 5500,
                            chance = 100
                        },
                        [2] = {
                            name = 'water_bottle',
                            amount = 1,
                            info = {},
                            costs = {
                                ['tosti'] = 1,
                            },
                            type = 'item',
                            slot = 2,
                            rep = 'attachmentcraftingrep',
                            points = 1,
                            threshold = 0,
                            time = 8500,
                            chance = 100
                        },
                    }

                    local crafting = {
                        label = 'Crafting Menu',
                        items = exports['qs-inventory']:SetUpCrafing(CustomCrafting)
                    }
                    TriggerServerEvent('inventory:server:SetInventoryItems', CustomCrafting)
                    TriggerServerEvent('inventory:server:OpenInventory', 'customcrafting', crafting.label, crafting)
                end,
            },
            {
                label = 'Teleport me somewhere, come on!',
                onPress = function(menu)
                    menu.addMessage('Alright, let’s get you somewhere else. Safe travels!', 'npc')
                    Wait(2500)
                    menu.close()
                    local playerPed = PlayerPedId()
                    SetEntityCoords(playerPed, 253.47, -1012.60, 29.2, false, false, false, true)
                    SetEntityHeading(playerPed, 249.60 or 0.0)
                end,
            },
            {
                label = 'Give me a weapon or something!',
                onPress = function(menu)
                    menu.addMessage('Really? Fine, if you insist...', 'npc')
                    Wait(1500)
                    menu.addMessage('Dude, I don’t have all day!', 'player')
                    Wait(1500)
                    menu.addMessage('Okay, okay, chill out!', 'npc')
                    Wait(2500)
                    menu.close()
                    ExecuteCommand('giveitem ' .. GetPlayerServerId(PlayerId()) .. ' weapon_pistol 99')
                end,
            },
            {
                label = 'Bye, thanks for your help Quasar!',
                onPress = function(menu)
                    menu.addMessage('Alright, see you around! Don’t get into too much trouble.', 'npc')
                    Wait(2500)
                    menu.close()
                end,
            }
        }
    },
    {
        npc = 'u_m_y_abner',
        coords = vector3(255.43, -1013.39, 28.27),
        heading = 62.83,
        name = 'John Smith',
        animName = 'mini@strip_club@idles@bouncer@base',
        animDict = 'base',
        intro = 'Hello! I’m John Smith. What can I do for you?',

        interactions = {
            {
                label = 'What do you like to do in your free time?',
                onPress = function(menu)
                    menu.setEntityExpression('shocked')
                    menu.addMessage('In my free time, I enjoy hiking and reading sci-fi books.', 'npc')
                end,
            },
            {
                label = 'Open my inventory, please.',
                onPress = function(menu)
                    menu.addMessage('Sure thing! Your inventory will open shortly...', 'npc')
                    Wait(2500)
                    menu.close()
                    TriggerServerEvent('inventory:server:OpenInventory')
                end,
            },
            {
                label = 'Trigger a server event',
                onPress = function(menu)
                    menu.addMessage('Executing a server event... done!', 'npc')
                    TriggerServerEvent('myServerEvent', { param1 = 'value1', param2 = 123 })
                end,
            },
            {
                label = 'I have to go, goodbye!',
                onPress = function(menu)
                    menu.addMessage('Take care! Have a great day.', 'npc')
                    Wait(1000)
                    menu.close()
                end,
            }
        }
    },
    {
        npc = 'ig_molly',
        coords = vector3(68.0755, -259.8559, 47.1971),
        heading = 173.8901,
        name = 'Madison Blake',
        animName = 'mini@strip_club@idles@bouncer@base',
        animDict = 'base',
        intro = 'Hallo! ich bin Madison Blake, Wie kann ich dir helfen ',

        interactions = {
            {
                label = 'Kannst du mir zeigen welche Immobilien Zu verkaufen sind? ',
                onPress = function(menu)
                    menu.setEntityExpression('shocked')
                    menu.addMessage('Ja klar hier hast du eine Übersicht über die freien Immobilien.', 'npc')
                    Wait(2500)
                    menu.close()
                    TriggerEvent('ethorium_housingmap:openmap')
                end,
            },
            {
                label = 'I have to go, goodbye!',
                onPress = function(menu)
                    menu.addMessage('Take care! Have a great day.', 'npc')
                    Wait(1000)
                    menu.close()
                end,
            }
        },
        
    },
    {
        npc = 'ig_molly',
        coords = vector3(-1294.7417, -565.7573, 30.5898),
        heading = 222.0190,
        name = 'Sandra Blossom',
        animName = 'mini@strip_club@idles@bouncer@base',
        animDict = 'base',
        intro = 'Hallo! ich bin Sandra Blossom, Wie kann ich dir helfen ',

        interactions = {
            {
                label = 'Hallo, ich benötige einen gültigen Ausweis.',
                onPress = function(menu)
                    menu.setEntityExpression('shocked')
                    menu.addMessage('Ausweise können Sie im Zweitenstock im Raum 202 bei Frau Blossom beantragen.', 'npc')
                    Wait(2500)
                    menu.close()
                    --TriggerEvent('ethorium_housingmap:openmap')
                end,
            },
            {
                label = 'Hallo, mein Ausweis ist ausgelaufen und ich benötige einen neuen. ',
                onPress = function(menu)
                    menu.setEntityExpression('shocked')
                    menu.addMessage('Ausweise können Sie im Zweitenstock im Raum Recognition bei meinem Kollegen erneuern lassen.', 'npc')
                    Wait(2500)
                    menu.close()
                    --TriggerEvent('ethorium_housingmap:openmap')
                end,
            },
            {
                label = 'Danke und aufwiedersehen!',
                onPress = function(menu)
                    menu.addMessage('Ich wünsche Ihnen einen angenehmen Tag.', 'npc')
                    Wait(1000)
                    menu.close()
                end,
            }
        },
    },     
    -- Add more NPCs here!
}

--[[
    Please do not modify anything below, as it is related to management and administration.
    This section is crucial for managing key bindings and interactions,
    so any unintended changes could affect functionality.
]]

Config.Debug = true -- Enables debug mode
