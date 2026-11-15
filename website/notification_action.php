<?php
/* notification_action.php — تعليم إشعار واحد (notification_mark_read) أو الكل (notification_mark_all_read) كمقروء */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('notifications.php');
}

$uid    = (int)$_SESSION['uid'];
$action = isset($_POST['action']) ? trim((string)$_POST['action']) : '';
$nid    = isset($_POST['notification_id']) ? (int)$_POST['notification_id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);

try {
    if ($action === 'mark_all_read' || $action === 'mark_all' || $action === 'all') {
        notification_mark_all_read($conn, $uid);
        flash_ok(msg('notification.marked_all_read'));
    } elseif ($nid > 0) {
        notification_mark_read($conn, $uid, $nid);
        flash_ok(msg('notification.marked_read'));
    }
    redirect('notifications.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('notifications.php');
} catch (Exception $e) {
    error_log('notification action error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('notifications.php');
}
