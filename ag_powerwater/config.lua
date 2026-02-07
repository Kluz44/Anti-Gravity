Config = {}

-- Localization 
-- Options: 'en', 'de'
Config.Locale = 'de'

-- Interaction System (Targeting)
-- Options: 'qb-target', 'ox_target', or false (for DrawText/Markers fallback)
Config.Target = 'ox_target'

-- [[ POWER & WATER JOB SETTINGS ]]

-- Job Name (Must match database/job list)
Config.JobName = 'power'

-- Economy Settings
Config.PayPerMission   = false        -- If true, player gets cash. If false, relies on salary.
Config.HouseCallPayout = true         -- If true, payment for house calls goes to Society Account.
Config.HouseCallPrice  = 500          -- Amount NPC pays for service.

-- Grid Health System
Config.Grid = {
    Enabled         = true,             -- Total System Toggle
    DecayInterval   = 30,               -- Minutes between natural decay
    DecayAmount     = { min = 1, max = 5 }, -- Random % lost per interval
    BlackoutLimit   = 20,               -- Below this %, lights flicker/outage occurs
    FireChance      = 10,               -- % Chance of fire on failed critical repair
    FireSystem      = 'SmartFires',     -- Options: 'SmartFires' (LondonStudios), 'default' (Scripted Fire), or 'none'
}

-- Zone Definitions
-- Maps GTA Zone Names (GetLabelText(GetNameOfZone(x,y,z))) to our logical Grids.
-- If a zone is not listed, it defaults to 'Unknown'.
Config.ZoneDefinitions = {
    -- [[ LOS SANTOS DISTRICTS ]]
    ['LS_Downtown'] = {
        label = 'Downtown LS',
        zones = { 'DOWNT', 'LEGION', 'PBOX', 'TEXTI', 'SKID', 'MISSION' }
    },
    ['LS_Vinewood'] = {
        label = 'Vinewood & Hills',
        zones = { 'VIN', 'EVIN', 'DTVINE', 'HWC', 'ALTA', 'RGLEN', 'CHIL', 'WINDF' }
    },
    ['LS_SouthCentral'] = {
        label = 'South Central',
        zones = { 'DAVIS', 'RANCHO', 'STRAW', 'CHAMH', 'CYPRE', 'BALLOW' }
    },
    ['LS_WestSide'] = {
        label = 'Rockford & Richman',
        zones = { 'ROCKF', 'RICHM', 'GOLF', 'MORN', 'WVINE' }
    },
    ['LS_Vespucci'] = {
        label = 'Vespucci & Del Perro',
        zones = { 'VESP', 'DELPE', 'DELBE', 'BEACH', 'VCANA', 'KOREAT' }
    },
    ['LS_Industrial'] = {
        label = 'East LS Industrial',
        zones = { 'EBURO', 'MURRI', 'LMESA', 'ELYS', 'MIRR' }
    },
    ['LS_Airport'] = {
        label = 'LS International Airport',
        zones = { 'AIRP' }
    },

    -- [[ BLAINE COUNTY ]]
    ['SandyShores'] = {
        label = 'Sandy Shores & Grand Senora',
        zones = { 'SANDY', 'GRAPES', 'ALAMO', 'DESRT', 'HARMO', 'JUNKY', 'RONALT', 'JAIL' }
    },
    ['PaletoBay'] = {
        label = 'Paleto Bay Area',
        zones = { 'PALETO', 'PALCOV', 'PROCOB', 'PALFOR', 'MTCHIL' }
    },
    ['CountrySide'] = {
        label = 'Blaine County (Wilderness)',
        zones = { 'TONGVAH', 'BANHAMC', 'BHAMCA', 'CHU', 'LAGO', 'ZANCUDO', 'MTGORDO', 'MTJOSE', 'SLAB' }
    }
}

-- Mission Settings
Config.RoutineInterval = { min = 15, max = 45 } -- Random minutes between generated missions
-- Config.CoolDown = 5 -- Deprecated

-- House Call Locations (Door Coordinates)
Config.HouseLocations = {
    vector3(-14.3, -1441.2, 31.1), -- Grove St
    vector3(118.6, -1921.3, 21.3), -- Grove St area
    vector3(-112.5, 6461.2, 31.6), -- Paleto
    vector3(1963.6, 3740.0, 32.3), -- Sandy
    vector3(-662.6, -934.3, 21.8), -- Little Seoul
}

-- Traffic Light Locations (Major Intersections)
Config.TrafficLights = {
    vector3(205.7, -1379.8, 30.5), -- Straw/Capital
    vector3(-322.2, -1004.8, 30.4), -- Pillbox Hill
    vector3(415.4, -979.7, 29.4), -- Mission Row
    vector3(-552.1, -213.6, 37.6), -- Rockford City Hall
    vector3(1701.3, 3584.5, 35.4), -- Sandy Shores Main
}

-- Street Light Locations (Sample Poles for Maintenance)
Config.StreetLights = {
    vector3(188.7, -928.9, 30.1), -- Legion South
    vector3(163.7, -986.9, 30.1), -- Legion West
    vector3(-563.8, -270.8, 35.4), -- Boulevard
    vector3(1714.5, 3662.9, 35.5), -- Sandy
}

