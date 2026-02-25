Config = {}

-- =============================================
-- Core Settings
-- =============================================
Config.Locale = 'de'
Config.Target = 'ox_target' -- Strictly ox_target requested
Config.Debug = true

Config.Core = 'qb-core' -- Framework integration
Config.DBType = 'oxmysql'

-- =============================================
-- Auto Import Data
-- =============================================
-- If true, the system will attempt to read busstops.json and routes.json
-- from the data/ folder and insert them to DB if the import flag is 0.
Config.AutoImportInitialData = true
Config.DefaultCompanyName = 'LS Transit Authority'

-- =============================================
-- Fleet / Vehicle Models
-- =============================================
Config.BusModels = {
    'bus',
    'coach',
    'dashound',
    'tourbus'
}

-- =============================================
-- Ped & Demand Settings (Phase 1)
-- =============================================
Config.Peds = {
    GlobalCap = 50, -- Max visible waiting peds globally on the server at any given time to save resources
    SpawnDistance = 250.0, -- Distance at which stops start generating peds if player is near
    DespawnDistance = 300.0,
}

Config.Demand = {
    -- Evaluate demand periodically per active grid/stop (in ms)
    EvaluationTick = 600000, -- 10 Minutes slot 
    BaseRushMultiplier = 1.0,
    -- Examples of Rush Profiles:
    Profiles = {
        ['default'] = { multiplier = 1.0 },
        ['morning_rush'] = { timeStart = 7, timeEnd = 9, multiplier = 2.5 },
        ['evening_rush'] = { timeStart = 16, timeEnd = 18, multiplier = 2.0 },
    }
}

-- =============================================
-- Economics / Boss System
-- =============================================
Config.TicketPrice = {
    Base = 5,
    PerStop = 2 
}

Config.DriverPay = {
    BasePerStop = 50,
    RatingMultiplier = true -- If mood is 100%, gets 100%. If mood is 50%, gets 50%.
}

-- =============================================
-- AI & Emergency Rules (Phase 2 Prep)
-- =============================================
Config.AI = {
    EnableEmergencyReaction = true,
    EmergencySirenDistance = 50.0, -- Distance to start pulling over
    CheckInterval = 1000, -- Check emergency behind every 1s
    EmergencyClasses = { 18 } -- Emergency Vehicle Class
}

-- =============================================
-- UI & Visuals
-- =============================================
Config.UI = {
    RefreshRate = 1000, -- Stop displays refresh every 1s when player is near
    MapMarkerColor = 3,
    BlipSprite = 513
}

-- =============================================
-- Persistence Tracker
-- =============================================
Config.Persistence = {
    SnapshotInterval = 120000 -- Save active trips to DB every 2 Minutes
}
