<?php
/* ============================================================
   tools/demo_data.php — fill the database with realistic demo data for
   presentations (accounts, reports, matches, claims, shipping, emergencies).

   Everything is created through the shared services, so automatic matching,
   notifications and statuses happen exactly as in real use.

   Usage (from the website folder):
     C:\xampp\php\php.exe tools\demo_data.php            add demo data
     C:\xampp\php\php.exe tools\demo_data.php --reset    DELETE ALL DATA first, then add demo data

   Command line only. Demo accounts are listed at the end of the run and in
   docs/PRESENTATION_GUIDE.md.
   ============================================================ */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

define('DB_NO_AUTOCONNECT', true);
require __DIR__ . '/../db.php';
require __DIR__ . '/../lib/bootstrap.php';

$conn = db_connect();
$reset = in_array('--reset', $argv, true);

/* ---------- helpers ---------- */

function demo_days_ago($n)
{
    return date('Y-m-d', strtotime("-$n days"));
}

function demo_user($conn, $name, $email, $password, $phone)
{
    $existing = db_one($conn, 'SELECT user_id FROM users WHERE email = ?', 's', array($email));
    if ($existing) {
        return (int)$existing['user_id'];
    }
    $user = account_register_user($conn, array(
        'full_name' => $name, 'email' => $email, 'password' => $password, 'confirm_password' => $password,
    ));
    account_update_profile($conn, $user['user_id'], array('full_name' => $name, 'phone' => $phone, 'nationality' => 'SA'));
    return (int)$user['user_id'];
}

function demo_lost($conn, $userId, $category, $landmark, $daysAgo, $description, $phone)
{
    $r = report_create_lost($conn, $userId, array(
        'item_category' => $category, 'lost_location' => $landmark, 'lost_date' => demo_days_ago($daysAgo),
        'item_description' => $description, 'reporter_phone' => $phone,
    ), 'no_upload');
    return (int)$r['id'];
}

function demo_found($conn, $userId, $category, $landmark, $daysAgo, $description, $phone, $statusIndex = 0, $question = '', $answer = '', $sighting = false)
{
    $statuses = lookup_found_current_statuses();
    $r = report_create_found($conn, $userId, array(
        'item_category' => $category, 'found_location' => $landmark, 'found_date' => demo_days_ago($daysAgo),
        'item_description' => $description, 'finder_phone' => $phone,
        'current_status' => $sighting ? lookup_sighting_status() : $statuses[$statusIndex],
        'report_kind' => $sighting ? 'sighting' : 'found',
        'security_question' => $question, 'security_answer' => $answer,
    ), 'no_upload');
    return (int)$r['id'];
}

/** The pending match between a lost and a found report (created automatically by the matching engine). */
function demo_match_id($conn, $lostId, $foundId)
{
    $m = db_one($conn, 'SELECT match_id FROM matches WHERE lost_item_id = ? AND found_item_id = ?', 'ii', array($lostId, $foundId));
    if ($m) {
        return (int)$m['match_id'];
    }
    // Matching suggests the closest candidates only; make sure the demo pair is linked.
    $r = admin_manual_match($conn, $lostId, $foundId);
    return (int)$r['match_id'];
}

/* ---------- 1. optional reset ---------- */

if ($reset) {
    echo "Deleting all data...\n";
    $conn->query('SET FOREIGN_KEY_CHECKS = 0');
    foreach (array('api_tokens', 'otp_codes', 'shipping_requests', 'claims', 'matches', 'item_images',
                   'security_questions', 'notifications', 'emergency_reports', 'lost_items', 'found_items',
                   'locations', 'categories', 'users', 'admins') as $table) {
        $conn->query("TRUNCATE TABLE `$table`");
    }
    $conn->query('SET FOREIGN_KEY_CHECKS = 1');
    $conn->query('UPDATE system_stats SET total_lost = 0, total_found = 0, pending_reports = 0, total_matches = 0');
    foreach (glob(__DIR__ . '/../assets/uploads/*') as $file) {
        if (is_file($file) && basename($file) !== '.htaccess') {
            unlink($file);
        }
    }
}

