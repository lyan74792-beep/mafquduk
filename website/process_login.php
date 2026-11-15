<?php
/* process_login.php — تسجيل الدخول عبر account_login */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('login.php');
}

$type  = (isset($_POST['account_type']) && $_POST['account_type'] === 'admin') ? 'admin' : 'user';
$back  = 'login.php' . ($type === 'admin' ? '?role=admin' : '');
$email = isset($_POST['email']) ? (string)$_POST['email'] : '';
$pass  = isset($_POST['password']) ? (string)$_POST['password'] : '';

try {
    $res = account_login($conn, $email, $pass, $type);

    session_regenerate_id(true);
    if ($res['role'] === 'admin') {
        $_SESSION['uid']  = (int)$res['admin']['admin_id'];
        $_SESSION['role'] = 'admin';
        $_SESSION['name'] = $res['admin']['full_name'];
        redirect('admin_dashboard.php');
    }

    $_SESSION['uid']  = (int)$res['user']['user_id'];
    $_SESSION['role'] = 'user';
    $_SESSION['name'] = $res['user']['full_name'];

    $next = isset($_SESSION['after_login']) ? $_SESSION['after_login'] : '';
    unset($_SESSION['after_login']);
    redirect(in_array($next, array('report_lost.php', 'report_found.php'), true) ? $next : 'user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect($back);
} catch (Exception $e) {
    error_log('login error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect($back);
}
