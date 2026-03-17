SQL = {}

-- Execute a query with oxmysql
-- @param query string The query to execute
-- @param parameters table The parameters to bind
-- @param callback function The callback function
-- @return table The result of the query
function SQL:Execute(query, parameters, callback)
    -- TODO: removed it and use s1n_lib ORM instead
    local isBusy = true
    local queryResult

    if string.find(query, 'INSERT') then
        if callback then
            exports.oxmysql:insert(query, parameters, function(result) callback(result) end)
        else
            queryResult = exports.oxmysql:insert_async(query, parameters)
            isBusy = false
        end
    elseif string.find(query, 'UPDATE') then
        if callback then
            exports.oxmysql:update(query, parameters, function(result) callback(result) end)
        else
            queryResult = exports.oxmysql:update_async(query, parameters)
            isBusy = false
        end
    else
        if callback then
            exports.oxmysql:query(query, parameters, function(result) callback(result) end)
        else
            queryResult = exports.oxmysql:query_async(query, parameters)
            isBusy = false
        end
    end

    while isBusy do
        Wait(10)
    end

    return queryResult
end