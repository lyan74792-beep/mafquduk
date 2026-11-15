<?php
/* process_lost.php — حفظ بلاغ مفقود عبر report_create_lost */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('report_lost.php');
}

try {
    $r = report_create_lost($conn, (int)$_SESSION['uid'], $_POST, 'item_image');
    flash_ok(msg('report.lost_created', array('id' => $r['id'])));
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('report_lost.php');
} catch (Exception $e) {
    error_log('lost report error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('report_lost.php');
}
