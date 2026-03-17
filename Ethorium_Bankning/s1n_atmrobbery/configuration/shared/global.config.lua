Config = Config or {}

Config.debugMode = true

-- If you modified the scripts names used by this script in your resources folder, you need to change them here
Config.ExportNames = {
    s1nLib = "s1n_lib",
}

-- The ATM models that will be used by the script (not all models are supported, so if you want to add a new one, you need to test it)
Config.AtmModels = { "prop_atm_02", "prop_atm_03", "prop_fleeca_atm", }

Config.Robberies = {
    -- The interval between each robbery I can do as a (in milliseconds)
    cooldown = 12 * 60 * 1000 * 60, -- 12 hours (in milliseconds)

    -- The interval between each robbery at the same ATM (in milliseconds)
    atmCooldown = 24 * 60 * 1000 * 60, -- 24 hours (in milliseconds)
}

-- If set to false, the script will use ox_target
Config.UseQBTarget = false

-- If set to true, the script will use quasar_inventory
Config.UseQuasarInventory = false

-- If set to true, the script will use ox_inventory,
-- IMPORTANT: Go to Config.Items to adapt c4 item for ox_inventory
Config.UseOXInventory = false

-- If `enable` set to true, the script will use this item name as cash (to get the money from an ATM)
Config.CashItem = {
    enable = false,
    itemName = 'cash'
}

-- The chance of getting money from the atm, should be a number between 0 - 100
Config.GetMoneyChance = 50

-- The reward that the player will get for robbing the atm, the number will be somewhere around the min - max values
Config.AtmReward = { min = 5000, max = 10000 }

-- Enable / disable the option to rob the atm using a drill
Config.EnableDrill = true

-- Enable / disable the option to rob the atm using a c4
Config.EnableC4 = true

-- Enable / disable the vehicle whitelist system
Config.EnableVehicleWhitelist = true

-- All the vehicles that are whitelisted
Config.WhitelistVehicles = {
    ['futo'] = true
}

-- All the jobs that will get the robbery notification
Config.NotificationJobs = {
    ['police'] = true
}

-- Robbery notification timeout
Config.NotificationTimeout = 15000

-- Number of milliseconds after which the rope and atm are deleted when you finished the robbery process for an ATM.
Config.AtmCooldown = 20000

-- Progress bar durations
Config.ProgressDuration = { drillfirst = 7000, drillsecond = 7000, search = 5000 }

-- Robbery items
-- IMPORTANT:
-- - if you use ox_inventory, YOU NEED TO MODIFY 'c4' TO 'weapon_stickybomb' otherwise it won't work
Config.Items = { rope = 'rope', drill = 'drill', c4 = 'c4' }

-- Distance to drill the ATM after drilling it from the wall
Config.DrillAfterDistance = 20.0

-- Minimum police online to start a robbery
Config.MinPoliceOnline = 0