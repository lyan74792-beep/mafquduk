<?php
/* ============================================================
   lib/services/shipping_service.php — shipping requests for
   approved claims (user creation/listing and admin management).
   ============================================================ */

function shipping_present_row(array $r)
{
    return array(
        'shipping_id'     => (int)$r['shipping_id'],
        'claim_id'        => (int)$r['claim_id'],
        'item_name'       => $r['item_name'],
        'city'            => $r['city'],
        'address'         => $r['address'],
        'phone'           => $r['phone'],
        'notes'           => $r['notes'],
        'status'          => $r['status'],
        'status_label'    => status_label($r['status']),
        'carrier'         => $r['carrier'],
        'tracking_number' => $r['tracking_number'],
        'admin_note'      => $r['admin_note'],
        'created_at'      => $r['created_at'],
    );
}

function shipping_create($conn, $userId, array $in)
{
    $uid     = (int)$userId;
    $claimId = isset($in['claim_id']) ? (int)$in['claim_id'] : 0;
    $city    = trim(isset($in['city']) ? (string)$in['city'] : '');
    $address = trim(isset($in['address']) ? (string)$in['address'] : '');
    $phone   = trim(isset($in['phone']) ? (string)$in['phone'] : '');
    $notes   = trim(isset($in['notes']) ? (string)$in['notes'] : '');

    $claim = db_one(
        $conn,
        'SELECT claim_id, status FROM claims WHERE claim_id = ? AND user_id = ?',
        'ii',
        array($claimId, $uid)
    );
    if (!$claim) {
        throw new NotFoundError(msg('claim.not_found'));
    }
    if ($claim['status'] !== 'Approved') {
        throw new ConflictError(msg('shipping.claim_not_approved'));
    }

    $existing = db_one(
        $conn,
        'SELECT shipping_id FROM shipping_requests WHERE claim_id = ?',
        'i',
        array($claimId)
    );
    if ($existing) {
        throw new ConflictError(msg('shipping.already_exists'));
    }

    $fields = array();
    if ($city === '' || mb_strlen($city) > 100) {
        $fields['city'] = msg('shipping.city_required');
    }
    if ($address === '') {
        $fields['address'] = msg('shipping.address_required');
    }
    if (!preg_match(PHONE_PATTERN, $phone)) {
        $fields['phone'] = msg('account.phone_invalid');
    }
    if ($fields) {
        throw new UserError(implode(' ', $fields), $fields);
    }

    $notesOrNull = $notes !== '' ? $notes : null;

    $shippingId = db_exec(
        $conn,
        "INSERT INTO shipping_requests (claim_id, user_id, city, address, phone, notes, status, created_at)
         VALUES (?, ?, ?, ?, ?, ?, 'pending', NOW())",
        'iissss',
        array($claimId, $uid, $city, $address, $phone, $notesOrNull)
    );

    return array('shipping_id' => (int)$shippingId);
}

function shipping_list_for_user($conn, $userId)
{
    $rows = db_all(
        $conn,
        'SELECT s.shipping_id, s.claim_id, f.item_name, s.city, s.address, s.phone, s.notes,
                s.status, s.carrier, s.tracking_number, s.admin_note, s.created_at
         FROM shipping_requests s
         JOIN claims cl ON cl.claim_id = s.claim_id
         JOIN found_items f ON f.found_item_id = cl.found_item_id
         WHERE s.user_id = ?
         ORDER BY s.created_at DESC, s.shipping_id DESC',
        'i',
        array((int)$userId)
    );

    return array('requests' => array_map('shipping_present_row', $rows));
}

function shipping_list_all($conn, $status = '')
{
    $status = trim((string)$status);
    $sql = 'SELECT s.shipping_id, s.claim_id, f.item_name, s.city, s.address, s.phone, s.notes,
                   s.status, s.carrier, s.tracking_number, s.admin_note, s.created_at,
                   u.full_name AS user_full_name, u.phone AS user_phone
            FROM shipping_requests s
            JOIN claims cl ON cl.claim_id = s.claim_id
            JOIN found_items f ON f.found_item_id = cl.found_item_id
            JOIN users u ON u.user_id = s.user_id';

    $types  = '';
    $params = array();
    if ($status !== '' && $status !== 'all') {
        $sql     .= ' WHERE s.status = ?';
        $types   .= 's';
        $params[] = $status;
    }
    $sql .= ' ORDER BY s.created_at DESC, s.shipping_id DESC';

    $rows = db_all($conn, $sql, $types, $params);
    $out  = array();
    foreach ($rows as $r) {
        $item = shipping_present_row($r);
        $item['user'] = array(
            'full_name' => $r['user_full_name'],
            'phone'     => $r['user_phone'],
        );
        $out[] = $item;
    }

    return array('requests' => $out);
}

function shipping_update($conn, $shippingId, array $in)
{
    $sid     = (int)$shippingId;
    $status  = trim(isset($in['status']) ? (string)$in['status'] : '');
    $allowed = array('pending', 'approved', 'shipped', 'delivered', 'rejected');

    if (!in_array($status, $allowed, true)) {
        throw new UserError(msg('shipping.status_invalid'), array('status' => msg('shipping.status_invalid_short')));
    }

    $row = db_one(
        $conn,
        'SELECT shipping_id, user_id FROM shipping_requests WHERE shipping_id = ?',
        'i',
        array($sid)
    );
    if (!$row) {
        throw new NotFoundError(msg('shipping.not_found'));
    }

    $carrier   = isset($in['carrier']) ? trim((string)$in['carrier']) : '';
    $tracking  = isset($in['tracking_number']) ? trim((string)$in['tracking_number']) : '';
    $adminNote = isset($in['admin_note']) ? trim((string)$in['admin_note']) : '';

    $carrierOrNull  = $carrier !== '' ? mb_substr($carrier, 0, 60) : null;
    $trackingOrNull = $tracking !== '' ? mb_substr($tracking, 0, 80) : null;
    $noteOrNull     = $adminNote !== '' ? mb_substr($adminNote, 0, 255) : null;

    db_exec(
        $conn,
        'UPDATE shipping_requests
         SET status = ?, carrier = ?, tracking_number = ?, admin_note = ?, updated_at = NOW()
         WHERE shipping_id = ?',
        'ssssi',
        array($status, $carrierOrNull, $trackingOrNull, $noteOrNull, $sid)
    );

    $label = status_label($status);
    $body  = msg('shipping.notify_status', array('id' => $sid, 'status' => $label));
    if ($carrierOrNull !== null && $trackingOrNull !== null) {
        $body .= ' ' . msg('shipping.notify_carrier_tracking', array('carrier' => $carrierOrNull, 'tracking' => $trackingOrNull));
    } elseif ($trackingOrNull !== null) {
        $body .= ' ' . msg('shipping.notify_tracking', array('tracking' => $trackingOrNull));
    }
    notify($conn, (int)$row['user_id'], msg('shipping.notify_title'), $body, 'shipping');
}
