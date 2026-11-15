<?php
/* ============================================================
   lib/services/presenters.php — one shape for items and statuses,
   shared by the website pages and the API (docs/API.md "ItemSummary").

   Services return image paths relative to the website root
   (assets/uploads/x.jpg). The API turns them into absolute URLs.
   ============================================================ */

/** Label for any status value (from lang/<code>.php "status.<value>"). */
function status_label($status)
{
    $key = 'status.' . $status;
    $label = msg($key);
    return $label === $key ? (string)$status : $label;
}

/** @deprecated kept for older callers; use status_label(). */
function status_label_ar($status)
{
    return status_label($status);
}

/**
 * SQL columns for an item summary. Use with the joins from item_summary_joins().
 * $type: 'lost' | 'found'.  Table alias is always "i".
 */
function item_summary_select($type)
{
    $id = $type === 'lost' ? 'lost_item_id' : 'found_item_id';
    $date = $type === 'lost' ? 'lost_date' : 'found_date';
    $extra = $type === 'found'
        ? 'i.report_kind, i.current_status,'
        : 'NULL AS report_kind, NULL AS current_status,';
    return "i.$id AS id, '$type' AS type, i.item_name, i.description, i.status, i.$date AS item_date,
            i.created_at, $extra
            c.category_name AS category, loc.location_name AS location,
            loc.latitude AS lat, loc.longitude AS lng,
            (SELECT img.image_url FROM item_images img WHERE img.$id = i.$id ORDER BY img.image_id LIMIT 1) AS image_url";
}

function item_summary_joins()
{
    return 'LEFT JOIN categories c ON c.category_id = i.category_id
            LEFT JOIN locations loc ON loc.location_id = i.location_id';
}

/** Convert a row selected with item_summary_select() into the ItemSummary shape. */
function present_item(array $row)
{
    return array(
        'id' => (int)$row['id'],
        'type' => $row['type'],
        'item_name' => $row['item_name'],
        'description' => $row['description'],
        'category' => $row['category'],
        'location' => $row['location'],
        'lat' => $row['lat'] !== null ? (float)$row['lat'] : null,
        'lng' => $row['lng'] !== null ? (float)$row['lng'] : null,
        'date' => $row['item_date'] ? substr($row['item_date'], 0, 10) : null,
        'status' => $row['status'],
        'status_label' => status_label($row['status']),
        'image_url' => $row['image_url'] ?: null,
        'report_kind' => $row['report_kind'],
        'current_status' => $row['current_status'],
        'created_at' => $row['created_at'],
    );
}

/** Run a prepared SELECT and return all rows. $types/$params as for bind_param. */
function db_all($conn, $sql, $types = '', array $params = array())
{
    $stmt = $conn->prepare($sql);
    if ($types !== '') {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    $stmt->close();
    return $rows;
}

/** Run a prepared SELECT and return the first row or null. */
function db_one($conn, $sql, $types = '', array $params = array())
{
    $rows = db_all($conn, $sql, $types, $params);
    return $rows ? $rows[0] : null;
}

/** Run a prepared INSERT/UPDATE/DELETE; returns insert_id (or affected rows when no id). */
function db_exec($conn, $sql, $types = '', array $params = array())
{
    $stmt = $conn->prepare($sql);
    if ($types !== '') {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->insert_id ?: $stmt->affected_rows;
    $stmt->close();
    return $result;
}
