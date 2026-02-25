AG.Phone = {}

-- [[ SEND MAIL ]]
-- data: { sender = 'Police', subject = 'Ticket', message = 'You have a fine', button = {} }
function AG.Phone.SendMail(source, data)
    local phoneSystem = AG.System.Phone
    if not source then return end

    -- QS SMARTPHONE (Standard & Pro)
    if phoneSystem == 'qs-smartphone' or phoneSystem == 'qs-smartphone-pro' then
        if IsDuplicityVersion() then
            TriggerClientEvent('qs-smartphone:client:CustomNotification', source, 'MAIL', data.sender, data.message, 'fas fa-envelope', '#ff0000', 5000)
            -- Or proper mail function if available
        end

    -- LB PHONE
    elseif phoneSystem == 'lb-phone' then
        if IsDuplicityVersion() then
            -- exports["lb-phone"]:SendMail(source, sender, subject, message, attachments, actions)
            exports["lb-phone"]:SendMail(source, data.sender, data.subject, data.message)
        end

    -- GKS PHONE
    elseif phoneSystem == 'gksphone' then
         if IsDuplicityVersion() then
            exports["gksphone"]:SendNewMail(source, {
                sender = data.sender,
                subject = data.subject,
                message = data.message,
                button = data.button
            })
         end

    -- OKOK PHONE
    elseif phoneSystem == 'okokPhone' then
        -- Often triggers client event
        TriggerClientEvent('okokPhone:client:newMail', source, {
            sender = data.sender,
            subject = data.subject,
            message = data.message
        })
        
    -- QB DEFAULT PHONE
    elseif phoneSystem == 'qb-phone' or AG.Framework == 'qbcore' then
        TriggerClientEvent('qb-phone:client:CustomNotification', source, 'MAIL', data.message, 'fas fa-envelope', '#ff0000', 5000)
    end
end
