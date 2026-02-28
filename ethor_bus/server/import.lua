-- =============================================
-- Initial Data Import Logic
-- =============================================

if not Config.AutoImportInitialData then return end

CreateThread(function()
    -- Wait a moment to ensure DB connection is ready
    Wait(2000)

    -- Check if import was already done
    local done = MySQL.scalar.await('SELECT key_value FROM bus_sys_properties WHERE key_name = ?', {'initial_import_v2'})
    if done == '1' then
        if Config.Debug then print('^2[ethor_bus] ^7Initial data import v2 already completed. Skipping.') end
        return
    end

    print('^4[ethor_bus] ^7Starting Initial Data Import (V2)...')
    
    -- Clear old broken data
    MySQL.query.await('DELETE FROM bus_stops')

    -- 1. Create Default Company
    local companyId = MySQL.insert.await('INSERT IGNORE INTO bus_companies (id, name, owner_identifier) VALUES (?, ?, ?)', { 1, Config.DefaultCompanyName, 'system' })
    if not companyId or companyId == 0 then companyId = 1 end
    print('^2[ethor_bus] ^7Company ID: ' .. tostring(companyId))

    -- Helper to map Capital X,Y,Z to lowercase
    local function mapCoords(c)
        if type(c) == 'string' then c = json.decode(c) end
        if not c then return {x=0.0, y=0.0, z=0.0} end
        return {x=(c.x or c.X or 0.0)+0.0, y=(c.y or c.Y or 0.0)+0.0, z=(c.z or c.Z or 0.0)+0.0}
    end

    -- 2. Load and Insert Stops
    local stopsFile = LoadResourceFile(GetCurrentResourceName(), 'data/busstops.json')
    if stopsFile then
        local parsed = json.decode(stopsFile)
        local stopsData = (parsed and parsed.BusStops) or {}
        local stopsCount = 0
        for _, stop in ipairs(stopsData) do
            local safeName = stop.Name or "Unknown"
            local gId = "stop_" .. safeName:gsub("%s+", "_"):gsub("[^%w_]", ""):lower()
            
            MySQL.insert.await([[
                INSERT IGNORE INTO bus_stops 
                (id, name, coords, approach_coords, exit_coords, queue_coords, base_demand, rush_profile) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                gId,
                safeName,
                json.encode(mapCoords(stop.Position)),
                json.encode(mapCoords(stop.PassengerSpawn)),
                json.encode({}), 
                json.encode({mapCoords(stop.PassengerSpawn)}),
                stop.MaxPassenger or 5,
                'default'
            })
            stopsCount = stopsCount + 1
        end
        print('^2[ethor_bus] ^7Imported ' .. stopsCount .. ' stops.')
    end

    -- 3. Load and Insert Routes
    local routesFile = LoadResourceFile(GetCurrentResourceName(), 'data/routes.json')
    if routesFile then
        local routesData = json.decode(routesFile)
        if routesData then
            local routesCount = 0
            for _, route in ipairs(routesData) do
                MySQL.insert.await('INSERT IGNORE INTO bus_routes (company_id, name, color, stops_json) VALUES (?, ?, ?, ?)', {
                    companyId,
                    route.name,
                    route.color,
                    json.encode(route.stops)
                })
                routesCount = routesCount + 1
            end
            print('^2[ethor_bus] ^7Imported ' .. routesCount .. ' routes.')
        end
    end

    -- Mark as done
    MySQL.update.await('UPDATE bus_sys_properties SET key_value = ? WHERE key_name = ?', {'1', 'initial_import_done'})
    print('^2[ethor_bus] ^7Initial Data Import Completed Successfully.')
end)
