-- 04_complete_features.sql
-- Adds everything the API, the website and the mobile app need to share one backend.
-- Safe to run once on top of 01 + 02 + 03.

-- 1. API login tokens (mobile app sends "Authorization: Bearer <token>")
CREATE TABLE IF NOT EXISTS `api_tokens` (
  `token_id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_type` varchar(10) NOT NULL,              -- 'user' | 'admin'
  `owner_id` int(11) NOT NULL,
  `token_hash` char(64) NOT NULL,                 -- sha256 of the token; the raw token is never stored
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `owner` (`owner_type`, `owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. One-time login codes sent to a phone (OTP)
CREATE TABLE IF NOT EXISTS `otp_codes` (
  `otp_id` int(11) NOT NULL AUTO_INCREMENT,
  `phone` varchar(20) NOT NULL,
  `code_hash` varchar(255) NOT NULL,              -- password_hash() of the 4-digit code
  `attempts` int(11) NOT NULL DEFAULT 0,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`otp_id`),
  KEY `phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 3. Shipping / delivery requests for an approved claim
CREATE TABLE IF NOT EXISTS `shipping_requests` (
  `shipping_id` int(11) NOT NULL AUTO_INCREMENT,
  `claim_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `city` varchar(100) NOT NULL,
  `address` text NOT NULL,
  `phone` varchar(20) NOT NULL,
  `notes` text DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending', -- pending | approved | shipped | delivered | rejected
  `carrier` varchar(60) DEFAULT NULL,
  `tracking_number` varchar(80) DEFAULT NULL,
  `admin_note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`shipping_id`),
  UNIQUE KEY `claim_id` (`claim_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `shipping_claim_fk` FOREIGN KEY (`claim_id`) REFERENCES `claims` (`claim_id`) ON DELETE CASCADE,
  CONSTRAINT `shipping_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 4. Cancelling a lost report (status becomes 'cancelled')
ALTER TABLE `lost_items`
  ADD COLUMN IF NOT EXISTS `cancel_reason` varchar(255) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `cancelled_at` datetime DEFAULT NULL;

-- 5. Found reports: where the item is now, and whether it is a sighting
--    report_kind: 'found' (finder has/handed it in) | 'sighting' (seen, left in place)
ALTER TABLE `found_items`
  ADD COLUMN IF NOT EXISTS `current_status` varchar(60) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `report_kind` varchar(20) NOT NULL DEFAULT 'found';

-- 6. Claimant's answer to the finder's security question (compared by the admin)
ALTER TABLE `claims`
  ADD COLUMN IF NOT EXISTS `security_answer` varchar(255) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `reject_reason` varchar(255) DEFAULT NULL;

-- 7. Security questions belong to a found item (item_type = 'found')
ALTER TABLE `security_questions`
  ADD KEY IF NOT EXISTS `item` (`item_type`, `item_id`);

-- 8. Emergency reports: who resolved it and when
ALTER TABLE `emergency_reports`
  ADD COLUMN IF NOT EXISTS `resolved_at` datetime DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `resolved_by` int(11) DEFAULT NULL;

-- 9. Bug fix from the original dump: lost_date / found_date had
--    "ON UPDATE current_timestamp()", so every status change (e.g. 'matched')
--    overwrote the reported date with today's date.
ALTER TABLE `lost_items`
  MODIFY `lost_date` timestamp NOT NULL DEFAULT current_timestamp();
ALTER TABLE `found_items`
  MODIFY `found_date` timestamp NOT NULL DEFAULT current_timestamp();

-- 10. system_stats keeps one snapshot row (stat_id = 1), refreshed by the admin stats endpoint
INSERT IGNORE INTO `system_stats` (`stat_id`, `total_lost`, `total_found`, `pending_reports`, `total_matches`)
VALUES (1, 0, 0, 0, 0);
