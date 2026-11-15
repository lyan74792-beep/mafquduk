<?php
/* resolve_emergency.php — تحديث حالة البلاغ الطارئ عبر admin_resolve_emergency */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php');
}

$emId    = isset($_POST['emergency_id']) ? (int)$_POST['emergency_id'] : 0;
$adminId = (int)$_SESSION['uid'];

try {
    admin_resolve_emergency($conn, $adminId, $emId);
    flash_ok(msg('report.emergency_resolved_ok', array('id' => $emId)));
    redirect('admin_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php');
} catch (Exception $e) {
    error_log('resolve emergency: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php');
}
