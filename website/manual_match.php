<?php
/* manual_match.php — الإدارة: ربط يدوي بين مفقود ومعثور عبر admin_manual_match */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php');
}

$lid = isset($_POST['lost_id']) ? (int)$_POST['lost_id'] : 0;
$fid = isset($_POST['found_id']) ? (int)$_POST['found_id'] : 0;

try {
    admin_manual_match($conn, $lid, $fid);
    flash_ok(msg('match.manual_created'));
    redirect('admin_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php');
} catch (Exception $e) {
    error_log('manual match: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php');
}
