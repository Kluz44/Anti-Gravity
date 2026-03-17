RRP.Locale.LoadLocale('en')
Config = {
    Target = true, -- ps-banking->true
    ResetDailyTransactionsTime = 8 * 60 * 60, -- 8 hours
    DisablePincode = false, -- ps-banking->true
    ExitKeys = {177},
    CamEase = 1000,
    MaxDistance = 2.0,
    QbBankingAccountSelector = false,
    Inventory = "qs-inventory", -- qb-inventory || ox_inventory
    ItemName = "creditcard",
    NotifySystem = "qb",
    BankSystem = "qb", -- qb, ps, esx, sky_banking
    PinInDB = false, -- set to false (later update)
    AudioSettings = {
        NumPad = {
            audioFile = "./numPadBeep.flac",
            audioVolume = 0.5,
        },
        CashCounter = {
            audioFile = "./cashcounter.flac",
            audioVolume = 0.5,
        },
    }
}
if Config.Target then
    Config.TargetOptions = {
        label = 'Open ATM',
        icon = 'fas fa-university',
    }
end

----------------
-- Tax system --
----------------

Config.Tax = {
    Deposit = {
        Min = 1,
        Max = 1000000,
        Percent = 0.05,
        Free = 50000,
        FreeTransactions = 2,
        MinTax = 100,
        DailyLimit = -1,
        DailyLimitAmount = 100000,
        CanMinus = true
    },
    Withdraw = {
        Min = 1,                -- minimum amount to withdraw per transaction
        Max = 1000000,             -- maximum amount to withdraw per transaction
        Percent = 0.05,            -- tax percent
        Free = 50000,              -- free amount/day
        FreeTransactions = 2,      -- free transactions (max Config.Free)/day
        MinTax = 100,              -- minimum tax
        DailyLimit = -1,           -- daily limit, -1 = unlimited
        DailyLimitAmount = 100000, -- daily limit amount, -1 = unlimited
        CanMinus = true           -- can the player go negative
    }
}

-------------------
-- Anim settings --
-------------------

Config.Objects = {
    Cash = `prop_anim_cash_note`,
    Card = `prop_cs_credit_card`
}

Config.AnimSettings = {
    InsertCard = {
        Object = true,
        IsLocal = true,
        Female = { -- i use 'IsPedMale()' native function https://docs.fivem.net/natives/?_0x6D9F5FAA7488BA46
            Insert = {
                Dict = {
                    Default = 'amb@prop_human_atm@female@enter',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@female@enter',
                },
                Anim = {
                    Default = 'enter',
                    [`prop_atm_01`] = 'enter',
                }
            },
            Remove = {
                Dict = {
                    Default = 'amb@prop_human_atm@female@enter',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@female@enter',
                },
                Anim = {
                    Default = 'enter',
                    [`prop_atm_01`] = 'enter',
                }
            }

        },
        Male = {
            Insert = {
                Dict = {
                    Default = 'amb@prop_human_atm@male@enter',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@male@enter',
                },
                Anim = {
                    Default = 'enter',
                    [`prop_atm_01`] = 'enter',
                }
            },
            Remove = {
                Dict = {
                    Default = 'amb@prop_human_atm@male@enter',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@male@enter',
                },
                Anim = {
                    Default = 'enter',
                    [`prop_atm_01`] = 'enter',
                }
            }
        }
    },
    MoneyDepositAndWithdraw = {
        Object = true,
        IsLocal = true,
        Female = { -- i use 'IsPedMale()' native function https://docs.fivem.net/natives/?_0x6D9F5FAA7488BA46
            Insert = {
                Dict = {
                    Default = 'amb@prop_human_atm@female@exit',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@female@exit',
                },
                Anim = {
                    Default = 'exit',
                    [`prop_atm_01`] = 'exit',
                }
            },
            Remove = {
                Dict = {
                    Default = 'amb@prop_human_atm@male@exit',
                    [`prop_atm_01`] = 'anim@amb@prop_human_atm@interior@male@exit',
                },
                Anim = {
                    Default = 'exit',
                    [`prop_atm_01`] = 'exit',
                }
            }

        },
        Male = {
            Insert = {
                Dict = {
                    Default = 'mp_common',
                    [`prop_atm_01`] = 'mp_common',
                },
                Anim = {
                    Default = 'givetake1_a',
                    [`prop_atm_01`] = 'givetake1_a',
                }
            },
            Remove = {
                Dict = {
                    Default = 'mp_common',
                    [`prop_atm_01`] = 'mp_common',
                },
                Anim = {
                    Default = 'givetake1_a',
                    [`prop_atm_01`] = 'givetake1_a',
                }
            }
        }
    },
}

