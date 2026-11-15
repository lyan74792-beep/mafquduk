<?php
/* process_otp.php — طلب رمز الدخول بالجوال والتحقق منه (للأفراد) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('login.php');
}

$action = isset($_POST['action']) ? (string)$_POST['action'] : '';

try {
    if ($action === 'request') {
        $phone = trim(isset($_POST['phone']) ? (string)$_POST['phone'] : '');
        $res   = account_otp_request($conn, $phone);
        $_SESSION['otp_phone'] = $phone;
        if (otp_dev_mode()) {
            flash_ok(msg('otp.dev_code', array('code' => $res['code'])));
        } else {
            flash_ok(msg('otp.sent'));
        }
        redirect('login.php');
    }

    if ($action === 'verify') {
        $phone = trim(isset($_POST['phone']) && $_POST['phone'] !== ''
            ? (string)$_POST['phone']
            : (isset($_SESSION['otp_phone']) ? (string)$_SESSION['otp_phone'] : ''));
        $code  = isset($_POST['code']) ? (string)$_POST['code'] : '';
        $user  = account_otp_verify($conn, $phone, $code);
        unset($_SESSION['otp_phone']);

        session_regenerate_id(true);
        $_SESSION['uid']  = (int)$user['user_id'];
        $_SESSION['role'] = 'user';
        $_SESSION['name'] = $user['full_name'];

        $next = isset($_SESSION['after_login']) ? $_SESSION['after_login'] : '';
        unset($_SESSION['after_login']);
        redirect(in_array($next, array('report_lost.php', 'report_found.php'), true) ? $next : 'user_dashboard.php');
    }

    redirect('login.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('login.php');
} catch (Exception $e) {
    error_log('otp error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('login.php');
}
