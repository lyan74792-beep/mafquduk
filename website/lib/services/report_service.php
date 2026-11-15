<?php
/* ============================================================
   lib/services/report_service.php — creating, listing, tracking,
   and cancelling lost/found/emergency reports.
   ============================================================ */

/**
 * Shared validation for lost and found item reports.
 * $prefix: 'lost' | 'found'.  Returns array($baseData, $fields).
 */
function report_validate_item(array $in, $prefix, $phoneField)
{
    $phone        = trim(isset($in[$phoneField]) ? (string)$in[$phoneField] : '');
    $categoryName = trim(isset($in['item_category']) ? (string)$in['item_category'] : '');
    $locKey       = $prefix . '_location';
    $dateKey      = $prefix . '_date';
    $locSel       = trim(isset($in[$locKey]) ? (string)$in[$locKey] : '');
    $locOther     = trim(isset($in[$locKey . '_other']) ? (string)$in[$locKey . '_other'] : '');
    $lat          = isset($in[$prefix . '_lat']) ? $in[$prefix . '_lat'] : '';
    $lng          = isset($in[$prefix . '_lng']) ? $in[$prefix . '_lng'] : '';
    $dateStr      = trim(isset($in[$dateKey]) ? (string)$in[$dateKey] : '');
    $desc         = trim(isset($in['item_description']) ? (string)$in['item_description'] : '');

    $fields = array();
    if (!preg_match(PHONE_PATTERN, $phone)) {
        $fields[$phoneField] = msg('account.phone_invalid');
    }
    if ($categoryName === '') {
        $fields['item_category'] = msg('report.category_required');
    }
    if ($locSel === '' || ($locSel === lookup_other() && $locOther === '')) {
        $fields[$locKey] = msg('report.location_required');
    }
    $d = DateTime::createFromFormat('Y-m-d', $dateStr);
    if (!$d || $d->format('Y-m-d') !== $dateStr || $d > new DateTime('today 23:59:59')) {
        $fields[$dateKey] = msg($prefix === 'lost' ? 'report.lost_date_invalid' : 'report.found_date_invalid');
    }
    if ($desc === '') {
        $fields['item_description'] = msg('report.description_required');
    }

    $base = array(
        'phone'     => $phone,
        'category'  => $categoryName,
        'loc_sel'   => $locSel,
        'loc_other' => $locOther,
        'lat'       => $lat,
        'lng'       => $lng,
        'date_db'   => $dateStr . ' 00:00:00',
        'item_name' => mb_substr($desc, 0, 60),
        'desc_db'   => mb_substr($desc, 0, 250),
    );
    return array($base, $fields);
}

/**
 * Shared transaction flow for saving a lost or found item report:
 * begin transaction -> remember phone -> resolve category/location -> insert -> save image -> match -> commit.
 */
function report_save_item($conn, $userId, $kind, array $base, $imageField, callable $insertFn)
{
    $uid       = (int)$userId;
    $savedFile = '';
    try {
        $conn->begin_transaction();

        account_remember_phone($conn, $uid, $base['phone']);
        $categoryId = find_or_create_category($conn, $base['category']);
        $locationId = resolve_location($conn, $base['loc_sel'], $base['loc_other'], $base['lat'], $base['lng']);

        $itemId    = (int)$insertFn($conn, $uid, $categoryId, $locationId, $base);
        $savedFile = save_item_image($conn, $kind, $itemId, $imageField);
        $matches   = $kind === 'lost'
            ? run_matching_for_lost($conn, $itemId)
            : run_matching_for_found($conn, $itemId);

        $conn->commit();
        return array('id' => $itemId, 'matches_found' => (int)$matches);
    } catch (Exception $ex) {
        $conn->rollback();
        if ($savedFile !== '' && is_file($savedFile)) {
            unlink($savedFile);
        }
        throw $ex;
    }
}

function report_create_lost($conn, $userId, array $in, $imageField = 'item_image')
{
    list($base, $fields) = report_validate_item($in, 'lost', 'reporter_phone');
    if ($fields) {
        throw new UserError(implode(' ', $fields), $fields);
    }

    return report_save_item($conn, $userId, 'lost', $base, $imageField, function ($conn, $uid, $catId, $locId, $b) {
        return db_exec(
            $conn,
            "INSERT INTO lost_items (user_id, category_id, location_id, item_name, description, color, brand, lost_date, status, created_at)
             VALUES (?, ?, ?, ?, ?, '', '', ?, 'searching', NOW())",
            'iiisss',
            array($uid, $catId, $locId, $b['item_name'], $b['desc_db'], $b['date_db'])
        );
    });
}

