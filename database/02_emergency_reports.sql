-- emergency_reports: used by report_emergency.php, process_emergency.php,
-- resolve_emergency.php and admin_dashboard.php, but missing from the
-- original phpMyAdmin dump (mafqoodak1.sql). Columns rebuilt from that code.

CREATE TABLE IF NOT EXISTS `emergency_reports` (
  `emergency_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `person_name` varchar(100) DEFAULT NULL,
  `approx_age` varchar(20) NOT NULL,
  `last_seen_location` varchar(150) NOT NULL,
  `clothing_description` text NOT NULL,
  `reporter_phone` varchar(20) NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`emergency_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `emergency_reports_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
