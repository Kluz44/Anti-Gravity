Config = {}

Config.IBANPrefix = "LS12-ETH-"
Config.ServerName = "Ethorium"
Config.Target = "qb-target" -- Supports 'qb-target', 'ox_target', 'qtarget'

-- Card Tiers & Limits
Config.Cards = {
    ['Standard'] = {
        daily_limit = 10000,
        monthly_fee = 250,
        requires_balance = 0
    },
    ['Premium'] = {
        daily_limit = 25000,
        monthly_fee = 750,
        requires_balance = 0
    },
    ['Gold'] = {
        daily_limit = 75000,
        monthly_fee = 2500,
        requires_balance = 0
    },
    ['Platin'] = {
        daily_limit = -1, -- Unlimited
        monthly_fee = 10000,
        requires_balance = 100000000 -- 100 Mio Guthaben
    }
}

-- Account Types
Config.AccountTypes = {
    "personal", "business", "shared", "government", "branch", "union"
}

-- Valid Transaction Sources
Config.ValidSources = {
    "player_cash_deposit", "bank_withdraw", "bank_transfer",
    "invoice_payment", "receipt_purchase", "loan_payout",
    "loan_repayment", "job_salary", "business_income",
    "government_tax", "government_payment", "vault_transfer",
    "atm_withdraw", "transport_delivery", "admin_spawn" -- Added admin_spawn for testing/admin purposes, might need specific checks later
}

-- Loan Score Thresholds & Interests
Config.Loans = {
    scores = {
        ['high'] = { min = 700, max_amount = 250000, interest = 0.05 },
        ['medium'] = { min = 500, max_amount = 50000, interest = 0.10 },
        ['low'] = { min = 300, max_amount = 10000, interest = 0.15 },
        ['rejected'] = { max = 299 }
    }
}

-- Vault Limits
Config.VaultLimits = {
    critical_low = 25000,
    warning_low = 100000,
    warning_high = 800000,
    critical_high = 1500000
}

-- Business Payout Limits
Config.BusinessPayouts = {
    ['employee'] = 5000,
    ['manager'] = 20000,
    ['boss'] = -1 -- Unlimited
}

Config.Webhooks = {
    transactions = "ENTER_WEBHOOK_HERE",
    admin = "ENTER_WEBHOOK_HERE",
    loans = "ENTER_WEBHOOK_HERE"
}
