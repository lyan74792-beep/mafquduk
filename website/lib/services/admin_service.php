<?php
/* ============================================================
   lib/services/admin_service.php — admin dashboard statistics,
   emergencies, reports, manual matching, and pending admin accounts.
   ============================================================ */

/** Helper for COUNT(*) queries returning a single integer. */
function admin_count($conn, $sql, $types = '', array $params = array())
{
    $row = db_one($conn, $sql, $types, $params);
    return $row ? (int)$row['cnt'] : 0;
}

/** Convert rows with {name, cnt} into [{name, count}]. */
function admin_present_counts(array $rows)
{
    $out = array();
    foreach ($rows as $r) {
        $out[] = array(
            'name'  => $r['name'],
            'count' => (int)$r['cnt'],
        );
    }
    return $out;
}

function admin_stats($conn)
{
    $totalLost         = admin_count($conn, 'SELECT COUNT(*) AS cnt FROM lost_items');
    $totalFound        = admin_count($conn, 'SELECT COUNT(*) AS cnt FROM found_items');
    $pendingMatches    = admin_count($conn, "SELECT COUNT(*) AS cnt FROM matches WHERE match_status = 'pending'");
    $claimsUnderReview = admin_count($conn, "SELECT COUNT(*) AS cnt FROM claims WHERE status = 'Under Review'");
    $activeEmergencies = admin_count($conn, "SELECT COUNT(*) AS cnt FROM emergency_reports WHERE status = 'active'");
    $totalMatches      = admin_count($conn, 'SELECT COUNT(*) AS cnt FROM matches');

    db_exec(
        $conn,
        'INSERT INTO system_stats (stat_id, total_lost, total_found, pending_reports, total_matches, updated_at)
         VALUES (1, ?, ?, ?, ?, NOW())
         ON DUPLICATE KEY UPDATE
             total_lost = VALUES(total_lost),
             total_found = VALUES(total_found),
             pending_reports = VALUES(pending_reports),
             total_matches = VALUES(total_matches),
             updated_at = NOW()',
        'iiii',
        array($totalLost, $totalFound, $claimsUnderReview, $totalMatches)
    );

    $avgRow = db_one(
        $conn,
        "SELECT AVG(TIMESTAMPDIFF(HOUR, claim_date, reviewed_at)) AS avg_hours
         FROM claims
         WHERE status IN ('Approved', 'Delivered') AND reviewed_at IS NOT NULL"
    );
    $avgHours = ($avgRow && $avgRow['avg_hours'] !== null) ? round((float)$avgRow['avg_hours'], 1) : null;

    $catRows = db_all(
        $conn,
        'SELECT cat.category_name AS name, COUNT(*) AS cnt
         FROM (SELECT category_id FROM lost_items UNION ALL SELECT category_id FROM found_items) i
         JOIN categories cat ON cat.category_id = i.category_id
         GROUP BY cat.category_id, cat.category_name
         ORDER BY cnt DESC'
    );

    $locRows = db_all(
        $conn,
        'SELECT loc.location_name AS name, COUNT(*) AS cnt
         FROM lost_items l
         JOIN locations loc ON loc.location_id = l.location_id
         GROUP BY loc.location_id, loc.location_name
         ORDER BY cnt DESC
         LIMIT 6'
    );

    $geoRows = db_all(
        $conn,
        'SELECT loc.latitude, loc.longitude, COUNT(*) AS cnt
         FROM (SELECT location_id FROM lost_items UNION ALL SELECT location_id FROM found_items) i
         JOIN locations loc ON loc.location_id = i.location_id
         WHERE loc.latitude IS NOT NULL AND loc.longitude IS NOT NULL
         GROUP BY loc.location_id, loc.latitude, loc.longitude'
    );
    $heatPoints = array();
    foreach ($geoRows as $r) {
        $heatPoints[] = array(
            'lat'    => (float)$r['latitude'],
            'lng'    => (float)$r['longitude'],
            'weight' => (int)$r['cnt'],
        );
    }

    return array(
        'total_lost'          => $totalLost,
        'total_found'         => $totalFound,
        'pending_matches'     => $pendingMatches,
        'claims_under_review' => $claimsUnderReview,
        'active_emergencies'  => $activeEmergencies,
        'avg_review_hours'    => $avgHours,
        'by_category'         => admin_present_counts($catRows),
        'top_locations'       => admin_present_counts($locRows),
        'heat_points'         => $heatPoints,
    );
}

