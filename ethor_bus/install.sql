-- =============================================
-- ethor_bus Installation Database Schema
-- Framework: QBCore / oxmysql
-- =============================================

-- 1. Companies Table
CREATE TABLE IF NOT EXISTS `bus_companies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `owner_identifier` varchar(50) DEFAULT NULL,
  `bank_balance` int(11) DEFAULT 0,
  `rating` float DEFAULT 100.0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Global Bus Stops Table
CREATE TABLE IF NOT EXISTS `bus_stops` (
  `id` varchar(50) NOT NULL, -- e.g. 'stop_legion_square'
  `name` varchar(100) NOT NULL,
  `coords` longtext NOT NULL, -- JSON {x,y,z,h} (Prop/Sign position)
  `approach_coords` longtext DEFAULT NULL, -- Bus Halt Position
  `exit_coords` longtext DEFAULT NULL, -- Ped routing after exit
  `queue_coords` longtext DEFAULT NULL, -- Waiting ped positions
  `base_demand` int(11) DEFAULT 5, -- Base chance/number of peds
  `rush_profile` varchar(50) DEFAULT 'default',
  `spawn_cap` int(11) DEFAULT 10,
  `current_backlog` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 3. Bus Routes Table
CREATE TABLE IF NOT EXISTS `bus_routes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `company_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL, -- e.g. 'Line 54 Metro'
  `color` varchar(7) DEFAULT '#ffffff',
  `stops_json` longtext NOT NULL, -- Ordered array of stop IDs
  `waypoints_json` longtext DEFAULT NULL, -- GPS Polyline Data
  PRIMARY KEY (`id`),
  FOREIGN KEY (`company_id`) REFERENCES `bus_companies`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 4. Active Trips (State Persistence Phase 1 & 3)
CREATE TABLE IF NOT EXISTS `bus_active_trips` (
  `id` varchar(50) NOT NULL,
  `route_id` int(11) NOT NULL,
  `bus_netid` int(11) DEFAULT NULL,
  `bus_plate` varchar(20) DEFAULT NULL,
  `driver_type` ENUM('human', 'ai') DEFAULT 'human',
  `driver_identifier` varchar(50) DEFAULT NULL,
  `current_stop_index` int(11) DEFAULT 1,
  `mood_score` int(11) DEFAULT 100,
  `passengers_total` int(11) DEFAULT 0,
  `bus_health` int(11) DEFAULT 100, -- Phase 3 Maintenance
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 5. System Properties (For Tracking Imports etc.)
CREATE TABLE IF NOT EXISTS `bus_sys_properties` (
  `key_name` varchar(50) NOT NULL,
  `key_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 6. Stop Requests (Phase 2)
CREATE TABLE IF NOT EXISTS `bus_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `company_id` int(11) NOT NULL,
  `coords` longtext NOT NULL,
  `name` varchar(100) NOT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `status` ENUM('pending', 'accepted', 'denied') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`company_id`) REFERENCES `bus_companies`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 7. Advertising System (Phase 3)
CREATE TABLE IF NOT EXISTS `bus_ads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `company_id` int(11) NOT NULL,
  `image_url` varchar(500) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`company_id`) REFERENCES `bus_companies`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Insert initial flag so we check it on start
INSERT IGNORE INTO `bus_sys_properties` (`key_name`, `key_value`) VALUES ('initial_import_done', '0');
