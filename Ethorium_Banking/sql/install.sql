CREATE TABLE IF NOT EXISTS `ethorium_accounts` (
  `iban` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'personal', -- personal, business, shared, government, branch, union
  `citizenid` varchar(50) DEFAULT NULL, -- Owner (if personal)
  `business_name` varchar(50) DEFAULT NULL, -- Owner (if business)
  `balance` int(11) NOT NULL DEFAULT 0,
  `is_frozen` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`iban`),
  KEY `citizenid` (`citizenid`),
  KEY `business_name` (`business_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ethorium_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `trace_id` varchar(100) NOT NULL,
  `account_iban` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `type` varchar(10) NOT NULL, -- 'deposit', 'withdraw', 'transfer'
  `source` varchar(50) NOT NULL, -- player_cash_deposit, bank_withdraw, atm_withdraw, etc.
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `account_iban` (`account_iban`),
  KEY `trace_id` (`trace_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ethorium_cards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `card_number` varchar(50) NOT NULL,
  `account_iban` varchar(50) NOT NULL,
  `tier` varchar(20) NOT NULL DEFAULT 'Standard', -- Standard, Premium, Gold, Platin
  `pin_hash` varchar(255) NOT NULL,
  `is_locked` tinyint(1) NOT NULL DEFAULT 0,
  `failed_attempts` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `card_number` (`card_number`),
  KEY `account_iban` (`account_iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ethorium_invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_identifier` varchar(50) NOT NULL, -- citizenid or job
  `receiver_citizenid` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `reference` varchar(50) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'unpaid', -- unpaid, paid, overdue
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `receiver_citizenid` (`receiver_citizenid`),
  UNIQUE KEY `reference` (`reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ethorium_loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `remaining_amount` int(11) NOT NULL,
  `interest_rate` decimal(5,2) NOT NULL,
  `collateral_type` varchar(20) DEFAULT NULL, -- 'house', 'vehicle'
  `collateral_id` varchar(50) DEFAULT NULL, -- house id or vehicle plate
  `collateral_value` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ethorium_banks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `type` varchar(20) NOT NULL, -- 'bank', 'atm'
  `vault_balance` int(11) NOT NULL DEFAULT 0,
  `data` longtext NOT NULL DEFAULT '{}', -- store coords, npc info, interaction points
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
