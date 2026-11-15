<?php
/* ============================================================
   api/routes/notifications.php — user notifications.
   ============================================================ */

route('GET', '/notifications', 'api_notifications_list', 'user');
route('POST', '/notifications/read-all', 'api_notifications_read_all', 'user');
route('POST', '/notifications/{id}/read', 'api_notification_read', 'user');

function api_notifications_list($params, $actor)
{
    global $conn;
    api_ok(notification_list($conn, $actor['id']));
}

function api_notification_read($params, $actor)
{
    global $conn;
    notification_mark_read($conn, $actor['id'], (int)$params['id']);
    api_ok();
}

function api_notifications_read_all($params, $actor)
{
    global $conn;
    notification_mark_all_read($conn, $actor['id']);
    api_ok();
}