/* ---------- 2. accounts ---------- */

$password = 'Demo@12345';
$adminPassword = 'Admin@12345';
$ahmed  = demo_user($conn, 'أحمد العتيبي', 'ahmed@mafqoodak.sa', $password, '0551000001');
$sara   = demo_user($conn, 'سارة القحطاني', 'sara@mafqoodak.sa', $password, '0551000002');
$khalid = demo_user($conn, 'خالد الحربي', 'khalid@mafqoodak.sa', $password, '0551000003');

if (!db_one($conn, 'SELECT admin_id FROM admins WHERE email = ?', 's', array('admin@mafqoodak.sa'))) {
    db_exec($conn, "INSERT INTO admins (full_name, email, password_hash, role, created_at) VALUES (?, ?, ?, 'admin', NOW())",
        'sss', array('مشرف المنصة', 'admin@mafqoodak.sa', password_hash($adminPassword, PASSWORD_DEFAULT)));
}
if (!db_one($conn, 'SELECT admin_id FROM admins WHERE email = ?', 's', array('noura@mafqoodak.sa'))) {
    account_register_admin($conn, array('full_name' => 'نورة الشهري', 'email' => 'noura@mafqoodak.sa',
        'password' => $adminPassword, 'confirm_password' => $adminPassword));   // stays pending → approve it live
}

$cat = lookup_categories();          // [documents, electronics, bags, jewellery, other]
$lm = array_keys(landmarks_map());   // landmarks in config order

/* ---------- 3. stories ---------- */

// A. Fresh suggested match → Ahmed can press "this is mine" during the demo.
$walletLost = demo_lost($conn, $ahmed, $cat[2], $lm[1], 2,
    'محفظة جلدية سوداء فيها بطاقة هوية وبطاقات بنكية وصورة عائلية', '0551000001');
$walletFound = demo_found($conn, $khalid, $cat[2], $lm[1], 1,
    'محفظة جلدية سوداء فيها بطاقات وصورة عائلية وجدتها قرب الباب', '0551000003', 0,
    'ما الاسم المكتوب على البطاقة البنكية؟', 'أحمد');
demo_match_id($conn, $walletLost, $walletFound);

// B. Claim waiting for the administrator (ownership verification with security answers).
$passportLost = demo_lost($conn, $sara, $cat[0], $lm[2], 3,
    'جواز سفر سعودي أخضر داخل غلاف جلدي بني', '0551000002');
$passportFound = demo_found($conn, $khalid, $cat[0], $lm[2], 2,
    'جواز سفر سعودي أخضر في غلاف جلدي بني اللون', '0551000003', 1,
    'ما لون الغلاف؟', 'بني');
match_claim($conn, $sara, demo_match_id($conn, $passportLost, $passportFound),
    'جواز سفري باسم سارة، وفي الغلاف بطاقة صعود الطائرة', 'بني');

// C. Approved claim with a delivery request → admin updates the shipping status.
$phoneLost = demo_lost($conn, $ahmed, $cat[1], $lm[4], 4,
    'جوال آيفون أسود بغطاء أحمر وعليه ملصق علم السعودية', '0551000001');
$phoneFound = demo_found($conn, $sara, $cat[1], $lm[4], 3,
    'جوال آيفون أسود بغطاء أحمر عليه ملصق', '0551000002', 0,
    'ما الملصق الموجود على الغطاء؟', 'علم السعودية');
$c = match_claim($conn, $ahmed, demo_match_id($conn, $phoneLost, $phoneFound),
    'جوالي آيفون أسود بغطاء أحمر، خلفيته صورة الكعبة', 'علم السعودية');
claim_approve($conn, $c['claim_id']);
shipping_create($conn, $ahmed, array('claim_id' => $c['claim_id'], 'city' => 'الرياض',
    'address' => 'حي النرجس، شارع الأمير محمد بن سلمان، مبنى 12', 'phone' => '0551000001',
    'notes' => 'التوصيل بعد العصر'));

