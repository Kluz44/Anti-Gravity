# Ethorium Banking - Developer Documentation

## Core Money System Interface
`Ethorium_Banking` is the exclusive source of truth for money movements. Do NOT use `AddMoney` or `RemoveMoney` directly in other scripts for cash/bank if it involves an actual logical transaction. Instead, use the export:

```lua
-- amount (int), isDeposit (bool), source (string), description (string)
exports['Ethorium_Banking']:ProcessMoneyMovement(account_iban, amount, isDeposit, source_name, description)
```

### Valid Sources
All transactions MUST contain a source name defined in `Config.ValidSources` (e.g. `job_salary`, `business_income`, `atm_withdraw`). If a source is not legitimate, the transaction will be blocked and an Anti-Cheat alert will fire.

## Card System
Cards are automatically generated via `exports['Ethorium_Banking']:CreateCard(account_iban, tier, pin_number)`.
To process a POS payment through another script (e.g. shop payment):
```lua
exports['Ethorium_Banking']:ProcessCardPayment(card_number, pin_number, amount, 'receipt_purchase', reason)
```

## Invoices vs Receipts
- **Receipts**: Handled immediately. Use `exports['Ethorium_Banking']:CreateReceipt(...)`. For gas stations, an extra argument `vehiclePlate` is required.
- **Invoices**: Pending payments. Use `exports['Ethorium_Banking']:CreateInvoice(...)`.

## Loans & Collateral
Loans dynamically check `player_houses` and `player_vehicles` SQL tables. Rented houses or financed cars are automatically excluded from being suitable collateral. Evaluated by `exports['Ethorium_Banking']:RequestLoan(...)`.

## ATM UI Customization
The standalone ATM UI uses a bridged format of the `rrp_realistic_atm` module inside `atm/`. To edit its HTML or CSS, check `web/atm/`. The Lua callbacks are intercepted inside `client/atm_bridge.lua` to route into QBCore and Ethorium_Banking automatically.
