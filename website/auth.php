<?php
/* auth.php — الجلسة وحماية الصفحات ورسائل التنبيه */

// توقيت مكة لكل الصفحات (حتى التي لا تتصل بقاعدة البيانات)
date_default_timezone_set('Asia/Riyadh');
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function e($s) {
    return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8');
}

// Website language: the language menu (assets/js/app.js) saves it in the
// "mafqodak_lang" cookie, so server messages (msg()) follow the page language.
if (!defined('I18N_WEB_LANG') && isset($_COOKIE['mafqodak_lang'])
    && in_array($_COOKIE['mafqodak_lang'], array('ar', 'en', 'tr', 'ur'), true)) {
    define('I18N_WEB_LANG', $_COOKIE['mafqodak_lang']);
}

/**
 * A lookup value stored in Arabic (category, landmark, item status, cancel
 * reason), wrapped so app.js shows it in the page language
 * (assets/i18n/values.js). Empty values show a dash.
 */
function lv($s) {
    $s = trim((string)$s);
    if ($s === '') {
        return '—';
    }
    return '<span data-i18n-value="' . e($s) . '">' . e($s) . '</span>';
}

function redirect($url) {
    header('Location: ' . $url);
    exit;
}

function flash($msg) {
    $_SESSION['flash'] = $msg;
}

function flash_ok($msg) {
    $_SESSION['flash_ok'] = $msg;
}

// تعرض رسائل الخطأ/النجاح المخزنة مرة واحدة ثم تمسحها
function render_flash() {
    if (!empty($_SESSION['flash'])) {
        echo '<div class="alert alert-danger small" role="alert">' . e($_SESSION['flash']) . '</div>';
        unset($_SESSION['flash']);
    }
    if (!empty($_SESSION['flash_ok'])) {
        echo '<div class="alert alert-success small" role="alert">' . e($_SESSION['flash_ok']) . '</div>';
        unset($_SESSION['flash_ok']);
    }
}

function is_logged_in() {
    return !empty($_SESSION['uid']) && !empty($_SESSION['role']);
}

// تحمي الصفحة: لازم دخول، ولو حُدد دور ('user' أو 'admin') لازم يطابق
function require_login($role = null) {
    if (!is_logged_in()) {
        $_SESSION['after_login'] = basename(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));
        redirect('login.php' . ($role === 'admin' ? '?role=admin' : ''));
    }
    if ($role !== null && $_SESSION['role'] !== $role) {
        redirect($_SESSION['role'] === 'admin' ? 'admin_dashboard.php' : 'user_dashboard.php');
    }
}
