<?php
/* ============================================================
   functions.php — دوال مشتركة: التصنيفات، المواقع، الصور، المطابقة الآلية، الإشعارات
   ============================================================ */

// أنواع الأخطاء المشتركة بين الموقع والـ API (UserError وأخواتها)
require_once __DIR__ . '/lib/errors.php';
// الرسائل من website/lang/<code>.php عبر msg('key')
require_once __DIR__ . '/lib/i18n.php';

if (!defined('MATCH_THRESHOLD')) {
    define('MATCH_THRESHOLD', 60);   // أقل درجة (من 100) لاقتراح مطابقة
}

/* ---------- المعالم: إحداثيات تقريبية تُستخدم لو المستخدم ما حدد موقعًا دقيقًا ---------- */
function landmark_coords($name) {
    $map = landmarks_map();
    return isset($map[$name]) ? $map[$name] : array(null, null);
}

/* قائمة المعالم المعتمدة => [lat, lng] — القيم في config/lookups.php */
function landmarks_map() {
    static $map = null;
    if ($map === null) {
        $config = require __DIR__ . '/config/lookups.php';
        $map = $config['landmarks'];
    }
    return $map;
}

/* ---------- التصنيف: يرجع رقمه، وينشئه لو غير موجود ---------- */
function find_or_create_category($conn, $name) {
    $stmt = $conn->prepare('SELECT category_id FROM categories WHERE category_name = ? LIMIT 1');
    $stmt->bind_param('s', $name);
    $stmt->execute();
    $stmt->bind_result($id);
    if ($stmt->fetch()) {
        $stmt->close();
        return (int)$id;
    }
    $stmt->close();

    $desc = '';
    $ins = $conn->prepare('INSERT INTO categories (category_name, description) VALUES (?, ?)');
    $ins->bind_param('ss', $name, $desc);
    $ins->execute();
    $newId = $ins->insert_id;
    $ins->close();
    return (int)$newId;
}

/* ---------- الموقع: يرجع رقمه. موقع دقيق (GPS/خريطة) = سجل جديد، وإلا يُعاد استخدام المعلم ---------- */
function resolve_location($conn, $selection, $other, $lat, $lng) {
    $selection = trim($selection);
    $other = trim($other);
    $isOther = ($selection === 'أخرى');
    $name = ($isOther && $other !== '') ? $other : $selection;
    if ($name === '' || $name === 'أخرى') {
        throw new UserError(msg('report.location_required'));
    }
    $name = mb_substr($name, 0, 100);

    $hasExact = is_numeric($lat) && is_numeric($lng)
        && (float)$lat >= -90 && (float)$lat <= 90
        && (float)$lng >= -180 && (float)$lng <= 180;

    if ($hasExact) {
        $la = (float)$lat;
        $lo = (float)$lng;
        $type = 'دقيق';
        $desc = 'موقع دقيق حدده المستخدم';
        $ins = $conn->prepare('INSERT INTO locations (location_name, location_type, latitude, longitude, description) VALUES (?, ?, ?, ?, ?)');
        $ins->bind_param('ssdds', $name, $type, $la, $lo, $desc);
        $ins->execute();
        $id = $ins->insert_id;
        $ins->close();
        return (int)$id;
    }

    $type = $isOther ? 'مخصص' : 'معلم';
    $stmt = $conn->prepare('SELECT location_id FROM locations WHERE location_name = ? AND location_type = ? LIMIT 1');
    $stmt->bind_param('ss', $name, $type);
    $stmt->execute();
    $stmt->bind_result($existing);
    if ($stmt->fetch()) {
        $stmt->close();
        return (int)$existing;
    }
    $stmt->close();

    $coords = landmark_coords($name);
    $la = $coords[0];
    $lo = $coords[1];
    $desc = '';
    $ins = $conn->prepare('INSERT INTO locations (location_name, location_type, latitude, longitude, description) VALUES (?, ?, ?, ?, ?)');
    $ins->bind_param('ssdds', $name, $type, $la, $lo, $desc);
    $ins->execute();
    $id = $ins->insert_id;
    $ins->close();
    return (int)$id;
}

/* ---------- الصورة: تتحقق وتحفظ، وللمفقود/المعثور تسجلها بجدول item_images.
   $field: اسم حقل الرفع (الموقع يستخدم item_image، والتطبيق image أو photo).
   ترجع مسار الملف على القرص (للحذف لو فشلت العملية)، أو '' لو لا توجد صورة ---------- */
