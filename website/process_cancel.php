<?php
/* process_cancel.php — إلغاء بلاغ مفقود عبر report_cancel_lost */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('user_dashboard.php');
}

$uid     = (int)$_SESSION['uid'];
$lostId  = isset($_POST['lost_item_id']) ? (int)$_POST['lost_item_id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);
$reason  = isset($_POST['reason']) ? (string)$_POST['reason'] : '';
$details = isset($_POST['details']) ? (string)$_POST['details'] : '';

try {
    report_cancel_lost($conn, $uid, $lostId, $reason, $details);
    flash_ok(msg('report.cancelled_ok', array('id' => $lostId)));
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('user_dashboard.php');
} catch (Exception $e) {
    error_log('cancel report error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('user_dashboard.php');
}
