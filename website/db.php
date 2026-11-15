<?php
/* ============================================================
   db.php — ملف الاتصال بقاعدة البيانات (تستدعيه كل الصفحات)
   عدّلي القيم أدناه فقط. كلمة المرور اكتبيها هنا ولا ترسليها بمحادثة.
   ============================================================ */

$DB_HOST = 'localhost';
$DB_PORT = 3306;
$DB_NAME = 'mafqoodak1';
$DB_USER = 'root';
$DB_PASS = '';

// توقيت مكة لكل التواريخ التي تنشئها PHP (مثل date('c'))
date_default_timezone_set('Asia/Riyadh');

// true أثناء التطوير: يعرض سبب الخطأ التقني مع الرسالة. اجعليها false عند التسليم.
if (!defined('APP_DEBUG')) { define('APP_DEBUG', true); }

function db_connect() {
    global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME, $DB_PORT;
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    $c = mysqli_init();
    $c->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);   // لا تتعلّق الصفحة لو العنوان خطأ
    $c->real_connect($DB_HOST, $DB_USER, $DB_PASS, $DB_NAME, $DB_PORT);
    $c->set_charset('utf8mb4');
    return $c;
}

// اتصال تلقائي لباقي الصفحات (test_db.php وtrack_status.php يوقفانه ليتعاملا مع الخطأ بنفسيهما)
if (!defined('DB_NO_AUTOCONNECT')) {
    try {
        $conn = db_connect();
    } catch (mysqli_sql_exception $e) {
        http_response_code(500);
        die('تعذّر الاتصال بقاعدة البيانات. تأكدي من تشغيل MySQL ومن بيانات الاتصال في db.php'
            . (APP_DEBUG ? ' [' . htmlspecialchars($e->getMessage()) . ']' : ''));
    }
}