<?php
/* ============================================================
   lib/services/claim_service.php — suggested matches and item claims
   (user actions and admin verification/delivery).
   ============================================================ */

/** Look up the latest security question and answer row for a found item. */
function security_qa_for($conn, $foundItemId)
{
    return db_one(
        $conn,
        "SELECT security_question, correct_answer FROM security_questions
         WHERE item_type = 'found' AND item_id = ?
         ORDER BY question_id DESC LIMIT 1",
        'i',
        array((int)$foundItemId)
    );
}

/** Security question text for a found item, or null if none. */
function security_question_for($conn, $foundItemId)
{
    $sq = security_qa_for($conn, $foundItemId);
    return ($sq && $sq['security_question'] !== '') ? $sq['security_question'] : null;
}

/** Validate that a claim description has at least 10 characters. */
function claim_validate_description($description)
{
    $description = trim((string)$description);
    if (mb_strlen($description) < 10) {
        throw new UserError(
            msg('claim.description_short'),
            array('claim_description' => msg('claim.description_min'))
        );
    }
    return $description;
}

/** Insert a claim in 'Under Review' status and return the new claim_id. */
function claim_insert($conn, $foundId, $userId, $description, $securityAnswer = '')
{
    $secAnswer    = trim((string)$securityAnswer);
    $secAnsOrNull = $secAnswer !== '' ? mb_substr($secAnswer, 0, 255) : null;
    return (int)db_exec(
        $conn,
        "INSERT INTO claims (found_item_id, user_id, claim_description, security_answer, claim_date, status)
         VALUES (?, ?, ?, ?, NOW(), 'Under Review')",
        'iiss',
        array((int)$foundId, (int)$userId, $description, $secAnsOrNull)
    );
}

/** Fetch a match belonging to $userId and verify it is still 'pending'. */
function match_require_pending($conn, $userId, $matchId)
{
    $m = db_one(
        $conn,
        'SELECT m.match_id, m.found_item_id, m.match_status
         FROM matches m
         JOIN lost_items l ON l.lost_item_id = m.lost_item_id
         WHERE m.match_id = ? AND l.user_id = ?',
        'ii',
        array((int)$matchId, (int)$userId)
    );
    if (!$m) {
        throw new NotFoundError(msg('match.not_found'));
    }
    if ($m['match_status'] !== 'pending') {
        throw new ConflictError(msg('match.already_handled'));
    }
    return $m;
}

function match_list_for_user($conn, $userId)
{
    $sql = 'SELECT m.match_id, m.match_score, m.lost_item_id,
                   ' . item_summary_select('found') . '
            FROM matches m
            JOIN lost_items l ON l.lost_item_id = m.lost_item_id
            JOIN found_items i ON i.found_item_id = m.found_item_id
            ' . item_summary_joins() . '
            WHERE l.user_id = ? AND m.match_status = \'pending\'
            ORDER BY m.created_at DESC, m.match_id DESC';

    $rows    = db_all($conn, $sql, 'i', array((int)$userId));
    $matches = array();
    foreach ($rows as $r) {
        $matches[] = array(
            'match_id'          => (int)$r['match_id'],
            'score'             => (float)$r['match_score'],
            'lost_item_id'      => (int)$r['lost_item_id'],
            'found'             => present_item($r),
            'security_question' => security_question_for($conn, (int)$r['id']),
        );
    }
    return array('matches' => $matches);
}

