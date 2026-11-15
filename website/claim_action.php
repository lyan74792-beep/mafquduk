<?php
/* claim_action.php — الإدارة: قبول أو رفض طلب الاسترداد عبر claim_approve / claim_reject */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php');
}

$cid    = isset($_POST['claim_id']) ? (int)$_POST['claim_id'] : 0;
$act    = isset($_POST['action']) ? (string)$_POST['action'] : '';
$reason = isset($_POST['reject_reason']) ? (string)$_POST['reject_reason'] : '';

try {
    if ($act === 'approve') {
        claim_approve($conn, $cid);
        flash_ok(msg('claim.approved_ok'));
    } else {
        claim_reject($conn, $cid, $reason);
        flash(msg('claim.rejected_ok'));
    }
    redirect('admin_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php');
} catch (Exception $e) {
    error_log('claim action: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php');
}