function report_create_found($conn, $userId, array $in, $imageField = 'item_image')
{
    list($base, $fields) = report_validate_item($in, 'found', 'finder_phone');

    $currentStatus = trim(isset($in['current_status']) ? (string)$in['current_status'] : '');
    $reportKindIn  = trim(isset($in['report_kind']) ? (string)$in['report_kind'] : '');
    $secQ          = trim(isset($in['security_question']) ? (string)$in['security_question'] : '');
    $secA          = trim(isset($in['security_answer']) ? (string)$in['security_answer'] : '');

    if (!in_array($currentStatus, lookup_found_current_statuses(), true)) {
        $fields['current_status'] = msg('report.current_status_required');
    }
    if (($secQ !== '') !== ($secA !== '')) {
        $fields['security_question'] = msg('report.security_qa_pair');
    } elseif ($secQ !== '' && (mb_strlen($secQ) > 255 || mb_strlen($secA) > 255)) {
        $fields['security_question'] = msg('report.security_qa_long');
    }
    if ($fields) {
        throw new UserError(implode(' ', $fields), $fields);
    }

    $reportKind = ($reportKindIn === 'sighting' || $currentStatus === lookup_sighting_status()) ? 'sighting' : 'found';

    return report_save_item($conn, $userId, 'found', $base, $imageField,
        function ($conn, $uid, $catId, $locId, $b) use ($currentStatus, $reportKind, $secQ, $secA) {
            $foundId = db_exec(
                $conn,
                "INSERT INTO found_items (user_id, category_id, location_id, item_name, description, color, brand, found_date, status, current_status, report_kind, created_at)
                 VALUES (?, ?, ?, ?, ?, '', '', ?, 'received', ?, ?, NOW())",
                'iiisssss',
                array($uid, $catId, $locId, $b['item_name'], $b['desc_db'], $b['date_db'], $currentStatus, $reportKind)
            );

            if ($secQ !== '' && $secA !== '') {
                db_exec(
                    $conn,
                    "INSERT INTO security_questions (item_id, item_type, security_question, correct_answer, created_at)
                     VALUES (?, 'found', ?, ?, NOW())",
                    'iss',
                    array($foundId, $secQ, $secA)
                );
            }
            return $foundId;
        }
    );
}

function report_create_emergency($conn, $userIdOrNull, array $in, $photoField = 'item_image')
{
    $uid      = $userIdOrNull !== null ? (int)$userIdOrNull : null;
    $name     = trim(isset($in['person_name']) ? (string)$in['person_name'] : '');
    $age      = trim(isset($in['approx_age']) ? (string)$in['approx_age'] : '');
    $locSel   = trim(isset($in['last_seen_location']) ? (string)$in['last_seen_location'] : '');
    $locOther = trim(isset($in['location_other']) ? (string)$in['location_other'] : '');
    $clothing = trim(isset($in['clothing_description']) ? (string)$in['clothing_description'] : '');
    $phone    = trim(isset($in['reporter_phone']) ? (string)$in['reporter_phone'] : '');

    $other    = lookup_other();
    $location = ($locSel === $other && $locOther !== '') ? $locOther : $locSel;

    $fields = array();
    if ($age === '') {
        $fields['approx_age'] = msg('report.age_required');
    }
    if ($location === '' || $location === $other) {
        $fields['last_seen_location'] = msg('report.last_seen_required');
    }
    if ($clothing === '') {
        $fields['clothing_description'] = msg('report.clothing_required');
    }
    if (!preg_match(PHONE_PATTERN, $phone)) {
        $fields['reporter_phone'] = msg('account.phone_invalid');
    }
    if ($fields) {
        throw new UserError(msg('report.emergency_incomplete'), $fields);
    }

    $nameDb = mb_substr($name, 0, 100);
    $ageDb  = mb_substr($age, 0, 20);
    $locDb  = mb_substr($location, 0, 150);

    $savedFile = '';
    try {
        $conn->begin_transaction();

        $emId = db_exec(
            $conn,
            "INSERT INTO emergency_reports (user_id, person_name, approx_age, last_seen_location, clothing_description, reporter_phone, status, created_at)
             VALUES (?, ?, ?, ?, ?, ?, 'active', NOW())",
            'isssss',
            array($uid, $nameDb, $ageDb, $locDb, $clothing, $phone)
        );

        $savedFile = save_item_image($conn, 'emergency', $emId, $photoField);
        if ($savedFile !== '') {
            $url = 'assets/uploads/' . basename($savedFile);
            db_exec(
                $conn,
                'UPDATE emergency_reports SET photo_url = ? WHERE emergency_id = ?',
                'si',
                array($url, $emId)
            );
        }

        if ($uid !== null) {
            account_remember_phone($conn, $uid, $phone);
        }

        $conn->commit();
        return array('id' => (int)$emId);
    } catch (Exception $ex) {
        $conn->rollback();
        if ($savedFile !== '' && is_file($savedFile)) {
            unlink($savedFile);
        }
        throw $ex;
    }
}

