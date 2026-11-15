<?php
/* ============================================================
   lib/services/item_service.php — public item browsing, details,
   and map pins. Never returns personal reporter/finder data.
   ============================================================ */

define('ITEMS_PER_PAGE', 20);

function item_build_query($type, $category, $q, &$types, array &$params)
{
    $table = $type === 'lost' ? 'lost_items' : 'found_items';
    $where = array("i.status NOT IN ('cancelled', 'delivered')");

    if ($category !== '') {
        $where[]  = 'c.category_name = ?';
        $types   .= 's';
        $params[] = $category;
    }
    if ($q !== '') {
        $where[]  = '(i.item_name LIKE ? OR i.description LIKE ?)';
        $like     = '%' . $q . '%';
        $types   .= 'ss';
        $params[] = $like;
        $params[] = $like;
    }

    return 'SELECT ' . item_summary_select($type) . " FROM $table i " . item_summary_joins() . ' WHERE ' . implode(' AND ', $where);
}

function item_browse($conn, $type = 'all', $category = '', $q = '', $page = 1)
{
    $type     = trim((string)$type);
    $category = trim((string)$category);
    $q        = trim((string)$q);
    $page     = max(1, (int)$page);
    $offset   = ($page - 1) * ITEMS_PER_PAGE;
    $limit    = ITEMS_PER_PAGE + 1;

    $types  = '';
    $params = array();

    if ($type === 'lost' || $type === 'found') {
        $sql = item_build_query($type, $category, $q, $types, $params)
             . ' ORDER BY i.created_at DESC, id DESC LIMIT ? OFFSET ?';
    } else {
        $sqlLost  = item_build_query('lost', $category, $q, $types, $params);
        $sqlFound = item_build_query('found', $category, $q, $types, $params);
        $sql      = "SELECT * FROM (($sqlLost) UNION ALL ($sqlFound)) AS combined ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?";
    }

    $types   .= 'ii';
    $params[] = $limit;
    $params[] = $offset;

    $rows    = db_all($conn, $sql, $types, $params);
    $hasMore = count($rows) > ITEMS_PER_PAGE;
    if ($hasMore) {
        array_pop($rows);
    }

    return array(
        'items'    => array_map('present_item', $rows),
        'page'     => $page,
        'has_more' => $hasMore,
    );
}

function item_details($conn, $type, $id)
{
    $type = trim((string)$type);
    $id   = (int)$id;
    if (($type !== 'lost' && $type !== 'found') || $id <= 0) {
        throw new NotFoundError(msg('item.not_found'));
    }

    $table = $type === 'lost' ? 'lost_items' : 'found_items';
    $idCol = $type === 'lost' ? 'lost_item_id' : 'found_item_id';

    $row = db_one(
        $conn,
        'SELECT ' . item_summary_select($type) . " FROM $table i " . item_summary_joins() . " WHERE i.$idCol = ?",
        'i',
        array($id)
    );
    if (!$row) {
        throw new NotFoundError(msg('item.not_found'));
    }

    $item = present_item($row);

    $imgRows = db_all(
        $conn,
        "SELECT image_url FROM item_images WHERE $idCol = ? ORDER BY image_id ASC",
        'i',
        array($id)
    );
    $images = array();
    foreach ($imgRows as $img) {
        if (!empty($img['image_url'])) {
            $images[] = $img['image_url'];
        }
    }
    $item['images']            = $images;
    $item['security_question'] = $type === 'found' ? security_question_for($conn, $id) : null;

    return $item;
}

function item_map($conn, $type = 'all')
{
    $type = trim((string)$type);
    $cond = "i.status NOT IN ('cancelled', 'delivered') AND loc.latitude IS NOT NULL AND loc.longitude IS NOT NULL";

    $sqlLost  = 'SELECT ' . item_summary_select('lost') . ' FROM lost_items i ' . item_summary_joins() . " WHERE $cond";
    $sqlFound = 'SELECT ' . item_summary_select('found') . ' FROM found_items i ' . item_summary_joins() . " WHERE $cond";

    if ($type === 'lost') {
        $sql = $sqlLost . ' ORDER BY i.created_at DESC, id DESC';
    } elseif ($type === 'found') {
        $sql = $sqlFound . ' ORDER BY i.created_at DESC, id DESC';
    } else {
        $sql = "SELECT * FROM (($sqlLost) UNION ALL ($sqlFound)) AS combined ORDER BY created_at DESC, id DESC";
    }

    $rows = db_all($conn, $sql);
    return array('items' => array_map('present_item', $rows));
}
