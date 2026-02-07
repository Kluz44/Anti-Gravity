-- Initialize Locales Table if not exists
if not Locales then Locales = {} end

-- Function to get localized string
-- Usage: AG.Lang('key', arg1, arg2...)
function AG.Lang(str, ...)
    local lang = Config.Locale or 'en'
    
    if Locales[lang] and Locales[lang][str] then
        return string.format(Locales[lang][str], ...)
    else
        return 'Locale [' .. lang .. '] ' .. str .. ' does not exist'
    end
end

-- Simpler alias
function _U(str, ...)
    return AG.Lang(str, ...)
end
