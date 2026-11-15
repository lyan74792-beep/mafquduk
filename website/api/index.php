<?php
/* ============================================================
   api/index.php — entry point for /api/v1/... (see docs/API.md)
   ============================================================ */

// CORS: the Flutter web build and other origins may call the API.
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

define('DB_NO_AUTOCONNECT', true);   // db.php must not print HTML errors here
require __DIR__ . '/../db.php';
require __DIR__ . '/../lib/bootstrap.php';   // helpers, errors, messages, services
require __DIR__ . '/core/http.php';
require __DIR__ . '/core/router.php';
require __DIR__ . '/core/auth.php';

foreach (glob(__DIR__ . '/routes/*.php') as $file) {
    require_once $file;
}

// Messages in the caller's language (the app sends Accept-Language: ar|en|tr|ur).
app_lang_from_header(isset($_SERVER['HTTP_ACCEPT_LANGUAGE']) ? $_SERVER['HTTP_ACCEPT_LANGUAGE'] : '');

try {
    $conn = db_connect();
} catch (mysqli_sql_exception $e) {
    api_error(503, 'db_unavailable', msg('api.db_unavailable') . (APP_DEBUG ? ' [' . $e->getMessage() . ']' : ''));
}
$GLOBALS['conn'] = $conn;

try {
    api_dispatch($conn);
} catch (NotFoundError $e) {
    api_error(404, 'not_found', $e->getMessage());
} catch (ConflictError $e) {
    api_error(409, 'conflict', $e->getMessage());
} catch (AuthError $e) {
    api_error(401, 'unauthorized', $e->getMessage());
} catch (ForbiddenError $e) {
    api_error(403, 'forbidden', $e->getMessage());
} catch (UserError $e) {
    api_error(422, 'validation', $e->getMessage(), $e->fields);
} catch (Throwable $e) {
    error_log('API error: ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    api_error(500, 'server_error', msg('api.unexpected') . (APP_DEBUG ? ' [' . $e->getMessage() . ']' : ''));
}