function save_item_image($conn, $kind, $itemId, $field = 'item_image') {
    if (empty($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
        return '';
    }
    $f = $_FILES[$field];
    if ($f['error'] !== UPLOAD_ERR_OK) {
        throw new UserError(msg('upload.failed'));
    }
    if ($f['size'] > 5 * 1024 * 1024) {
        throw new UserError(msg('upload.too_large'));
    }
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($f['tmp_name']);
    $allowed = array('image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'image/gif' => 'gif');
    if (!isset($allowed[$mime])) {
        throw new UserError(msg('upload.invalid_type'));
    }

    $dir = __DIR__ . '/assets/uploads';
    if (!is_dir($dir)) {
        mkdir($dir, 0775, true);
    }
    // منع تنفيذ أي سكربت داخل مجلد الرفع
    if (!is_file($dir . '/.htaccess')) {
        file_put_contents($dir . '/.htaccess', "<FilesMatch \"\\.(php|phtml|phar)$\">\n    Require all denied\n</FilesMatch>\n");
    }

    $fileName = bin2hex(random_bytes(8)) . '.' . $allowed[$mime];
    $path = $dir . '/' . $fileName;
    if (!move_uploaded_file($f['tmp_name'], $path)) {
        throw new UserError(msg('upload.save_failed'));
    }

    // صور البلاغات الطارئة تُحفظ في emergency_reports.photo_url وليس هنا
    if ($kind === 'lost' || $kind === 'found') {
        $url = 'assets/uploads/' . $fileName;
        $lostId = ($kind === 'lost') ? $itemId : null;
        $foundId = ($kind === 'found') ? $itemId : null;
        $stmt = $conn->prepare('INSERT INTO item_images (lost_item_id, found_item_id, image_url, uploaded_at) VALUES (?, ?, ?, NOW())');
        $stmt->bind_param('iis', $lostId, $foundId, $url);
        $stmt->execute();
        $stmt->close();
    }
    return $path;
}

/* ---------- الإشعارات ---------- */
function notify($conn, $userId, $title, $message, $type) {
    $stmt = $conn->prepare('INSERT INTO notifications (user_id, title, message, notification_type, is_read, created_at) VALUES (?, ?, ?, ?, 0, NOW())');
    $stmt->bind_param('isss', $userId, $title, $message, $type);
    $stmt->execute();
    $stmt->close();
}

/* ============================================================
   المطابقة الآلية (بسيطة): نفس التصنيف شرط، ثم نقاط للموقع والتشابه النصي والتاريخ
   ============================================================ */
function tokens($text) {
    $text = mb_strtolower((string)$text, 'UTF-8');
    $parts = preg_split('/[^\p{L}\p{N}]+/u', $text, -1, PREG_SPLIT_NO_EMPTY);
    $stop = array('من', 'في', 'على', 'الى', 'إلى', 'عن', 'هذا', 'هذه', 'ذلك', 'التي', 'الذي', 'مع', 'او', 'أو', 'كان', 'لون', 'تم', 'تسليمه', 'حالة', 'الغرض', 'the', 'and', 'for', 'with');
    $out = array();
    foreach ($parts as $p) {
        $p = preg_replace('/^ال/u', '', $p);
        if (mb_strlen($p, 'UTF-8') >= 3 && !in_array($p, $stop, true)) {
            $out[$p] = true;
        }
    }
    return array_keys($out);
}

// معامل التداخل: المشترك ÷ الأصغر بين المجموعتين (يناسب وصف قصير مقابل وصف طويل)
function overlap_ratio($a, $b) {
    if (!$a || !$b) {
        return 0.0;
    }
    $common = count(array_intersect($a, $b));
    return $common / min(count($a), count($b));
}

function distance_km($lat1, $lon1, $lat2, $lon2) {
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) * sin($dLat / 2)
        + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) * sin($dLon / 2);
    return 6371 * 2 * atan2(sqrt($a), sqrt(1 - $a));
}

function score_pair($lost, $found) {
    $score = 20;   // نفس التصنيف

    if ($lost['loc_name'] !== '' && $lost['loc_name'] === $found['loc_name']) {
        $score += 20;
    } elseif ($lost['lat'] !== null && $lost['lng'] !== null && $found['lat'] !== null && $found['lng'] !== null) {
        $d = distance_km($lost['lat'], $lost['lng'], $found['lat'], $found['lng']);
        if ($d <= 0.5) {
            $score += 20;
        } elseif ($d <= 2) {
            $score += 10;
        }
    }

    $score += (int)round(overlap_ratio(tokens($lost['text']), tokens($found['text'])) * 50);

    $t1 = strtotime((string)$lost['date']);
    $t2 = strtotime((string)$found['date']);
    if ($t1 && $t2) {
        $days = abs($t2 - $t1) / 86400;
        if ($days <= 3) {
            $score += 10;
        } elseif ($days <= 14) {
            $score += 5;
        }
    }
    return min(100, $score);
}

function normalize_item($row) {
    return array(
        'id'          => isset($row['id']) ? (int)$row['id'] : 0,
        'user_id'     => (int)$row['user_id'],
        'category_id' => (int)$row['category_id'],
        'text'        => trim($row['item_name'] . ' ' . $row['description'] . ' ' . $row['color'] . ' ' . $row['brand']),
        'date'        => $row['item_date'],
        'loc_name'    => (string)$row['location_name'],
        'lat'         => ($row['latitude'] !== null && $row['latitude'] !== '') ? (float)$row['latitude'] : null,
        'lng'         => ($row['longitude'] !== null && $row['longitude'] !== '') ? (float)$row['longitude'] : null,
    );
}

