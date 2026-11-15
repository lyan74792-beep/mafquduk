<?php
/* ============================================================
   api/core/http.php — request input and JSON responses.
   ============================================================ */

/** Send {"ok":true,"data":...} and stop. */
function api_ok($data = array(), $status = 200)
{
    $data = api_absolute_images($data);
    api_send($status, array('ok' => true, 'data' => $data ? $data : new stdClass()));
}

/** Send {"ok":false,"error":{...}} and stop. */
function api_error($status, $code, $message, array $fields = array())
{
    $error = array('code' => $code, 'message' => $message);
    if ($fields) {
        $error['fields'] = $fields;
    }
    api_send($status, array('ok' => false, 'error' => $error));
}

function api_send($status, array $body)
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * Request body as an array: JSON body, or form fields for multipart requests.
 * Cached, so it is safe to call many times.
 */
function api_input()
{
    static $input = null;
    if ($input !== null) {
        return $input;
    }
    $type = isset($_SERVER['CONTENT_TYPE']) ? strtolower($_SERVER['CONTENT_TYPE']) : '';
    if (strpos($type, 'application/json') !== false) {
        $raw = file_get_contents('php://input');
        $decoded = ($raw === '' || $raw === false) ? array() : json_decode($raw, true);
        if (!is_array($decoded)) {
            api_error(400, 'bad_request', msg('api.bad_json'));
        }
        $input = $decoded;
    } else {
        $input = $_POST;
    }
    return $input;
}

/** One trimmed string field from the request body ('' when missing). */
function api_str($key, $default = '')
{
    $in = api_input();
    if (!isset($in[$key]) || is_array($in[$key])) {
        return $default;
    }
    return trim((string)$in[$key]);
}

/** One query-string parameter. */
function api_query($key, $default = '')
{
    return isset($_GET[$key]) && !is_array($_GET[$key]) ? trim((string)$_GET[$key]) : $default;
}

/**
 * Walk a response and make every image path absolute
 * (keys image_url, photo_url, and the list "images").
 */
function api_absolute_images($data)
{
    if (!is_array($data)) {
        return $data;
    }
    foreach ($data as $k => $v) {
        if (($k === 'image_url' || $k === 'photo_url') && is_string($v)) {
            $data[$k] = api_public_url($v);
        } elseif ($k === 'images' && is_array($v)) {
            $data[$k] = array_map('api_public_url', $v);
        } elseif (is_array($v)) {
            $data[$k] = api_absolute_images($v);
        }
    }
    return $data;
}

/** Absolute URL for a path relative to the website root, e.g. assets/uploads/x.jpg. */
function api_public_url($relative)
{
    if ($relative === null || $relative === '') {
        return null;
    }
    if (preg_match('#^https?://#i', $relative)) {
        return $relative;
    }
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'localhost';
    // website root = folder that contains /api
    $root = rtrim(str_replace('\\', '/', dirname(dirname($_SERVER['SCRIPT_NAME']))), '/');
    return $scheme . '://' . $host . $root . '/' . ltrim($relative, '/');
}
