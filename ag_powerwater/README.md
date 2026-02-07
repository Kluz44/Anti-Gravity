# AG Template - Master Base
**DO NOT EDIT THIS FOLDER DIRECTLY FOR NEW SCRIPTS.**

This is the master template for the Anti-Gravity Development Team.
It contains:
- Framework Bridge (ESX/QBCore/QBox)
- System Detection (Inventory, Phone, Garage, Notify, Weather)
- Buffered Database Storage (JSON -> MySQL)
- Localization System (de/en)
- UI Boilerplate (HTML/JS/CSS)

## How to create a new script
Run the `new_resource.ps1` script in the root folder:
```powershell
./new_resource.ps1 -Name "my_new_script"
```
This will copy this template and rename all necessary files and variables.