function fetch_item($conn, $kind, $id) {
    if ($kind === 'lost') {
        $table = 'lost_items'; $idCol = 'lost_item_id'; $dateCol = 'lost_date';
    } else {
        $table = 'found_items'; $idCol = 'found_item_id'; $dateCol = 'found_date';
    }
    $sql = "SELECT i.$idCol AS id, i.user_id, i.category_id, i.item_name, i.description, i.color, i.brand, i.$dateCol AS item_date, l.location_name, l.latitude, l.longitude
            FROM $table i LEFT JOIN locations l ON l.location_id = i.location_id
            WHERE i.$idCol = ? LIMIT 1";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    return $row ? normalize_item($row) : null;
}

function create_match($conn, $lostId, $foundId, $score, $lostUserId) {
    $chk = $conn->prepare('SELECT match_id FROM matches WHERE lost_item_id = ? AND found_item_id = ? LIMIT 1');
    $chk->bind_param('ii', $lostId, $foundId);
    $chk->execute();
    $chk->store_result();
    $exists = $chk->num_rows > 0;
    $chk->close();
    if ($exists) {
        return false;
    }

    $status = 'pending';   // بانتظار تأكيد صاحب البلاغ
    $ins = $conn->prepare('INSERT INTO matches (lost_item_id, found_item_id, match_score, match_status, created_at) VALUES (?, ?, ?, ?, NOW())');
    $ins->bind_param('iids', $lostId, $foundId, $score, $status);
    $ins->execute();
    $matchId = (int)$ins->insert_id;
    $ins->close();

    $u1 = $conn->prepare("UPDATE lost_items SET status = 'matched' WHERE lost_item_id = ? AND status = 'searching'");
    $u1->bind_param('i', $lostId);
    $u1->execute();
    $u1->close();

    $u2 = $conn->prepare("UPDATE found_items SET status = 'matched' WHERE found_item_id = ? AND status = 'received'");
    $u2->bind_param('i', $foundId);
    $u2->execute();
    $u2->close();

    notify($conn, $lostUserId, msg('match.possible_title'),
        msg('match.possible_body', array('id' => $lostId)), 'match');
    return $matchId;
}

// عند تسجيل مفقود جديد: نبحث بين المعثورات
function run_matching_for_lost($conn, $lostId) {
    $lost = fetch_item($conn, 'lost', $lostId);
    if (!$lost) {
        return 0;
    }
    $sql = "SELECT i.found_item_id AS id, i.user_id, i.category_id, i.item_name, i.description, i.color, i.brand, i.found_date AS item_date, l.location_name, l.latitude, l.longitude
            FROM found_items i LEFT JOIN locations l ON l.location_id = i.location_id
            WHERE i.category_id = ? AND i.status IN ('received', 'matched')";
    $stmt = $conn->prepare($sql);
    $cat = $lost['category_id'];
    $stmt->bind_param('i', $cat);
    $stmt->execute();
    $res = $stmt->get_result();
    $cands = array();
    while ($row = $res->fetch_assoc()) {
        $found = normalize_item($row);
        if ($found['user_id'] === $lost['user_id']) {
            continue;
        }
        $score = score_pair($lost, $found);
        if ($score >= MATCH_THRESHOLD) {
            $cands[] = array($score, $found['id']);
        }
    }
    $stmt->close();

    rsort($cands);
    $created = 0;
    foreach (array_slice($cands, 0, 3) as $c) {
        if (create_match($conn, $lostId, $c[1], $c[0], $lost['user_id'])) {
            $created++;
        }
    }
    return $created;
}

// عند تسجيل معثور جديد: نبحث بين المفقودات اللي لسا تبحث
function run_matching_for_found($conn, $foundId) {
    $found = fetch_item($conn, 'found', $foundId);
    if (!$found) {
        return 0;
    }
    $sql = "SELECT i.lost_item_id AS id, i.user_id, i.category_id, i.item_name, i.description, i.color, i.brand, i.lost_date AS item_date, l.location_name, l.latitude, l.longitude
            FROM lost_items i LEFT JOIN locations l ON l.location_id = i.location_id
            WHERE i.category_id = ? AND i.status IN ('searching', 'matched')";  // a suggested match is not a confirmation: keep looking
    $stmt = $conn->prepare($sql);
    $cat = $found['category_id'];
    $stmt->bind_param('i', $cat);
    $stmt->execute();
    $res = $stmt->get_result();
    $cands = array();
    while ($row = $res->fetch_assoc()) {
        $lost = normalize_item($row);
        if ($lost['user_id'] === $found['user_id']) {
            continue;
        }
        $score = score_pair($lost, $found);
        if ($score >= MATCH_THRESHOLD) {
            $cands[] = array($score, $lost['id'], $lost['user_id']);
        }
    }
    $stmt->close();

    rsort($cands);
    $created = 0;
    foreach (array_slice($cands, 0, 3) as $c) {
        if (create_match($conn, $c[1], $foundId, $c[0], $c[2])) {
            $created++;
        }
    }
    return $created;
}
