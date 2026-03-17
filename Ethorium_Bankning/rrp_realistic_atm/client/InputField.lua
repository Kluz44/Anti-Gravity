InputField = {}
InputField.__index = InputField

function InputField:new(dui, maxLength, type)
    local obj = {
        dui = dui,
        maxLength = maxLength or 4,
        value = "",
        type = type,
    }
    setmetatable(obj, self)
    return obj
end

function InputField:addCharacter(char)
    if #self.value < self.maxLength then
        self.value = self.value .. char
        local sendValue = self.value
        if self.type == "password" then
            sendValue = string.rep("*", #self.value)
        end
        SendDuiMessage(self.dui, json.encode({
            action = "updateInput",
            value = sendValue
        }))
    end
end

function InputField:removeCharacter()
    self.value = self.value:sub(1, -2)
    local sendValue = self.value
    if self.type == "password" then
        sendValue = string.rep("*", #self.value)
    end
    SendDuiMessage(self.dui, json.encode({
        action = "updateInput",
        value = sendValue
    }))
end

function InputField:getValue()
    return self.value
end

function InputField:clear()
    self.value = ""
    SendDuiMessage(self.dui, json.encode({
        action = "updateInput",
        value = self.value
    }))
end

return InputField