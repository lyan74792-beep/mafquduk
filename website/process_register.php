<?php
/* process_register.php — إنشاء حساب عبر account_service (الأفراد والإدارة) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('register.php');
}

$type = (isset($_POST['account_type']) && $_POST['account_type'] === 'admin') ? 'admin' : 'user';
$back = ($type === 'admin') ? 'register_admin.php' : 'register.php';

try {
    if (empty($_POST['accept_terms'])) {
        throw new UserError(msg('account.terms_required'));
    }

    if ($type === 'admin') {
        $res = account_register_admin($conn, $_POST);
        flash_ok($res['message']);
        redirect('login.php?role=admin');
    }

    $user = account_register_user($conn, $_POST);

    session_regenerate_id(true);
    $_SESSION['uid']  = (int)$user['user_id'];
    $_SESSION['role'] = 'user';
    $_SESSION['name'] = $user['full_name'];

    $next = isset($_SESSION['after_login']) ? $_SESSION['after_login'] : '';
    unset($_SESSION['after_login']);
    redirect(in_array($next, array('report_lost.php', 'report_found.php'), true) ? $next : 'user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect($back);
} catch (Exception $e) {
    error_log('register error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect($back);
}
