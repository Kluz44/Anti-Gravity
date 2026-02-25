-- =============================================
-- Initial Data Import Logic
-- =============================================

if not Config.AutoImportInitialData then return end

CreateThread(function()
    -- Wait a moment to ensure DB connection is ready
    Wait(2000)

    -- Check if import was already done
    local done = MySQL.scalar.await('SELECT key_value FROM bus_sys_properties WHERE key_name = ?', {'initial_import_done'})
    if done == '1' then
        if Config.Debug then print('^2[ethor_bus] ^7Initial data import already completed previously. Skipping.') end
        return
    end

    print('^4[ethor_bus] ^7Starting Initial Data Import...')

    -- 1. Create Default Company
    local companyId = MySQL.insert.await('INSERT INTO bus_companies (name, owner_identifier) VALUES (?, ?)', { Config.DefaultCompanyName, 'system' })
    if not companyId then
        print('^1[ethor_bus] ^7Failed to create default company!')
        return
    end
    print('^2[ethor_bus] ^7Created Default Company ID: ' .. companyId)

    -- 2. Load and Insert Stops
    local stopsFile = LoadResourceFile(GetCurrentResourceName(), 'data/busstops.json')
    if stopsFile then
        local stopsData = json.decode(stopsFile)
        if stopsData then
            local stopsCount = 0
            for _, stop in ipairs(stopsData) do
                MySQL.insert.await([[
                    INSERT IGNORE INTO bus_stops 
                    (id, name, coords, approach_coords, exit_coords, queue_coords, base_demand, rush_profile) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    stop.id,
                    stop.name,
                    json.encode(stop.coords),
                    json.encode(stop.approach_coords),
                    json.encode(stop.exit_coords),
                    json.encode(stop.queue_coords),
                    stop.base_demand or 5,
                    stop.rush_profile or 'default'
                })
                stopsCount = stopsCount + 1
            end
            print('^2[ethor_bus] ^7Imported ' .. stopsCount .. ' stops.')
        end
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
