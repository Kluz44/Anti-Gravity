Config = {}

-- ▼ Interaktion: 'ekey', 'target', 'radial' oder 'both'
Config.InteractionMode = 'target'
Config.Interact = {
    EKeyDistance   = 2.2,
    TargetDistance = 2.5,
    TargetLabel    = 'Einchecken nach Los Santos',
    HelpText       = 'E drücken zum Einchecken',
    Show3DText     = false,
    Text3D         = '[E] Einchecken',
    Radial = { Enabled=false, Key='G', Distance=2.5, Title='Airbridge', OptionText='Einchecken' }
}

-- ▼ Check-in Ped
Config.CheckInPed = {
    model = `A_F_Y_FemaleAgent`,
    coords = vec4(-1909.6293, 3756.0381, -83.8439, 118.7003),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- ▼ Flugzeugauswahl (frei)
Config.PlaneModel = `titan20`
Config.Luftfahrzeugkennzeichen = 'ETH-463'

-- NPC Crew
Config.PilotModel   = `S_M_M_Pilot_02`
Config.CopilotModel = `S_M_M_Pilot_02`
Config.CrewModel    = `S_M_M_Pilot_02`
Config.Pilot = { Godmode=true, BlockRagdoll=true, BlockSeatShuffle=true, NoDrag=true, KeepGearUpTick=500 }

-- Routen & Flug
Config.StartPoint = vec4(-532.2598, -4764.4829, 340.5653, 352.5164)
Config.EndPoint   = vec4(-471.3706, 6032.3511, 913.7523, 3.1410)
Config.CruiseAltitude = 550.0
Config.FlightSpeed    = 85.0
Config.Loiter = { Enabled=true, PointA = vec4(-1400.0,-2500.0,550.0,110.0), PointB = vec4(3800.0,4400.0,550.0,20.0), ArriveThreshold=250.0, ReissueMs=8000, SpeedOverride=85.0 }
Config.DespawnOffset = vec3(2000.0, 2000.0, 300.0)

-- Sitz-Policy (Die Crew belegt die Sitze -1 bis 3)
Config.SeatPolicy = { AutoDiscover=true, AlwaysExclude={-1,0,1,2,3}, PerModelPreferred = {} }
Config.CargoAttachOffsets = {
    vec3(0.0,-2.2,0.85), vec3(0.6,-1.8,0.85), vec3(-0.6,-1.8,0.85),
    vec3(1.2,-2.4,0.85), vec3(-1.2,-2.4,0.85), vec3(0.0,-3.0,0.85),
    vec3(0.8,-3.0,0.85), vec3(-0.8,-3.0,0.85), vec3(1.6,-3.6,0.85), vec3(-1.6,-3.6,0.85),
}

-- Boarding & Gruppenlogik
Config.StartMode = 'window'
Config.CheckInWindowMinutes = 3
Config.MaxPlayersPerFlight = 10
Config.ReminderIntervalSeconds = 60
Config.FinalReminderSeconds = 30
Config.FlightCooldownSeconds = 180

-- UX & Notifies
Config.NotifySystem = 'qb'
Config.HelpTextPressToJump = 'F drücken zum Springen'

Config.Debug = true

-- Commands & Audit/Webhook/Throttle (kurz gehalten)
Config.Command = { UseAce=true, Ace='command.airbridge', RateLimitMs=1500, EveryoneCanUse={'status','seats','help'}, Allowlist={} }
Config.Audit = { Enabled=true, File='logs/audit.jsonl', AlsoPrint=true, MaxLinesView=50, ExportFile='logs/audit_export.csv', MaxLinesExport=500, Rotate={Enabled=true, MaxBytes=5*1024*1024, Keep=5, File='logs/audit.jsonl'} }
Config.Webhook = { Enabled=false, Url='', Username='Airbridge Audit', Avatar='', Events={'reset','kick','host','open','close','start','denied','ratelimit'}, Styles={ default={color=5793266,emoji='🛰️'} }, Throttle={ Enabled=true, WindowMs=60000, MaxEvents=8, PerSub={}, PerUser={Enabled=true, WindowMs=60000, MaxEvents=5}, Feedback={Enabled=true, CooldownMs=8000} } }
