<?php
/* admin_shipping_action.php — الإدارة: تحديث حالة طلب الشحن وبيانات التتبع عبر shipping_update */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('admin_dashboard.php#panel-shipping');
}

$shippingId = isset($_POST['shipping_id']) ? (int)$_POST['shipping_id'] : 0;
$in         = array(
    'status'          => isset($_POST['status']) ? (string)$_POST['status'] : '',
    'carrier'         => isset($_POST['carrier']) ? (string)$_POST['carrier'] : '',
    'tracking_number' => isset($_POST['tracking_number']) ? (string)$_POST['tracking_number'] : '',
    'admin_note'      => isset($_POST['admin_note']) ? (string)$_POST['admin_note'] : '',
);

try {
    shipping_update($conn, $shippingId, $in);
    flash_ok(msg('shipping.updated_ok', array('id' => $shippingId)));
    redirect('admin_dashboard.php#panel-shipping');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('admin_dashboard.php#panel-shipping');
} catch (Exception $e) {
    error_log('admin shipping update: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('admin_dashboard.php#panel-shipping');
}