function report_mine($conn, $userId)
{
    $uid = (int)$userId;

    $lostRows = db_all(
        $conn,
        'SELECT ' . item_summary_select('lost') . ', i.cancel_reason
         FROM lost_items i ' . item_summary_joins() . '
         WHERE i.user_id = ?
         ORDER BY i.created_at DESC, i.lost_item_id DESC',
        'i',
        array($uid)
    );
    $lost = array();
    foreach ($lostRows as $r) {
        $item = present_item($r);
        $item['cancel_reason'] = $r['cancel_reason'];
        $lost[] = $item;
    }

    $foundRows = db_all(
        $conn,
        'SELECT ' . item_summary_select('found') . '
         FROM found_items i ' . item_summary_joins() . '
         WHERE i.user_id = ?
         ORDER BY i.created_at DESC, i.found_item_id DESC',
        'i',
        array($uid)
    );
    $found = array_map('present_item', $foundRows);

    $emRows = db_all(
        $conn,
        'SELECT emergency_id, person_name, approx_age, last_seen_location, status, created_at
         FROM emergency_reports
         WHERE user_id = ?
         ORDER BY created_at DESC, emergency_id DESC',
        'i',
        array($uid)
    );
    $emergencies = array();
    foreach ($emRows as $e) {
        $emergencies[] = array(
            'id'                 => (int)$e['emergency_id'],
            'person_name'        => $e['person_name'],
            'approx_age'         => $e['approx_age'],
            'last_seen_location' => $e['last_seen_location'],
            'status'             => $e['status'],
            'status_label'       => status_label($e['status']),
            'created_at'         => $e['created_at'],
        );
    }

    return array(
        'lost'        => $lost,
        'found'       => $found,
        'emergencies' => $emergencies,
    );
}

function report_cancel_lost($conn, $userId, $lostId, $reason, $details = '')
{
    $reason  = trim((string)$reason);
    $details = trim((string)$details);

    if (!in_array($reason, lookup_cancel_reasons(), true)) {
        throw new UserError(msg('report.cancel_reason_required'), array('reason' => msg('report.cancel_reason_invalid')));
    }

    $row = db_one(
        $conn,
        'SELECT lost_item_id, status FROM lost_items WHERE lost_item_id = ? AND user_id = ?',
        'ii',
        array((int)$lostId, (int)$userId)
    );
    if (!$row) {
        throw new NotFoundError(msg('report.not_found'));
    }
    if (!in_array($row['status'], array('searching', 'matched'), true)) {
        throw new ConflictError(msg('report.cancel_not_allowed'));
    }

    $cancelReason = $details !== '' ? ($reason . ' — ' . $details) : $reason;
    $cancelReason = mb_substr($cancelReason, 0, 255);

    db_exec(
        $conn,
        "UPDATE lost_items SET status = 'cancelled', cancel_reason = ?, cancelled_at = NOW() WHERE lost_item_id = ?",
        'si',
        array($cancelReason, (int)$lostId)
    );
    db_exec(
        $conn,
        "UPDATE matches SET match_status = 'rejected' WHERE lost_item_id = ? AND match_status = 'pending'",
        'i',
        array((int)$lostId)
    );
}

function report_track($conn, $lostId)
{
    $id = (int)$lostId;
    if ($id <= 0) {
        throw new NotFoundError(msg('report.not_found'));
    }
    $row = db_one(
        $conn,
        'SELECT l.lost_item_id, c.category_name, l.status, l.created_at
         FROM lost_items l
         LEFT JOIN categories c ON c.category_id = l.category_id
         WHERE l.lost_item_id = ?',
        'i',
        array($id)
    );
    if (!$row) {
        throw new NotFoundError(msg('report.not_found'));
    }

    return array(
        'id'           => (int)$row['lost_item_id'],
        'category'     => $row['category_name'] ? $row['category_name'] : '',
        'status'       => $row['status'],
        'status_label' => status_label($row['status']),
        'created_at'   => $row['created_at'],
    );
}