// D. Completed case (delivered) — shows the full history.
$watchLost = demo_lost($conn, $sara, $cat[3], $lm[6], 8,
    'ساعة يد ذهبية نسائية بسوار معدني', '0551000002');
$watchFound = demo_found($conn, $khalid, $cat[3], $lm[6], 7,
    'ساعة يد ذهبية نسائية سوارها معدني', '0551000003', 1);
$c = match_claim($conn, $sara, demo_match_id($conn, $watchLost, $watchFound),
    'ساعتي الذهبية، مكتوب خلفها تاريخ زواجي');
claim_approve($conn, $c['claim_id']);
claim_deliver($conn, $c['claim_id']);

// E. Found items still waiting for an owner (browse + map).
demo_found($conn, $khalid, $cat[2], $lm[5], 1, 'حقيبة ظهر رمادية فيها سجادة صلاة ومصحف صغير', '0551000003', 0);
demo_found($conn, $sara, $cat[4], $lm[0], 0, 'مسبحة كهرمان مع علبة خشبية', '0551000002', 1);

// F. Sighting: seen but left in place.
demo_found($conn, $sara, $cat[2], $lm[5], 0, 'حقيبة سفر زرقاء متروكة بجانب العمود رقم 12', '0551000002', 0, '', '', true);

// G. Lost reports still searching.
demo_lost($conn, $khalid, $cat[1], $lm[7], 1, 'سماعات لاسلكية بيضاء في علبة شحن', '0551000003');
demo_lost($conn, $sara, $cat[0], $lm[3], 0, 'بطاقة تصريح الحج باسم سارة القحطاني', '0551000002');

// H. Cancelled report (owner found it).
$umbrella = demo_lost($conn, $ahmed, $cat[4], $lm[0], 5, 'مظلة سوداء كبيرة قابلة للطي', '0551000001');
$reasons = lookup_cancel_reasons();
report_cancel_lost($conn, $ahmed, $umbrella, $reasons[0], 'وجدتها في الفندق');

// I. Missing persons: one active (guest), one resolved.
report_create_emergency($conn, null, array(
    'person_name' => 'عبدالله (7 سنوات)', 'approx_age' => '7', 'last_seen_location' => $lm[1],
    'clothing_description' => 'ثوب أبيض وطاقية بيضاء، يحمل حقيبة صغيرة زرقاء', 'reporter_phone' => '0559000001',
), 'no_upload');
$resolved = report_create_emergency($conn, $sara, array(
    'person_name' => 'الحاجة فاطمة', 'approx_age' => '70', 'last_seen_location' => $lm[4],
    'clothing_description' => 'عباءة سوداء وحجاب رمادي، تستخدم عصا', 'reporter_phone' => '0551000002',
), 'no_upload');
$adminId = (int)db_one($conn, 'SELECT admin_id FROM admins WHERE email = ?', 's', array('admin@mafqoodak.sa'))['admin_id'];
admin_resolve_emergency($conn, $adminId, $resolved['id']);

admin_stats($conn);   // refresh the statistics snapshot

/* ---------- 4. summary ---------- */

$count = function ($table) use ($conn) {
    return (int)db_one($conn, "SELECT COUNT(*) AS n FROM `$table`")['n'];
};
echo "Demo data ready:\n";
foreach (array('users', 'admins', 'lost_items', 'found_items', 'matches', 'claims', 'shipping_requests', 'emergency_reports', 'notifications') as $t) {
    printf("  %-18s %d\n", $t, $count($t));
}
echo "\nAccounts (password for visitors: $password, for admins: $adminPassword):\n";
echo "  visitor  ahmed@mafqoodak.sa   (has a fresh suggested match + an approved claim with delivery)\n";
echo "  visitor  sara@mafqoodak.sa    (has a claim waiting for verification)\n";
echo "  visitor  khalid@mafqoodak.sa  (found several items)\n";
echo "  admin    admin@mafqoodak.sa\n";
echo "  pending  noura@mafqoodak.sa   (admin sign-up waiting for approval)\n";
