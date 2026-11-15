<?php
/* process_profile.php — معالجة تحديث الملف الشخصي (account_update_profile) وتغيير كلمة المرور (account_change_password) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('profile.php');
}

$uid    = (int)$_SESSION['uid'];
$action = isset($_POST['action']) ? trim((string)$_POST['action']) : 'update_profile';

try {
    if ($action === 'change_password' || isset($_POST['current_password'], $_POST['new_password'])) {
        $current = isset($_POST['current_password']) ? (string)$_POST['current_password'] : '';
        $newPass = isset($_POST['new_password']) ? (string)$_POST['new_password'] : '';
        if (isset($_POST['confirm_password']) && (string)$_POST['confirm_password'] !== $newPass) {
            throw new UserError(msg('account.password_mismatch'));
        }
        account_change_password($conn, $uid, $current, $newPass);
        flash_ok(msg('account.password_changed'));
    } else {
        $updated = account_update_profile($conn, $uid, $_POST);
        $_SESSION['name'] = $updated['full_name'];
        flash_ok(msg('account.profile_updated'));
    }
    redirect('profile.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('profile.php');
} catch (Exception $e) {
    error_log('profile action error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('profile.php');
}