function admin_emergencies($conn, $status = 'active')
{
    $status = trim((string)$status);
    if ($status === '') {
        $status = 'active';
    }

    $sql = 'SELECT emergency_id, person_name, approx_age, last_seen_location,
                   clothing_description, reporter_phone, photo_url, status, created_at
            FROM emergency_reports';

    $types  = '';
    $params = array();
    if ($status !== 'all') {
        $sql     .= ' WHERE status = ?';
        $types   .= 's';
        $params[] = $status;
    }
    $sql .= ' ORDER BY created_at DESC, emergency_id DESC';

    $rows = db_all($conn, $sql, $types, $params);
    $out  = array();
    foreach ($rows as $r) {
        $out[] = array(
            'id'                   => (int)$r['emergency_id'],
            'person_name'          => $r['person_name'],
            'approx_age'           => $r['approx_age'],
            'last_seen_location'   => $r['last_seen_location'],
            'clothing_description' => $r['clothing_description'],
            'reporter_phone'       => $r['reporter_phone'],
            'photo_url'            => $r['photo_url'] ?: null,
            'status'               => $r['status'],
            'status_label'         => status_label($r['status']),
            'created_at'           => $r['created_at'],
        );
    }

    return array('emergencies' => $out);
}

function admin_resolve_emergency($conn, $adminId, $id)
{
    $emId = (int)$id;
    $aid  = (int)$adminId;

    $row = db_one(
        $conn,
        'SELECT emergency_id, user_id, status FROM emergency_reports WHERE emergency_id = ?',
        'i',
        array($emId)
    );
    if (!$row) {
        throw new NotFoundError(msg('report.emergency_not_found'));
    }
    if ($row['status'] === 'found') {
        throw new ConflictError(msg('report.emergency_already_resolved'));
    }

    try {
        $conn->begin_transaction();

        db_exec(
            $conn,
            "UPDATE emergency_reports
             SET status = 'found', resolved_at = NOW(), resolved_by = ?
             WHERE emergency_id = ?",
            'ii',
            array($aid, $emId)
        );

        if ($row['user_id'] !== null) {
            notify(
                $conn,
                (int)$row['user_id'],
                msg('report.emergency_resolved_title'),
                msg('report.emergency_resolved_body', array('id' => $emId)),
                'emergency'
            );
        }

        $conn->commit();
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

/** Build a SELECT for lost or found reports including reporter info. */
function admin_reports_query($type, $status, &$types, array &$params)
{
    $table = $type === 'lost' ? 'lost_items' : 'found_items';
    $sql   = 'SELECT ' . item_summary_select($type) . ',
                     u.full_name AS reporter_name, u.phone AS reporter_phone, u.email AS reporter_email
              FROM ' . $table . ' i
              ' . item_summary_joins() . '
              LEFT JOIN users u ON u.user_id = i.user_id';

    if ($status !== '' && $status !== 'all') {
        $sql     .= ' WHERE i.status = ?';
        $types   .= 's';
        $params[] = $status;
    }
    return $sql;
}

function admin_reports($conn, $type = 'all', $status = '')
{
    $type   = trim((string)$type);
    $status = trim((string)$status);
    $types  = '';
    $params = array();

    if ($type === 'lost' || $type === 'found') {
        $sql = admin_reports_query($type, $status, $types, $params)
             . ' ORDER BY i.created_at DESC, id DESC LIMIT 200';
    } else {
        $sqlLost  = admin_reports_query('lost', $status, $types, $params);
        $sqlFound = admin_reports_query('found', $status, $types, $params);
        $sql      = "SELECT * FROM (($sqlLost) UNION ALL ($sqlFound)) AS combined ORDER BY created_at DESC, id DESC LIMIT 200";
    }

    $rows    = db_all($conn, $sql, $types, $params);
    $reports = array();
    foreach ($rows as $r) {
        $item = present_item($r);
        $item['reporter'] = array(
            'full_name' => $r['reporter_name'],
            'phone'     => $r['reporter_phone'],
            'email'     => $r['reporter_email'],
        );
        $reports[] = $item;
    }

    return array('reports' => $reports);
}

function admin_open_items($conn)
{
    $lostRows = db_all(
        $conn,
        'SELECT ' . item_summary_select('lost') . '
         FROM lost_items i ' . item_summary_joins() . "
         WHERE i.status IN ('searching', 'matched')
         ORDER BY i.created_at DESC, i.lost_item_id DESC"
    );
    $foundRows = db_all(
        $conn,
        'SELECT ' . item_summary_select('found') . '
         FROM found_items i ' . item_summary_joins() . "
         WHERE i.status IN ('received', 'matched')
         ORDER BY i.created_at DESC, i.found_item_id DESC"
    );

    return array(
        'lost'  => array_map('present_item', $lostRows),
        'found' => array_map('present_item', $foundRows),
    );
}

function admin_manual_match($conn, $lostId, $foundId)
{
    $lid = (int)$lostId;
    $fid = (int)$foundId;
    if ($lid <= 0 || $fid <= 0) {
        throw new UserError(msg('match.items_required'));
    }

    try {
        $conn->begin_transaction();

        $lost = db_one(
            $conn,
            'SELECT lost_item_id, user_id, status FROM lost_items WHERE lost_item_id = ?',
            'i',
            array($lid)
        );
        $found = db_one(
            $conn,
            'SELECT found_item_id, status FROM found_items WHERE found_item_id = ?',
            'i',
            array($fid)
        );
        if (!$lost || !$found) {
            throw new NotFoundError(msg('item.not_found'));
        }
        if (!in_array($lost['status'], array('searching', 'matched'), true)
            || !in_array($found['status'], array('received', 'matched'), true)) {
            throw new ConflictError(msg('match.items_unavailable'));
        }

        $matchId = create_match($conn, $lid, $fid, 100.0, (int)$lost['user_id']);
        if (!$matchId) {
            throw new ConflictError(msg('match.already_exists'));
        }

        $conn->commit();
        return array('match_id' => (int)$matchId);
    } catch (Exception $ex) {
        $conn->rollback();
        throw $ex;
    }
}

/* ---------- pending admin accounts ---------- */

function admin_pending_admins($conn)
{
    $rows = db_all(
        $conn,
        "SELECT admin_id, full_name, email, role, created_at
         FROM admins
         WHERE role = 'pending'
         ORDER BY created_at DESC, admin_id DESC"
    );
    foreach ($rows as &$r) {
        $r['admin_id'] = (int)$r['admin_id'];
    }
    unset($r);
    return array('admins' => $rows);
}

/** Verify that an admin exists and is currently in 'pending' state. */
function admin_require_pending($conn, $id)
{
    $aid = (int)$id;
    $row = db_one($conn, 'SELECT admin_id, role FROM admins WHERE admin_id = ?', 'i', array($aid));
    if (!$row) {
        throw new NotFoundError(msg('account.not_found'));
    }
    if ($row['role'] !== 'pending') {
        throw new ConflictError(msg('account.admin_not_pending'));
    }
    return $aid;
}

function admin_approve_admin($conn, $id)
{
    $aid = admin_require_pending($conn, $id);
    db_exec($conn, "UPDATE admins SET role = 'admin' WHERE admin_id = ? AND role = 'pending'", 'i', array($aid));
}

function admin_reject_admin($conn, $id)
{
    $aid = admin_require_pending($conn, $id);
    db_exec($conn, "DELETE FROM admins WHERE admin_id = ? AND role = 'pending'", 'i', array($aid));
}
