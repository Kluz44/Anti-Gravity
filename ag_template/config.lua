Config = {}

-- Localization 
-- Options: 'en', 'de'
Config.Locale = 'de'

-- Interaction System (Targeting)
-- Options: 'qb-target', 'ox_target', or false (for DrawText/Markers fallback)
Config.Target = 'ox_target'

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
    Phone = {
        'qs-smartphone-pro',
        'qs-smartphone',
        'lb-phone',
        'gksphone',
        'okokPhone',
        'roadphone',
        'codem-phone'
    },
    Garage = {
        'qb-garages',
        'qs-advancedgarages',
        'jg-advancedgarages',
        'cd_garage',
        'okokGarage',
        'loaf_garage',
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
    }
}
