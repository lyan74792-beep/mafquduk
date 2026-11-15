<?php
/* process_emergency.php — حفظ بلاغ طارئ عبر report_create_emergency (يسمح للزوار والمسجلين) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('report_emergency.php');
}

$uid = is_logged_in() ? (int)$_SESSION['uid'] : null;

try {
    $r = report_create_emergency($conn, $uid, $_POST, 'item_image');
    flash_ok(msg('report.emergency_created', array('id' => $r['id'])));
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('report_emergency.php');
} catch (Exception $e) {
    error_log('emergency report error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('report_emergency.php');
}