Config.Offsets = {
    CardPos = {
        Default = {
            First = vector3(0.25, 0.05, 1.20),
            Second = vector3(0.25, 0.12, 1.20),
            Rot = vector2(-90.0, 90.0)
        },
        [`prop_atm_01`] = { -- store
            First = vector3(0.20, -0.25, 1.12),
            Second = vector3(0.20, -0.16, 1.12),
            Rot = vector2(-90.0, 90.0)
        },
    },
    MoneyDeposit = {
        Default = {
            First = vector3(-0.10, 0.00, 0.94),
            Second = vector3(-0.08, 0.12, 0.94),
            Rot = vector2(0, 0.0)
        },
        [`prop_atm_01`] = { -- store
            First = vector3(-0.05, -0.30, 0.75),
            Second = vector3(-0.05, -0.20, 0.75),
            Rot = vector2(0, 0)
        },

    },
    MoneyWithdraw = {
        Default = {
            First = vector3(0.28, 0.20, 0.94),
            Second = vector3(0.25, 0.00, 0.94),
            Rot = vector2(0, 0.0)
        },
        [`prop_atm_01`] = { -- store
            First = vector3(-0.05, -0.20, 0.75),
            Second = vector3(-0.05, -0.30, 0.75),
            Rot = vector2(0, 0)
        },

    },
}

-----------------------------
-- ATM models and settings --
-----------------------------

Config.ATMs = {
    [`prop_atm_02`] = { -- blue
        modelName = "prop_atm_02",
        canDeposit = true,
        colorHash = '#2f4c8f',
        btnColorHash = '#007b5e96',
        waterMarkLink = './fleeca-logo.webp',
        OriginalDict = "prop_atm_02",              -- do not change this exept if you know what you are doing
        OriginalTexture = "prop_cashpoint_screen", -- do not change this exept if you know what you are doing
    },
    [`prop_atm_03`] = {                            -- red
        modelName = "prop_atm_03",
        canDeposit = true,
        colorHash = '#592123',
        btnColorHash = '#592123',
        waterMarkLink = './fleeca-logo.webp',
        OriginalDict = "prop_atm_03",              -- do not change this exept if you know what you are doing
        OriginalTexture = "prop_cashpoint_screen", -- do not change this exept if you know what you are doing
    },
    [`prop_fleeca_atm`] = {                        -- green
        modelName = "prop_fleeca_atm",
        canDeposit = true,
        colorHash = '#2a714f',
        btnColorHash = '#007b5e96',
        waterMarkLink = './fleeca-logo.webp',
        OriginalDict = "prop_fleeca_atm",     -- do not change this exept if you know what you are doing
        OriginalTexture = "prop_fleece_emis", -- do not change this exept if you know what you are doing
    },
    [`prop_atm_01`] = {                       -- store
        modelName = "prop_atm_01",
        canDeposit = false,
        colorHash = '#2f4c8f',
        btnColorHash = '#007b5e96',
        waterMarkLink = './fleeca-logo.webp',
        OriginalDict = "prop_atm_01",              -- do not change this exept if you know what you are doing
        OriginalTexture = "prop_cashpoint_screen", -- do not change this exept if you know what you are doing
    },
}

Config.Scorched = {
    SetScorched = true, -- set to false if you do not want to use the scorched system
    --CustomFuncDisable = function(atmEntity) -- default: SetEntityRenderScorched(atmEntity, false)
    -- insert your custom function here
    --end,
    --CustomFuncEnable = function(atmEntity) -- default: SetEntityRenderScorched(atmEntity, true)
    -- insert your custom function here
    --end
}

