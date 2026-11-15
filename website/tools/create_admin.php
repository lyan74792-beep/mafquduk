<?php
/* ============================================================
   tools/create_admin.php — create (or re-activate) an administrator account
   from the command line. Needed once to get the FIRST admin: after that,
   admins approve new admin sign-ups from the dashboard or the app.

   Usage (from the website folder):
     C:\xampp\php\php.exe tools\create_admin.php "Full Name" admin@example.com "StrongPassword"

   Only works from the command line, never through the browser.
   ============================================================ */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

if ($argc !== 4) {
    fwrite(STDERR, "Usage: php tools/create_admin.php \"Full Name\" email password\n");
    exit(1);
}

define('DB_NO_AUTOCONNECT', true);
require __DIR__ . '/../db.php';
require __DIR__ . '/../lib/bootstrap.php';

list(, $name, $email, $password) = $argv;
$email = strtolower(trim($email));

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 8 || trim($name) === '') {
    fwrite(STDERR, "Invalid input: name required, valid email, password of at least 8 characters.\n");
    exit(1);
}

$conn = db_connect();
$hash = password_hash($password, PASSWORD_DEFAULT);
$existing = db_one($conn, 'SELECT admin_id FROM admins WHERE email = ?', 's', array($email));

if ($existing) {
    db_exec($conn, "UPDATE admins SET full_name = ?, password_hash = ?, role = 'admin' WHERE admin_id = ?",
        'ssi', array($name, $hash, (int)$existing['admin_id']));
    echo "Admin updated and activated: $email\n";
} else {
    db_exec($conn, "INSERT INTO admins (full_name, email, password_hash, role, created_at) VALUES (?, ?, ?, 'admin', NOW())",
        'sss', array($name, $email, $hash));
    echo "Admin created: $email\n";
}
