local cachedData = {}
local isDirty = false
local resourceName = GetCurrentResourceName()


-- Load data from local JSON file on resource start
local function LoadLocalData()
    local loadedData = LoadResourceFile(resourceName, "data.json")
    if loadedData then
        cachedData = json.decode(loadedData)
        if not cachedData then cachedData = {} end
        print('^2[AG-Template] ^7Local Data Loaded Successfully.')
    else
        cachedData = {}
        SaveResourceFile(resourceName, "data.json", json.encode(cachedData), -1)
        print('^3[AG-Template] ^7No Local Data Found. Created new data.json.')
    end
end

-- Save current cache to local JSON file
local function SaveLocalData()
    if not isDirty then return end -- Optimization: Don't write if nothing changed
    SaveResourceFile(resourceName, "data.json", json.encode(cachedData, { indent = true }), -1)
    isDirty = false
    if Config.Debug then print('^2[AG-Template] ^7Local JSON Synced.') end
end

-- Sync data to MySQL Database
-- Handles INSERT or UPDATE based on existing keys
local function SyncToDatabase()
    print('^4[AG-Template] ^7Starting Database Sync...')
    
    local queries = {}
    
    for identifier, data in pairs(cachedData) do
        -- This is an example query. Adjust based on your actual table schema.
        -- Using ON DUPLICATE KEY UPDATE for MySQL is efficient for upserts.
        queries[#queries+1] = {
            query = "INSERT INTO " .. Config.TableName .. " (identifier, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?",
            values = { identifier, json.encode(data), json.encode(data) }
        }
    end

    if #queries > 0 then
        local success = MySQL.transaction.await(queries)
        if success then
            print('^2[AG-Template] ^7Database Sync Complete. (' .. #queries .. ' records updated)')
        else
            print('^1[AG-Template] ^7Database Sync Failed!')
        end
    else
        print('^3[AG-Template] ^7No data to sync.')
    end
end

-------------------------------------------------------------------------------
-- Public API for other resources/scripts
-------------------------------------------------------------------------------

-- Get data for a user
function AG.GetData(identifier)
    return cachedData[identifier] or {}
end

-- Set data for a user (Trigger Save)
function AG.SetData(identifier, key, value)
    if not cachedData[identifier] then cachedData[identifier] = {} end
    
    cachedData[identifier][key] = value
    isDirty = true
    
    -- We save to local file immediately for crash safety
    SaveLocalData()
end

-------------------------------------------------------------------------------
-- Lifecycle Loops
-------------------------------------------------------------------------------

-- Initialize
CreateThread(function()
    LoadLocalData()
    
    -- Sync Loop
    while true do
        Wait(Config.SyncInterval * 60 * 1000) -- Convert minutes to ms
        SyncToDatabase()
    end
end)

-- Save on Resource Stop
AddEventHandler('onResourceStop', function(apiResourceName)
    if resourceName ~= apiResourceName then return end
    print('^1[AG-Template] ^7Resource Stopping. Forcing final sync...')
    SaveLocalData()
    SyncToDatabase()
end)

