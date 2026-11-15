<?php
/* process_found.php — حفظ بلاغ معثور أو مشاهدة عبر report_create_found */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('report_found.php');
}

$back = (isset($_POST['report_kind']) && $_POST['report_kind'] === 'sighting')
    ? 'report_found.php?kind=sighting'
    : 'report_found.php';

try {
    $r = report_create_found($conn, (int)$_SESSION['uid'], $_POST, 'item_image');
    flash_ok(msg('report.found_created', array('id' => $r['id'])));
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect($back);
} catch (Exception $e) {
    error_log('found report error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect($back);
}
