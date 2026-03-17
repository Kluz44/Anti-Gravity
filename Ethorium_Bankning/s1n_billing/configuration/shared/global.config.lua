Config = Config or {}

-- The Framework (QB/ESX) is detected automatically with our script s1n_lib (If an error occurs, you can set the framework name manually in the configuration file of s1n_lib)

-- To modify the language, go to the fxmanifest.lua file and replace 'languages/english.lua' with the language you want (like 'languages/french.lua')

-- Set to true to show debug messages in the console or false to hide them
Config.DebugMode = true

-- You need to verify that the following scripts are exactly named like this or change the names here
Config.ExportNames = {
    s1nLib = "s1n_lib",
}

Config.Keys = {
    -- The key to open the billing menu
    openBillingMenu = "B",
}

-- The permissions for the billing system
Config.Permissions = {
    -- The permission to create an invoice as a company, view company invoices, pay them (what jobs and job grades can create an invoice as a company)
    MANAGE_COMPANY_INVOICES = {
        jobs = {
            -- The job name (write it in lowercase)
            ["police"] = {
                -- The job grade name (write it in lowercase)
                ["officer"] = true,
                ["sergeant"] = true,
                ["lieutenant"] = true,
                ["captain"] = true,
                ["chief"] = true,
            }
        }
    },

    -- The permission to review invoices of someone (what jobs and job grades can review the invoices of someone)
    REVIEW_SOMEONE_INVOICES = {
        jobs = {
            -- The job name (write it in lowercase)
            ["police"] = {
                -- The job grade name (write it in lowercase)
                ["officer"] = true,
                ["sergeant"] = true,
                ["lieutenant"] = true,
                ["captain"] = true,
                ["chief"] = true,
            }
        }
    }
}

-- All configurations related to the contract system
Config.Contract = {
    closestPlayer = {
        -- Distance to which the seller needs to be close to another player to create a contract
        distance = 10.0,
    },

    closestOwnedVehicle = {
        -- Distance to which tge seller needs to be close to his vehicle to create a contract for it
        distance = 10.0,
    }
}

-- All configurations related to the invoice system
Config.Invoice = {
    -- All configurations related to the VAT system
    vat = {
        -- Enable or disable the VAT system
        enabled = false,

        -- The tax rate for the invoices (Must be a number between 0 and 1, example: 0.2 = 20%)
        rate = 0.2,

        -- The exact name of the company which will receive the VAT (If empty, the VAT won't be send to anyone but still be applied)
        -- If you're using ESX, you need to use the following name: "society_<job_name>" (example: "society_police").
        -- If you have any errors on your server-console when VAT is enabled, their is a VERY HIGH probability that the name is wrong.
        beneficiaryCompany = ""
    },

    -- The default items which can be selected when creating an invoice
    defaultItems = {
        {
            name = "Gave him a ride",
        },
        {
            name = "Helped him with his car",
        },
        {
            name = "Gave him a repair kit",
        },
        {
            name = "Other",
        }
    },

    -- The items which can be selected when creating an invoice for a specific job
    jobsItems = {
        ["police"] = {
            defaultItems = {
                {
                    name = "Reckless Driving",
                },
                {
                    name = "Speeding",
                },
                {
                    name = "Parking Violation",
                },
                {
                    name = "Illegal Parking",
                },
                {
                    name = "Driving Without a License",
                },
                {
                    name = "Driving Without Insurance",
                },
                {
                    name = "Driving Without Registration",
                },
                {
                    name = "Driving Without a Seatbelt",
                },
                {
                    name = "Driving Without a Helmet",
                },
                {
                    name = "Driving Under the Influence",
                },
                {
                    name = "Hit and Run",
                },
                {
                    name = "Reckless Endangerment",
                },
                {
                    name = "Resisting Arrest",
                },
                {
                    name = "Assault on a Police Officer",
                },
            }
        }
    },

    note = {
        -- The maximum length of the note when creating an invoice
        maxLength = 40,
    },
}