local QBCore = exports['qb-core']:GetCoreObject()

RRP = RRP or {}
RRP.Locale = {}
function RRP.Locale.LoadLocale(lang) end

-- Try to load Locales if data exists in the scope, but fallback to key mapping or raw key
-- since the resource reads from locales/en.json. Let's provide a robust T() just in case.
local translations = {}
Citizen.CreateThread(function()
    local fileData = LoadResourceFile(GetCurrentResourceName(), "atm/locales/en.json")
    if fileData then
        translations = json.decode(fileData) or {}
    end
end)

function RRP.Locale.T(key)
    local keys = {}
    for k in string.gmatch(key, "([^%.]+)") do
        table.insert(keys, k)
    end
    
    local current = translations
    for i=1, #keys do
        if current and current[keys[i]] then
            current = current[keys[i]]
        else
            return key
        end
    end
    return type(current) == "string" and current or key
end

RRP.Callback = {}
function RRP.Callback.await(name, _, ...)
    local p = promise.new()
    QBCore.Functions.TriggerCallback(name, function(result)
        p:resolve(result)
    end, ...)
    return Citizen.Await(p)
end

RRP.CheckDeadStatus = function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"]
end

RRP.Controls = {
    DisableControls = function() end -- Optional: Let the script handle standard NUI focus
}

RRP.Notify = function(sys, title, msg)
    QBCore.Functions.Notify(msg, "info")
end

RRP.Dui = {}
RRP.Dui.__index = RRP.Dui
function RRP.Dui:new(o)
    local self = setmetatable({}, RRP.Dui)
    self.url = o.url
    self.width = o.width
    self.height = o.height
    
    self.duiObject = CreateDui(self.url, self.width, self.height)
    self.dictName = "duiTextureDict_" .. tostring(math.random(1000,9999))
    self.txtName = "duiTexture_" .. tostring(math.random(1000,9999))
    
    local duiHandle = GetDuiHandle(self.duiObject)
    CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(self.dictName), self.txtName, duiHandle)
    
    return self
end

function RRP.Dui:sendMessage(data)
    SendDuiMessage(self.duiObject, json.encode(data))
end

function RRP.Dui:remove()
    DestroyDui(self.duiObject)
end

RRP.Target = {
    addModel = function(models, options)
        -- Adapt the RRP target option to QB-Target
        local cleanedOptions = {}
        for _, opt in ipairs(options) do
            table.insert(cleanedOptions, {
                icon = "fas fa-credit-card",
                label = "Use ATM",
                action = function(entity)
                    if opt.onSelect then
                        opt.onSelect({entity = entity})
                    end
                end,
                canInteract = function(entity)
                    if opt.canInteract then return opt.canInteract(entity) end
                    return true
                end
            })
        end

        exports['qb-target']:AddTargetModel(models, {
            options = cleanedOptions,
            distance = 2.0
        })
    end
}

-- Provide global function RRP.Callback proxy
function RRP.Callback(...) 
    -- Some parts use RRP.Callback directly instead of await
    local args = {...}
    local name = args[1]
    local ignore = args[2]
    local cb = args[3]
    local argsList = {}
    for i=4, #args do table.insert(argsList, args[i]) end
    
    QBCore.Functions.TriggerCallback(name, function(result)
        cb(result)
    end, table.unpack(argsList))
end
