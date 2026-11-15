<?php
/* track_status.php — حالة البلاغ عبر report_track (يبحث برقم بلاغ المفقود فقط، ولا يعيد بيانات شخصية) */
header('Content-Type: application/json; charset=utf-8');
define('DB_NO_AUTOCONNECT', true);
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

$q = isset($_GET['query']) ? ltrim(trim($_GET['query']), '#') : '';
if ($q === '' || !ctype_digit($q) || strlen($q) > 10) {
    echo json_encode(array('success' => false, 'message' => 'not_found'));
    exit;
}

try {
    $conn   = db_connect();
    $r      = report_track($conn, (int)$q);
    $valid  = array('received', 'searching', 'matched', 'ready', 'delivered', 'cancelled');
    $status = in_array($r['status'], $valid, true) ? $r['status'] : 'searching';

    echo json_encode(array(
        'success' => true,
        'report'  => array(
            'report_id'     => (string)$r['id'],
            'item_category' => $r['category'],
            'status'        => $status,
            'status_label'  => $r['status_label'],
            'created_at'    => substr((string)$r['created_at'], 0, 10),
        ),
    ), JSON_UNESCAPED_UNICODE);
} catch (NotFoundError $e) {
    echo json_encode(array('success' => false, 'message' => 'not_found'));
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(array('success' => false, 'message' => 'server_error'));
}