function match_claim($conn, $userId, $matchId, $description, $securityAnswer = '')
{
    $uid         = (int)$userId;
    $mid         = (int)$matchId;
    $m           = match_require_pending($conn, $uid, $mid);
    $description = claim_validate_description($description);
    $foundId     = (int)$m['found_item_id'];

    try {
        $conn->begin_transaction();

        $claimId = claim_insert($conn, $foundId, $uid, $description, $securityAnswer);
        db_exec(
            $conn,
            "UPDATE matches SET match_status = 'claimed' WHERE match_id = ?",
            'i',
            array($mid)
        );

        $conn->commit();
        return array('claim_id' => $claimId);
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

function match_reject($conn, $userId, $matchId)
{
    $m = match_require_pending($conn, (int)$userId, (int)$matchId);
    db_exec($conn, "UPDATE matches SET match_status = 'rejected' WHERE match_id = ?", 'i', array((int)$m['match_id']));
}

function claim_found_item($conn, $userId, $foundId, $description, $securityAnswer = '')
{
    $uid = (int)$userId;
    $fid = (int)$foundId;

    $item = db_one(
        $conn,
        'SELECT found_item_id, user_id, status FROM found_items WHERE found_item_id = ?',
        'i',
        array($fid)
    );
    if (!$item) {
        throw new NotFoundError(msg('item.not_found'));
    }
    if ((int)$item['user_id'] === $uid) {
        throw new ForbiddenError(msg('claim.own_item'));
    }
    if (!in_array($item['status'], array('received', 'matched'), true)) {
        throw new ConflictError(msg('claim.item_unavailable'));
    }

    $existing = db_one(
        $conn,
        "SELECT claim_id FROM claims
         WHERE found_item_id = ? AND user_id = ? AND status IN ('Under Review', 'Approved')
         LIMIT 1",
        'ii',
        array($fid, $uid)
    );
    if ($existing) {
        throw new ConflictError(msg('claim.already_claimed'));
    }

    $description = claim_validate_description($description);

    try {
        $conn->begin_transaction();

        $claimId = claim_insert($conn, $fid, $uid, $description, $securityAnswer);

        db_exec(
            $conn,
            "UPDATE matches m
             JOIN lost_items l ON l.lost_item_id = m.lost_item_id
             SET m.match_status = 'claimed'
             WHERE m.found_item_id = ? AND l.user_id = ? AND m.match_status = 'pending'",
            'ii',
            array($fid, $uid)
        );

        $conn->commit();
        return array('claim_id' => $claimId);
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

function claim_list_for_user($conn, $userId)
{
    $sql = 'SELECT cl.claim_id, cl.status AS claim_status, cl.claim_date, cl.reviewed_at, cl.reject_reason,
                   s.shipping_id, s.status AS shipping_status, s.carrier, s.tracking_number,
                   ' . item_summary_select('found') . '
            FROM claims cl
            JOIN found_items i ON i.found_item_id = cl.found_item_id
            ' . item_summary_joins() . '
            LEFT JOIN shipping_requests s ON s.claim_id = cl.claim_id
            WHERE cl.user_id = ?
            ORDER BY cl.claim_date DESC, cl.claim_id DESC';

    $rows   = db_all($conn, $sql, 'i', array((int)$userId));
    $claims = array();
    foreach ($rows as $r) {
        $shipping = null;
        if ($r['shipping_id'] !== null) {
            $shipping = array(
                'shipping_id'     => (int)$r['shipping_id'],
                'status'          => $r['shipping_status'],
                'status_label'    => status_label($r['shipping_status']),
                'carrier'         => $r['carrier'],
                'tracking_number' => $r['tracking_number'],
            );
        }
        $claims[] = array(
            'claim_id'      => (int)$r['claim_id'],
            'status'        => $r['claim_status'],
            'status_label'  => status_label($r['claim_status']),
            'claim_date'    => $r['claim_date'],
            'reviewed_at'   => $r['reviewed_at'],
            'reject_reason' => $r['reject_reason'],
            'item'          => present_item($r),
            'shipping'      => $shipping,
        );
    }
    return array('claims' => $claims);
}

/* ---------- admin claim management ---------- */

function claim_admin_list($conn, $status = 'Under Review')
{
    $status = trim((string)$status);
    if ($status === '') {
        $status = 'Under Review';
    }

    $sql = 'SELECT cl.claim_id, cl.status AS claim_status, cl.claim_description, cl.claim_date,
                   cl.reviewed_at, cl.reject_reason, cl.security_answer,
                   u.full_name AS claimant_name, u.email AS claimant_email, u.phone AS claimant_phone,
                   ' . item_summary_select('found') . '
            FROM claims cl
            JOIN users u ON u.user_id = cl.user_id
            JOIN found_items i ON i.found_item_id = cl.found_item_id
            ' . item_summary_joins();

    $types  = '';
    $params = array();
    if ($status !== 'all') {
        $sql     .= ' WHERE cl.status = ?';
        $types   .= 's';
        $params[] = $status;
    }
    $sql .= ' ORDER BY cl.claim_date DESC, cl.claim_id DESC';

    $rows   = db_all($conn, $sql, $types, $params);
    $claims = array();
    foreach ($rows as $r) {
        $qa = security_qa_for($conn, (int)$r['id']);
        $claims[] = array(
            'claim_id'          => (int)$r['claim_id'],
            'status'            => $r['claim_status'],
            'status_label'      => status_label($r['claim_status']),
            'claim_description' => $r['claim_description'],
            'claim_date'        => $r['claim_date'],
            'reviewed_at'       => $r['reviewed_at'],
            'reject_reason'     => $r['reject_reason'],
            'security_question' => ($qa && $qa['security_question'] !== '') ? $qa['security_question'] : null,
            'correct_answer'    => ($qa && $qa['correct_answer'] !== '') ? $qa['correct_answer'] : null,
            'security_answer'   => $r['security_answer'],
            'claimant'          => array(
                'full_name' => $r['claimant_name'],
                'email'     => $r['claimant_email'],
                'phone'     => $r['claimant_phone'],
            ),
            'item'              => present_item($r),
        );
    }
    return array('claims' => $claims);
}

/** Fetch a claim and verify it is in $expectedStatus. */
function claim_require_status($conn, $claimId, $expectedStatus)
{
    $row = db_one(
        $conn,
        'SELECT claim_id, user_id, found_item_id, status FROM claims WHERE claim_id = ?',
        'i',
        array((int)$claimId)
    );
    if (!$row) {
        throw new NotFoundError(msg('claim.not_found'));
    }
    if ($row['status'] !== $expectedStatus) {
        throw new ConflictError(msg('claim.invalid_state'));
    }
    return $row;
}

/** Update the found item and any linked lost item + match for the claimant. */
function claim_update_item_and_match($conn, $foundId, $userId, $itemStatus, $matchStatus)
{
    db_exec(
        $conn,
        'UPDATE found_items SET status = ? WHERE found_item_id = ?',
        'si',
        array($itemStatus, (int)$foundId)
    );
    db_exec(
        $conn,
        'UPDATE lost_items l JOIN matches m ON m.lost_item_id = l.lost_item_id
         SET l.status = ?, m.match_status = ?
         WHERE m.found_item_id = ? AND l.user_id = ?',
        'ssii',
        array($itemStatus, $matchStatus, (int)$foundId, (int)$userId)
    );
}

function claim_approve($conn, $claimId)
{
    try {
        $conn->begin_transaction();

        $c   = claim_require_status($conn, $claimId, 'Under Review');
        $cid = (int)$c['claim_id'];
        $fid = (int)$c['found_item_id'];
        $uid = (int)$c['user_id'];

        db_exec(
            $conn,
            "UPDATE claims SET status = 'Approved', reviewed_at = NOW() WHERE claim_id = ?",
            'i',
            array($cid)
        );
        claim_update_item_and_match($conn, $fid, $uid, 'ready', 'approved');
        notify($conn, $uid, msg('claim.approved_title'), msg('claim.approved_body'), 'claim');

        $conn->commit();
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

function claim_reject($conn, $claimId, $reason = '')
{
    $reasonClean  = trim((string)$reason);
    $reasonOrNull = $reasonClean !== '' ? mb_substr($reasonClean, 0, 255) : null;

    try {
        $conn->begin_transaction();

        $c   = claim_require_status($conn, $claimId, 'Under Review');
        $cid = (int)$c['claim_id'];
        $fid = (int)$c['found_item_id'];
        $uid = (int)$c['user_id'];

        db_exec(
            $conn,
            "UPDATE claims SET status = 'Rejected', reject_reason = ?, reviewed_at = NOW() WHERE claim_id = ?",
            'si',
            array($reasonOrNull, $cid)
        );
        db_exec(
            $conn,
            "UPDATE matches SET match_status = 'rejected' WHERE found_item_id = ? AND match_status = 'claimed'",
            'i',
            array($fid)
        );

        $body = msg('claim.rejected_body');
        if ($reasonOrNull !== null) {
            $body .= ' ' . msg('claim.rejected_reason', array('reason' => $reasonOrNull));
        }
        notify($conn, $uid, msg('claim.rejected_title'), $body, 'claim');

        $conn->commit();
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

function claim_deliver($conn, $claimId)
{
    try {
        $conn->begin_transaction();

        $c   = claim_require_status($conn, $claimId, 'Approved');
        $cid = (int)$c['claim_id'];
        $fid = (int)$c['found_item_id'];
        $uid = (int)$c['user_id'];

        db_exec(
            $conn,
            "UPDATE claims SET status = 'Delivered', reviewed_at = NOW() WHERE claim_id = ?",
            'i',
            array($cid)
        );
        claim_update_item_and_match($conn, $fid, $uid, 'delivered', 'delivered');
        notify($conn, $uid, msg('claim.delivered_title'), msg('claim.delivered_body'), 'claim');

        $conn->commit();
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}
