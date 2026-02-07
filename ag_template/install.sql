CREATE TABLE IF NOT EXISTS `ag_data` (
  `identifier` varchar(255) NOT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