-- Major Transformer / Substation Locations
Config.MainTransformers = {
    vector3(564.4, -986.1, 25.5), -- Mission Row Substation
    vector3(2042.8, 1729.9, 99.8), -- Ron Alternates Substation (Sandy)
    vector3(-524.4, -1071.0, 23.0), -- Alta
}

-- Water Division Settings
Config.PipeLocations = {
    vector3(188.5, -943.5, 30.1), -- Legion Square Area
    vector3(-73.6, -1198.5, 27.8), -- Little Seoul
    vector3(-1175.2, -889.5, 13.9), -- Vespucci
    vector3(1697.5, 3588.6, 35.6), -- Sandy Shores
    vector3(-174.5, 6384.5, 31.5), -- Paleto
}

Config.WaterModels = {
    'prop_fire_hydrant_1', 'prop_fire_hydrant_2', 'prop_fire_hydrant_4'
}

Config.HydrantLocations = {
    vector3(199.3, -934.1, 30.6), -- Legion
    vector3(-106.8, -1071.0, 26.8), -- Construction
    vector3(-1382.1, -1390.6, 4.6), -- Beach
    vector3(1705.5, 3578.8, 35.6), -- Sandy
}

-- Dam Mission (Land Act Dam)
Config.DamValves = {
    vector3(1663.5, -22.5, 173.8), -- Top Valve 1
    vector3(1671.2, -12.1, 173.8), -- Top Valve 2
    vector3(1693.8, 38.2, 168.8), -- Lower Walkway / Generator
}

-- Wind Energy (Ron Alternates)
Config.Turbines = {
    { base = vector3(2056.8, 1722.5, 96.9), topOffset = 80.0 }, 
    { base = vector3(2146.8, 1754.5, 99.8), topOffset = 82.0 },
    { base = vector3(2248.8, 1851.5, 107.8), topOffset = 85.0 },
}

-- Jobs counted as Firefighters for Turbine Suppression Logic
Config.FireJobs = { 'fire', 'ambulance' }

-- Time in minutes to sync local data to the database
Config.SyncInterval = 30

-- Debug Mode: Enable print statements
Config.Debug = true

-- Database Table Name (Example)
Config.TableName = 'ag_data'

-- Society / Company Integration
-- [INFO] Choose your society/banking backend for commissions and payouts.
-- Options:
-- 'none','esx_society','ap-government','qb-management','qb-banking',
-- 'Renewed-Banking','okokBanking','zpx-banking','tgg-banking','crm-banking', 'tgiann-bank'
Config.Society                         = 'ap-government' 

-- Fees / Taxes (pure functions for clarity)
-- [INFO] Adjust percentages as needed. Use integers for whole-number math, or
-- set Config.UseMathCeilOnFees to round up final fees.
Config.BankFee                         = function(price) return price / 100 * 10 end -- [EDIT] 10%
Config.BrokerFee                       = function(price) return price / 100 * 5 end  -- [EDIT] 5%
Config.Taxes                           = function(price) return price / 100 * 5 end  -- [EDIT] 5%

-- Round up fee totals?
Config.UseMathCeilOnFees               = true -- [EDIT] true = ceil final computed fees

-- List of Detectable Resources (for reference, used in bridge.lua)
Config.Detectables = {
    Notify = {
        'qb-core', -- built-in (notify triggers)
        'es_extended', -- built-in (notify triggers)
        'okokNotify',
        'mythic_notify',
        'pNotify',
        't-notify',
        'rcore_notify',
        'ox_lib'
    },
    Inventory = {
        'qs-inventory',
        'qb-inventory',
        'ps-inventory',
        'ox_inventory',
        'core_inventory',
        'codem-inventory',
        'inventory',
        'origen_inventory',
        'tgiann-inventory'
    },
    Garage = {
        'rcore_garage',
        'zerio-garage',
        'codem-garage',
        'ak47_garage',
        'ak47_qb_garage',
        'vms_garagesv2',
        'cs-garages',
        'msk_garage',
        'RxGarages',
        'ws_garage-v2',
        'op-garages',
        'op_garages_v2'
    },
    Clothing = {
        'qs-appearance',
        'qb-clothing',
        'codem-appearance',
        'ak47_clothing',
        'fivem-appearance',
        'illenium-appearance',
        'raid_clothes',
        'rcore_clothes',
        'origen_clothing',
        'rcore_clothing',
        'sleek-clothestore',
        'tgiann-clothing',
        'p_appearance',
        '0r-clothingv2'
    },
    Weather = {
        'qb-weathersync',
        'esx_weathersync',
        'vSync',
        'cd_easytime',
        'qb-timeweather',
        'Renewed-Weathersync',
        'RealisticWeather',
        'Dynamic Weather System',
        'Advanced Weather Sync',
        'ox_weather'
    },
    Phone = {
        'qb-phone',
        'qs-smartphone',
        'lb-phone',
        'gksphone',
        'np-wd',
        'high_phone',
        'yflip-phone',
        'roadphone'
    }
}

-- Config.Items table for Tablet and Tools
Config.Items = {
    tablet = 'pw_tablet',
    toolbox = 'pw_toolbox',
    wrench = 'pw_wrench',
    multimeter = 'pw_multimeter'
}

-- Require Tools for missions?
Config.RequireTools = true
