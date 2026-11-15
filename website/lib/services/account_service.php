<?php
/* ============================================================
   lib/services/account_service.php — accounts: register, login, OTP,
   profile, password. Used by the website (process_*.php) and the API.

   Conventions for every service file:
   - functions take $conn first, plain values/arrays after, return arrays;
   - no $_POST / $_SESSION / echo / redirect in here;
   - throw UserError (or a subclass from lib/errors.php) with an Arabic message.
   ============================================================ */

define('OTP_TTL_SECONDS', 300);
define('OTP_MAX_ATTEMPTS', 5);
define('PHONE_PATTERN', '/^05[0-9]{8}$/');

/* ---------- reading accounts ---------- */

function account_user($conn, $userId)
{
    $u = db_one($conn, 'SELECT user_id, full_name, email, phone, nationality, account_status, created_at
                        FROM users WHERE user_id = ?', 'i', array($userId));
    if (!$u) {
        throw new NotFoundError(msg('account.not_found'));
    }
    $u['user_id'] = (int)$u['user_id'];
    return $u;
}

function account_admin($conn, $adminId)
{
    $a = db_one($conn, 'SELECT admin_id, full_name, email, role, created_at FROM admins WHERE admin_id = ?', 'i', array($adminId));
    if (!$a) {
        throw new NotFoundError(msg('account.not_found'));
    }
    $a['admin_id'] = (int)$a['admin_id'];
    return $a;
}

/* ---------- registration ---------- */

/** Validate name/email/password fields shared by user and admin sign-up. */
function account_validate_signup(array $in)
{
    $name = trim(isset($in['full_name']) ? $in['full_name'] : '');
    $email = strtolower(trim(isset($in['email']) ? $in['email'] : ''));
    $pass = isset($in['password']) ? (string)$in['password'] : '';
    $confirm = isset($in['confirm_password']) ? (string)$in['confirm_password'] : '';

    $fields = array();
    if ($name === '' || mb_strlen($name) > 100) {
        $fields['full_name'] = msg('account.name_invalid');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 100) {
        $fields['email'] = msg('account.email_invalid');
    }
    if (strlen($pass) < 8) {
        $fields['password'] = msg('account.password_short');
    } elseif ($pass !== $confirm) {
        $fields['confirm_password'] = msg('account.password_mismatch');
    }
    if ($fields) {
        throw new UserError(implode(' ', $fields), $fields);
    }
    return array($name, $email, $pass);
}

/** Create a user account. Returns the user. */
function account_register_user($conn, array $in)
{
    list($name, $email, $pass) = account_validate_signup($in);
    if (db_one($conn, 'SELECT user_id FROM users WHERE email = ?', 's', array($email))) {
        throw new ConflictError(msg('account.email_taken'), array('email' => msg('account.already_registered')));
    }
    $hash = password_hash($pass, PASSWORD_DEFAULT);
    $id = db_exec($conn, "INSERT INTO users (full_name, phone, email, password_hash, nationality, account_status, created_at)
                          VALUES (?, NULL, ?, ?, '', 'active', NOW())", 'sss', array($name, $email, $hash));
    return account_user($conn, $id);
}

/** Create an admin account in 'pending' state (an existing admin approves it). */
function account_register_admin($conn, array $in)
{
    list($name, $email, $pass) = account_validate_signup($in);
    if (db_one($conn, 'SELECT admin_id FROM admins WHERE email = ?', 's', array($email))) {
        throw new ConflictError(msg('account.email_taken'), array('email' => msg('account.already_registered')));
    }
    $hash = password_hash($pass, PASSWORD_DEFAULT);
    db_exec($conn, "INSERT INTO admins (full_name, email, password_hash, role, created_at) VALUES (?, ?, ?, 'pending', NOW())",
        'sss', array($name, $email, $hash));
    return array('message' => msg('account.admin_pending_created'));
}

/* ---------- login ---------- */

/**
 * Check email + password. $type: 'user' | 'admin'.
 * Returns array('role' => 'user', 'user' => [...]) or array('role' => 'admin', 'admin' => [...]).
 */
function account_login($conn, $email, $password, $type)
{
    $email = strtolower(trim($email));
    if ($email === '' || $password === '') {
        throw new UserError(msg('account.login_missing'));
    }

    if ($type === 'admin') {
        $row = db_one($conn, 'SELECT admin_id, password_hash, role FROM admins WHERE email = ?', 's', array($email));
        if (!$row || !password_verify($password, $row['password_hash'])) {
            throw new AuthError(msg('account.invalid_credentials'));
        }
        if ($row['role'] === 'pending') {
            throw new ForbiddenError(msg('account.admin_pending'));
        }
        return array('role' => 'admin', 'admin' => account_admin($conn, (int)$row['admin_id']));
    }

    $row = db_one($conn, 'SELECT user_id, password_hash, account_status FROM users WHERE email = ?', 's', array($email));
    if (!$row || !password_verify($password, $row['password_hash'])) {
        throw new AuthError(msg('account.invalid_credentials'));
    }
    account_assert_active($row['account_status']);
    return array('role' => 'user', 'user' => account_user($conn, (int)$row['user_id']));
}

function account_assert_active($status)
{
    if (in_array(strtolower((string)$status), array('blocked', 'suspended', 'banned', 'inactive'), true)) {
        throw new ForbiddenError(msg('account.suspended'));
    }
}

/* ---------- phone OTP login ---------- */

/** Is OTP running without a real SMS provider? (code is shown to the user) */
function otp_dev_mode()
{
    return !defined('SMS_PROVIDER_ENABLED') || !SMS_PROVIDER_ENABLED;
}

/**
 * Hook for a real SMS provider (Unifonic, Twilio, …). Without one, the code
 * is only logged and returned in dev mode.
 */
function sms_send($phone, $message)
{
    error_log('[SMS dev] to ' . $phone . ': ' . $message);
    return true;
}

/** Create and "send" a 4-digit code. Returns array('expires_in' => s, 'code' => raw code). */
function account_otp_request($conn, $phone)
{
    $phone = trim($phone);
    if (!preg_match(PHONE_PATTERN, $phone)) {
        throw new UserError(msg('account.phone_invalid'), array('phone' => msg('account.phone_invalid')));
    }
    if (!db_one($conn, 'SELECT user_id FROM users WHERE phone = ?', 's', array($phone))) {
        throw new NotFoundError(msg('otp.no_account'));
    }
    // one live code per phone
    db_exec($conn, 'UPDATE otp_codes SET used_at = NOW() WHERE phone = ? AND used_at IS NULL', 's', array($phone));

    $code = (string)random_int(1000, 9999);
    // expiry computed by the database, so PHP and MySQL clocks can't disagree
    db_exec($conn, 'INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))',
        'ssi', array($phone, password_hash($code, PASSWORD_DEFAULT), OTP_TTL_SECONDS));
    sms_send($phone, msg('otp.sms_text', array('code' => $code)));
    return array('expires_in' => OTP_TTL_SECONDS, 'code' => $code);
}

/** Check a code; on success returns the user. */
function account_otp_verify($conn, $phone, $code)
{
    $phone = trim($phone);
    $otp = db_one($conn, 'SELECT otp_id, code_hash, attempts FROM otp_codes
                          WHERE phone = ? AND used_at IS NULL AND expires_at > NOW()
                          ORDER BY otp_id DESC LIMIT 1', 's', array($phone));
    if (!$otp) {
        throw new AuthError(msg('otp.expired'));
    }
    if ((int)$otp['attempts'] >= OTP_MAX_ATTEMPTS) {
        db_exec($conn, 'UPDATE otp_codes SET used_at = NOW() WHERE otp_id = ?', 'i', array($otp['otp_id']));
        throw new AuthError(msg('otp.too_many'));
    }
    if (!password_verify(trim($code), $otp['code_hash'])) {
        db_exec($conn, 'UPDATE otp_codes SET attempts = attempts + 1 WHERE otp_id = ?', 'i', array($otp['otp_id']));
        throw new AuthError(msg('otp.wrong'));
    }
    db_exec($conn, 'UPDATE otp_codes SET used_at = NOW() WHERE otp_id = ?', 'i', array($otp['otp_id']));

    $row = db_one($conn, 'SELECT user_id, account_status FROM users WHERE phone = ?', 's', array($phone));
    if (!$row) {
        throw new NotFoundError(msg('otp.no_account'));
    }
    account_assert_active($row['account_status']);
    return account_user($conn, (int)$row['user_id']);
}

/* ---------- profile ---------- */

function account_update_profile($conn, $userId, array $in)
{
    $name = trim(isset($in['full_name']) ? $in['full_name'] : '');
    $phone = trim(isset($in['phone']) ? $in['phone'] : '');
    $nat = trim(isset($in['nationality']) ? $in['nationality'] : '');

    $fields = array();
    if ($name === '' || mb_strlen($name) > 100) {
        $fields['full_name'] = msg('account.name_invalid');
    }
    if ($phone !== '' && !preg_match(PHONE_PATTERN, $phone)) {
        $fields['phone'] = msg('account.phone_invalid');
    }
    if (mb_strlen($nat) > 50) {
        $fields['nationality'] = msg('account.nationality_long');
    }
    if ($fields) {
        throw new UserError(implode(' ', $fields), $fields);
    }
    if ($phone !== '' && db_one($conn, 'SELECT user_id FROM users WHERE phone = ? AND user_id <> ?', 'si', array($phone, $userId))) {
        throw new ConflictError(msg('account.phone_taken'), array('phone' => msg('account.phone_taken')));
    }
    $phoneOrNull = $phone === '' ? null : $phone;
    db_exec($conn, 'UPDATE users SET full_name = ?, phone = ?, nationality = ? WHERE user_id = ?',
        'sssi', array($name, $phoneOrNull, $nat, $userId));
    return account_user($conn, $userId);
}

function account_change_password($conn, $userId, $current, $new)
{
    $row = db_one($conn, 'SELECT password_hash FROM users WHERE user_id = ?', 'i', array($userId));
    if (!$row || !password_verify((string)$current, $row['password_hash'])) {
        throw new AuthError(msg('account.current_password_wrong'));
    }
    if (strlen((string)$new) < 8) {
        throw new UserError(msg('account.password_short'), array('new_password' => msg('account.password_short')));
    }
    db_exec($conn, 'UPDATE users SET password_hash = ? WHERE user_id = ?', 'si',
        array(password_hash((string)$new, PASSWORD_DEFAULT), $userId));
}

/** Save the reporter's phone on their account if they have none yet (forms ask for it). */
function account_remember_phone($conn, $userId, $phone)
{
    if ($userId === null || !preg_match(PHONE_PATTERN, $phone)) {
        return;
    }
    $taken = db_one($conn, 'SELECT user_id FROM users WHERE phone = ? AND user_id <> ?', 'si', array($phone, $userId));
    if (!$taken) {
        db_exec($conn, 'UPDATE users SET phone = ? WHERE user_id = ?', 'si', array($phone, $userId));
    }
}
