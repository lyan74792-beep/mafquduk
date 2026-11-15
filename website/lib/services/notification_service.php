<?php
/* ============================================================
   lib/services/notification_service.php — user notifications.
   ============================================================ */

function notification_list($conn, $userId)
{
    $uid = (int)$userId;

    $cntRow = db_one(
        $conn,
        'SELECT COUNT(*) AS cnt FROM notifications WHERE user_id = ? AND is_read = 0',
        'i',
        array($uid)
    );
    $unreadCount = $cntRow ? (int)$cntRow['cnt'] : 0;

    $rows = db_all(
        $conn,
        'SELECT notification_id, title, message, notification_type, is_read, created_at
         FROM notifications
         WHERE user_id = ?
         ORDER BY created_at DESC, notification_id DESC
         LIMIT 100',
        'i',
        array($uid)
    );

    $notifications = array();
    foreach ($rows as $r) {
        $notifications[] = array(
            'notification_id'   => (int)$r['notification_id'],
            'title'             => $r['title'],
            'message'           => $r['message'],
            'notification_type' => $r['notification_type'],
            'is_read'           => (bool)$r['is_read'],
            'created_at'        => $r['created_at'],
        );
    }

    return array(
        'unread_count'  => $unreadCount,
        'notifications' => $notifications,
    );
}

function notification_mark_read($conn, $userId, $id)
{
    $uid = (int)$userId;
    $nid = (int)$id;

    $row = db_one(
        $conn,
        'SELECT notification_id FROM notifications WHERE notification_id = ? AND user_id = ?',
        'ii',
        array($nid, $uid)
    );
    if (!$row) {
        throw new NotFoundError(msg('notification.not_found'));
    }

    db_exec(
        $conn,
        'UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND user_id = ?',
        'ii',
        array($nid, $uid)
    );
}

function notification_mark_all_read($conn, $userId)
{
    db_exec(
        $conn,
        'UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0',
        'i',
        array((int)$userId)
    );
}
