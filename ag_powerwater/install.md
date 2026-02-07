# Installation Guide: Power & Water Department (`ag_powerwater`)

Welcome to the Power & Water Grid System. This resource manages the electrical and water infrastructure of Los Santos, including realistic failures, blackouts, and job missions.

## 1. Requirements

Ensure these resources are installed and started **before** `ag_powerwater`:
*   [ox_lib](https://github.com/overextended/ox_lib) (Latest Version)
*   [ox_target](https://github.com/overextended/ox_target) OR `qb-target`
*   **Database**: Ensure your server is connected to a MySQL database (oxmysql).

## 2. Optional Dependencies (Highly Recommended)

For the full experience, we recommend:
*   [SmartFires](https://store.londonstudios.net/) (London Studios) - For realistic Turbine & Transformer fires.
*   [Smart Hose](https://store.londonstudios.net/) (London Studios) - For putting out those fires.
*   **Weather Script**: `cd_easytime`, `vSync`, `vSyncR`, or `qb-weathersync` (For visual blackouts).

## 3. Installation

1.  Copy the `ag_powerwater` folder to your server's `resources` directory.
2.  Add `ensure ag_powerwater` to your `server.cfg`.
3.  **Important**: Ensure it starts **after** `ox_lib`.

## 4. Integrations

### A. rcore_fuel (Disable Pumps during Blackout)
To stop gas pumps from working when the local power grid is down, follow these steps:

1.  Open your `rcore_fuel` resource folders.
2.  Look for an **editable client file** or **config file** where the check `CanRefuel` (or similar) is performed.
3.  Paste the following code snippet at the start of the check function:

```lua
-- Integration: ag_powerwater (Blackout Check)
-- Returns FALSE if the grid in this zone is down (< blackout limit)
if GetResourceState('ag_powerwater') == 'started' then
    -- The 'true' argument automatically shows a notification: "Stromausfall! Zapfsäule tot."
    if not exports['ag_powerwater']:IsGridActive(GetEntityCoords(pump), true) then
        return false 
    end
end
```

### B. SmartFires & Smart Hose
*   **No configuration needed!**
*   The script automatically detects if you have `SmartFires` installed.
*   **Turbine Fires**: Will spawn a massive **Gas/Oil Fire** at the top.
*   **Transformer Fires**: Will spawn an **Electrical Fire**.
*   **Hose**: Firefighters can use the standard London Studios hose to extinguish these flames.

### C. Weather & Blackouts
The script automatically detects the following weather resources to synchronize visual blackouts:
*   `cd_easytime`
*   `vSync` / `vSyncR`
*   `qb-weathersync`

If you use a custom weather script, you can listen for the client event:
`RegisterNetEvent('ag_powerwater:client:blackoutState', function(isBlackout) ... end)`

## 5. Configuration (`config.lua`)

*   **`Config.PayPerMission`**: Set to `true` to give instant cash, or `false` if players are paid salaries via job handling.
*   **`Config.HouseCallPayout`**: If `true`, money goes to the society account (requires framework setup).
*   **`Config.FireJobs`**: List of jobs (e.g., `{'fire', 'ambulance'}`) that are required to extinguish complex fires. If NO ONE from these jobs is online, the Electrician's "Emergency Shutdown" will auto-extinguish the fire as a fail-safe.
