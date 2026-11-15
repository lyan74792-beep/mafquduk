<?php
/* process_shipping.php — إنشاء طلب شحن جديد عبر shipping_create */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('shipping_request.php');
}

$uid     = (int)$_SESSION['uid'];
$claimId = isset($_POST['claim_id']) ? (int)$_POST['claim_id'] : 0;
$back    = 'shipping_request.php' . ($claimId > 0 ? '?claim_id=' . $claimId : '');

try {
    $res = shipping_create($conn, $uid, $_POST);
    flash_ok(msg('shipping.created_ok', array('id' => $res['shipping_id'])));
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect($back);
} catch (Exception $e) {
    error_log('shipping create error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect($back);
}
