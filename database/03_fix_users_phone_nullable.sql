-- process_register.php creates users without a phone (phone is added later,
-- e.g. from the emergency form), but the dump declared users.phone NOT NULL,
-- so every registration failed with "Column 'phone' cannot be null".
-- The UNIQUE key stays: MariaDB allows many NULLs in a unique column.

ALTER TABLE `users` MODIFY `phone` varchar(20) DEFAULT NULL;
