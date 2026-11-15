<?php
/* admin_accounts_action.php — الإدارة: قبول أو رفض حسابات المشرفين المعلقة عبر admin_approve_admin / admin_reject_admin */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php#panel-accounts');
}

$adminId = isset($_POST['admin_id']) ? (int)$_POST['admin_id'] : 0;
$action  = isset($_POST['action']) ? (string)$_POST['action'] : '';

try {
    if ($action === 'approve') {
        admin_approve_admin($conn, $adminId);
        flash_ok(msg('account.admin_approved_ok'));
    } else {
        admin_reject_admin($conn, $adminId);
        flash_ok(msg('account.admin_rejected_ok'));
    }
    redirect('admin_dashboard.php#panel-accounts');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php#panel-accounts');
} catch (Exception $e) {
    error_log('admin accounts action: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php#panel-accounts');
}
