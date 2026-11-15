<?php
/* delivery_action.php — الإدارة: تسجيل تسليم الغرض لصاحبه عبر claim_deliver */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php');
}

$cid = isset($_POST['claim_id']) ? (int)$_POST['claim_id'] : 0;

try {
    claim_deliver($conn, $cid);
    flash_ok(msg('claim.delivered_ok'));
    redirect('admin_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php');
} catch (Exception $e) {
    error_log('delivery: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php');
}