-- Disable controls for movements, hit, and shoot
Config.DisableControls = {
    30,  -- Move Left/Right
    31,  -- Move Up/Down

    25,  -- Aim
    37,  -- Select Weapon
    44,  -- Cover
    140, -- Melee Attack Light
    141, -- Melee Attack Heavy
    142, -- Melee Attack Alternate
    143, -- Melee Block
}

---------------------
-- Camera settings --
---------------------

-- Do not touch this unless you know what you are doing
-- If you change the camera then you need to change the ratios too
Config.CameraFov = 70.0
Config.CamOffsets = {
    Default = vector3(-0.09994507, -0.4500122, 1.379971),
    [`prop_atm_01`] = vector3(0.000000, -0.500024, 1.21002)
}
Config.CamRots = {
    Default = vector3(-0.1, 3.739997, -0.7399989),
    [`prop_atm_01`] = vector3(0.000000, 0.200000, 0.75000)
}
Config.DuiRes = {
    [`prop_fleeca_atm`] = { 1533, 1117 },
    Default = { 742, 512 }
}
Config.DuiUrl = ("nui://%s/web/index.html"):format(GetCurrentResourceName())
Config.Ratios = {
    [`prop_atm_02`] = {                                                                                                       -- blue
        { action = "btn-1",  x = 0.33860938383267, y = 0.33575129533679, x2 = 0.36630864895421, y2 = 0.36683937823834 },      -- gomb 1
        { action = "btn-2",  x = 0.34313171283211, y = 0.41243523316062, x2 = 0.36913510457886, y2 = 0.44248704663212 },      -- gomb 2
        { action = "btn-3",  x = 0.34652345958168, y = 0.49222797927461, x2 = 0.3719615602035,  y2 = 0.52124352331606 },      -- gomb 3
        { action = "btn-4",  x = 0.34991520633126, y = 0.56165803108808, x2 = 0.37478801582815, y2 = 0.59067357512953 },      -- gomb 4
        { action = "btn-5",  x = 0.6031656302996,  y = 0.33575129533679, x2 = 0.62860373092142, y2 = 0.36580310880829 },      -- gomb 5
        { action = "btn-6",  x = 0.60090446579989, y = 0.41243523316062, x2 = 0.62521198417185, y2 = 0.44041450777202 },      -- gomb 6
        { action = "btn-7",  x = 0.5992085924251,  y = 0.49222797927461, x2 = 0.6223855285472,  y2 = 0.51917098445596 },      -- gomb 7
        { action = "btn-8",  x = 0.59694742792538, y = 0.56165803108808, x2 = 0.61955907292256, y2 = 0.58963730569948 },      -- gomb 8
        { action = "num-1",  x = 0.44036178631995, y = 0.76787564766839, x2 = 0.45732052006783, y2 = 0.80310880829016 },      -- 1
        { action = "num-2",  x = 0.4624081401922,  y = 0.76787564766839, x2 = 0.48049745618994, y2 = 0.8020725388601 },       -- 2
        { action = "num-3",  x = 0.48445449406444, y = 0.76683937823834, x2 = 0.50254381006218, y2 = 0.80310880829016 },      -- 3
        { action = "CANCEL", x = 0.50593555681176, y = 0.76787564766839, x2 = 0.52515545505936, y2 = 0.80310880829016 },      -- CANCEL
        { action = "num-4",  x = 0.43753533069531, y = 0.81036269430052, x2 = 0.45505935556812, y2 = 0.84870466321244 },      -- 4
        { action = "num-5",  x = 0.46071226681741, y = 0.81036269430052, x2 = 0.47936687394008, y2 = 0.84974093264249 },      -- 5
        { action = "num-6",  x = 0.48388920293951, y = 0.80932642487047, x2 = 0.50254381006218, y2 = 0.84870466321244 },      -- 6
        { action = "CLEAR",  x = 0.50593555681176, y = 0.81036269430052, x2 = 0.52572074618428, y2 = 0.84974093264249 },      -- CLEAR
        { action = "num-7",  x = 0.43470887507066, y = 0.8559585492228,  x2 = 0.45336348219333, y2 = 0.90155440414508 },      -- 7
        { action = "num-8",  x = 0.45845110231769, y = 0.85699481865285, x2 = 0.47823629169022, y2 = 0.90051813471503 },      -- 8
        { action = "num-9",  x = 0.48219332956473, y = 0.8559585492228,  x2 = 0.50367439231204, y2 = 0.90051813471503 },      -- 9
        { action = "ENTER",  x = 0.50593555681176, y = 0.85699481865285, x2 = 0.527981910684,   y2 = 0.90051813471503 },      -- ENTER
        { action = "EMPTY",  x = 0.43131712832109, y = 0.90777202072539, x2 = 0.45110231769361, y2 = 0.95751295336788 },      --
        { action = "num-0",  x = 0.45618993781798, y = 0.90777202072539, x2 = 0.47767100056529, y2 = 0.95854922279793 },      -- 0
        { action = "EMPTY",  x = 0.4816280384398,  y = 0.90777202072539, x2 = 0.50367439231204, y2 = 0.95751295336788 },      --
        { action = "EMPTY",  x = 0.50593555681176, y = 0.90777202072539, x2 = 0.52911249293386, y2 = 0.95751295336788 },      --
        { action = "CARD",   x = 0.6837899543379,  y = 0.31171548117155, x2 = 0.81792237442922, y2 = 0.5407949790795 },       -- CARD
    },
    [`prop_atm_03`] = {                                                                                                       --red
        { action = "btn-1",  x = 0.33408705483324, y = 0.33471502590674, x2 = 0.36178631995478, y2 = 0.36062176165803 },
        { action = "btn-2",  x = 0.33804409270774, y = 0.41139896373057, x2 = 0.36517806670435, y2 = 0.43937823834197 },
        { action = "btn-3",  x = 0.34200113058225, y = 0.49533678756477, x2 = 0.36743923120407, y2 = 0.51917098445596 },
        { action = "btn-4",  x = 0.34539287733183, y = 0.56683937823834, x2 = 0.37026568682872, y2 = 0.59274611398964 },
        { action = "btn-5",  x = 0.60655737704918, y = 0.33367875647668, x2 = 0.631995477671,   y2 = 0.36165803108808 },
        { action = "btn-6",  x = 0.60429621254946, y = 0.41347150259067, x2 = 0.62916902204635, y2 = 0.44041450777202 },
        { action = "btn-7",  x = 0.60203504804975, y = 0.49430051813472, x2 = 0.62464669304692, y2 = 0.52020725388601 },
        { action = "btn-8",  x = 0.59977388355003, y = 0.56787564766839, x2 = 0.6223855285472,  y2 = 0.59274611398964 },
        { action = "num-1",  x = 0.43866591294517, y = 0.77616580310881, x2 = 0.45675522894291, y2 = 0.81554404145078 },
        { action = "num-2",  x = 0.46127755794234, y = 0.77616580310881, x2 = 0.47993216506501, y2 = 0.81450777202073 },
        { action = "num-3",  x = 0.48332391181458, y = 0.77616580310881, x2 = 0.50310910118711, y2 = 0.81450777202073 },
        { action = "CANCEL", x = 0.50537026568683, y = 0.77616580310881, x2 = 0.52628603730921, y2 = 0.81450777202073 },
        { action = "num-4",  x = 0.43583945732052, y = 0.82072538860104, x2 = 0.45449406444319, y2 = 0.86217616580311 },
        { action = "num-5",  x = 0.45901639344262, y = 0.81968911917098, x2 = 0.47993216506501, y2 = 0.86321243523316 },
        { action = "num-6",  x = 0.48275862068966, y = 0.81968911917098, x2 = 0.50367439231204, y2 = 0.86321243523316 },
        { action = "CLEAR",  x = 0.50537026568683, y = 0.82072538860104, x2 = 0.527981910684,   y2 = 0.86217616580311 },
        { action = "num-7",  x = 0.43244771057094, y = 0.86943005181347, x2 = 0.45166760881854, y2 = 0.91502590673575 },
        { action = "num-8",  x = 0.45732052006783, y = 0.86943005181347, x2 = 0.47767100056529, y2 = 0.91502590673575 },
        { action = "num-9",  x = 0.48106274731487, y = 0.86839378238342, x2 = 0.50367439231204, y2 = 0.91502590673575 },
        { action = "ENTER",  x = 0.50593555681176, y = 0.86943005181347, x2 = 0.52911249293386, y2 = 0.91709844559585 },
        { action = "EMPTY",  x = 0.42905596382137, y = 0.92331606217617, x2 = 0.44940644431882, y2 = 0.97512953367876 },
        { action = "num-0",  x = 0.45505935556812, y = 0.92331606217617, x2 = 0.47710570944036, y2 = 0.97512953367876 },
        { action = "EMPTY",  x = 0.48106274731487, y = 0.92331606217617, x2 = 0.50367439231204, y2 = 0.9740932642487 },
        { action = "EMPTY",  x = 0.50650084793669, y = 0.92331606217617, x2 = 0.53024307518372, y2 = 0.97512953367876 },
        { action = "CARD",   x = 0.6837899543379,  y = 0.31171548117155, x2 = 0.81792237442922, y2 = 0.5407949790795 },
    },
    [`prop_fleeca_atm`] = { -- green
        { action = "btn-1", x = 0.34189497716895, y = 0.3336820083682,  x2 = 0.36929223744292, y2 = 0.3755230125523 },
        { action = "btn-2", x = 0.3458904109589,  y = 0.40585774058577, x2 = 0.37214611872146, y2 = 0.44769874476987 },
        { action = "btn-3", x = 0.34931506849315, y = 0.47384937238494, x2 = 0.37557077625571, y2 = 0.51569037656904 },
        { action = "btn-4", x = 0.35216894977169, y = 0.5397489539749,  x2 = 0.37842465753425, y2 = 0.5847280334728 },
        { action = "btn-5", x = 0.60045662100457, y = 0.3336820083682,  x2 = 0.625,            y2 = 0.3744769874477 },
        { action = "btn-6", x = 0.59817351598174, y = 0.40899581589958, x2 = 0.62271689497717, y2 = 0.44874476987448 },
        { action = "btn-7", x = 0.5958904109589,  y = 0.47803347280335, x2 = 0.62043378995434, y2 = 0.51569037656904 },
        { action = "btn-8", x = 0.59360730593607, y = 0.54393305439331, x2 = 0.6175799086758,  y2 = 0.5826359832636 },
        { action = "num-1", x = 0.43892694063927, y = 0.75836820083682, x2 = 0.45776255707763, y2 = 0.79602510460251 },
        { action = "num-2", x = 0.46118721461187, y = 0.76046025104603, x2 = 0.48116438356164, y2 = 0.79602510460251 },
        { action = "num-3", x = 0.48458904109589, y = 0.76150627615063, x2 = 0.50456621004566, y2 = 0.79602510460251 },
        { action = "num-4", x = 0.43664383561644, y = 0.80230125523013, x2 = 0.45547945205479, y2 = 0.84205020920502 },
        { action = "num-5", x = 0.46004566210046, y = 0.80230125523013, x2 = 0.48002283105023, y2 = 0.84100418410042 },
        { action = "num-6", x = 0.48344748858447, y = 0.80230125523013, x2 = 0.50456621004566, y2 = 0.84100418410042 },
        { action = "num-7", x = 0.4337899543379,  y = 0.84832635983264, x2 = 0.45376712328767, y2 = 0.89225941422594 },
        { action = "num-8", x = 0.45776255707763, y = 0.84937238493724, x2 = 0.47888127853881, y2 = 0.89330543933054 },
        { action = "num-9", x = 0.48287671232877, y = 0.84832635983264, x2 = 0.50456621004566, y2 = 0.89225941422594 },
        { action = "num-0", x = 0.45547945205479, y = 0.89958158995816, x2 = 0.4777397260274,  y2 = 0.94769874476987 },
        { action = "CLEAR", x = 0.43036529680365, y = 0.89958158995816, x2 = 0.45148401826484, y2 = 0.94874476987448 },
        { action = "ENTER", x = 0.48173515981735, y = 0.90062761506276, x2 = 0.50513698630137, y2 = 0.94874476987448 },
        { action = "EMPTY", x = 0.50684931506849, y = 0.76150627615063, x2 = 0.52682648401826, y2 = 0.79707112970711 },
        { action = "EMPTY", x = 0.50684931506849, y = 0.80439330543933, x2 = 0.52853881278539, y2 = 0.84205020920502 },
        { action = "EMPTY", x = 0.5074200913242,  y = 0.84832635983264, x2 = 0.5296803652968,  y2 = 0.89225941422594 },
        { action = "EMPTY", x = 0.50799086757991, y = 0.90062761506276, x2 = 0.53196347031963, y2 = 0.94874476987448 },
        { action = "CARD",  x = 0.6837899543379,  y = 0.31171548117155, x2 = 0.81792237442922, y2 = 0.5407949790795 },
        { action = "MONEY", x = 0.3898401826484,  y = 0.65062761506276, x2 = 0.57762557077626, y2 = 0.73117154811715 }
    },
    [`prop_atm_01`] = { -- small
        { action = "btn-1", x = 0.27099664053751, y = 0.17641025641026, x2 = 0.3006718924972,  y2 = 0.20820512820513 },
        { action = "btn-2", x = 0.28051511758119, y = 0.2574358974359,  x2 = 0.31019036954087, y2 = 0.28923076923077 },
        { action = "btn-3", x = 0.28891377379619, y = 0.33846153846154, x2 = 0.31802911534155, y2 = 0.36923076923077 },
        { action = "btn-4", x = 0.2973124300112,  y = 0.40615384615385, x2 = 0.32586786114222, y2 = 0.43487179487179 },
        { action = "btn-5", x = 0.57838745800672, y = 0.17435897435897, x2 = 0.60750279955207, y2 = 0.21025641025641 },
        { action = "btn-6", x = 0.57446808510638, y = 0.25641025641026, x2 = 0.60246360582307, y2 = 0.28615384615385 },
        { action = "btn-7", x = 0.57166853303471, y = 0.3374358974359,  x2 = 0.59742441209406, y2 = 0.36512820512821 },
        { action = "btn-8", x = 0.57054871220605, y = 0.40615384615385, x2 = 0.59406494960806, y2 = 0.43076923076923 },
        { action = "num-1", x = 0.40929451287794, y = 0.63487179487179, x2 = 0.43337066069429, y2 = 0.67282051282051 },
        { action = "num-2", x = 0.43729003359462, y = 0.63589743589744, x2 = 0.46080627099664, y2 = 0.67282051282051 },
        { action = "num-3", x = 0.46472564389698, y = 0.63589743589744, x2 = 0.48880179171333, y2 = 0.67282051282051 },
        { action = "num-4", x = 0.40817469204927, y = 0.67897435897436, x2 = 0.43169092945129, y2 = 0.71794871794872 },
        { action = "num-5", x = 0.43617021276596, y = 0.67794871794872, x2 = 0.46024636058231, y2 = 0.71692307692308 },
        { action = "num-6", x = 0.46360582306831, y = 0.67897435897436, x2 = 0.48880179171333, y2 = 0.71794871794872 },
        { action = "num-7", x = 0.40649496080627, y = 0.72512820512821, x2 = 0.43057110862262, y2 = 0.76307692307692 },
        { action = "num-8", x = 0.43505039193729, y = 0.72307692307692, x2 = 0.46024636058231, y2 = 0.76410256410256 },
        { action = "num-9", x = 0.46304591265398, y = 0.72307692307692, x2 = 0.48768197088466, y2 = 0.76410256410256 },
        { action = "CLEAR", x = 0.4036954087346,  y = 0.77230769230769, x2 = 0.42889137737962, y2 = 0.81333333333333 },
        { action = "num-0", x = 0.43337066069429, y = 0.77128205128205, x2 = 0.45912653975364, y2 = 0.81230769230769 },
        { action = "ENTER", x = 0.46248600223964, y = 0.77025641025641, x2 = 0.48824188129899, y2 = 0.81230769230769 },
        { action = "CARD",  x = 0.70884658454647, y = 0.15794871794872, x2 = 0.84266517357223, y2 = 0.4174358974359 }
    }
}

----------------------
-- Shared functions --
----------------------

Shared = {}
Shared.CoordsToString = function(coords)
    return string.format('%s,%s,%s', coords.x, coords.y, coords.z)
end
