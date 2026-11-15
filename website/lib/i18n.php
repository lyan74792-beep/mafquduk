<?php
/* ============================================================
   lib/i18n.php — user-facing messages come from website/lang/<code>.php,
   never from string literals in the code.

     msg('auth.invalid_credentials')
     msg('report.created', array('id' => 12))   // "{id}" placeholders

   Language: the API sets it from the Accept-Language header (the app sends
   its current language); web pages use the language the visitor picked
   (cookie "mafqodak_lang", see auth.php). Missing keys fall back to
   Arabic, then to the key itself.
   ============================================================ */

// Load with require_once. (A function_exists() guard can't work here: PHP
// declares this file's functions before running its first line.)
if (!defined('I18N_DEFAULT')) {
    define('I18N_DEFAULT', 'ar');
}

/** Get or set the current message language ('ar', 'en', …). */
function app_lang($set = null)
{
    static $lang = null;
    if ($lang === null) {
        // Web pages: the visitor's choice (cookie, see auth.php). API: Accept-Language.
        $lang = defined('I18N_WEB_LANG') ? I18N_WEB_LANG : I18N_DEFAULT;
    }
    if ($set !== null) {
        $code = strtolower(substr((string)$set, 0, 2));
        if (is_file(__DIR__ . '/../lang/' . $code . '.php')) {
            $lang = $code;
        }
    }
    return $lang;
}

/**
 * Pick the first supported language from an Accept-Language header.
 * A language without a catalogue gets English.
 */
function app_lang_from_header($header)
{
    $header = trim((string)$header);
    if ($header === '') {
        return app_lang();
    }
    foreach (explode(',', $header) as $part) {
        $code = strtolower(substr(trim($part), 0, 2));
        if ($code !== '' && is_file(__DIR__ . '/../lang/' . $code . '.php')) {
            return app_lang($code);
        }
    }
    return app_lang('en');
}

/** @return array<string,string> */
function i18n_catalog($lang)
{
    static $cache = array();
    if (!isset($cache[$lang])) {
        $file = __DIR__ . '/../lang/' . $lang . '.php';
        $cache[$lang] = is_file($file) ? require $file : array();
    }
    return $cache[$lang];
}

/** Translated message for $key with {placeholders} replaced from $params. */
function msg($key, array $params = array())
{
    $cat = i18n_catalog(app_lang());
    if (isset($cat[$key])) {
        $text = $cat[$key];
    } else {
        $fallback = i18n_catalog(I18N_DEFAULT);
        $text = isset($fallback[$key]) ? $fallback[$key] : $key;
    }
    foreach ($params as $name => $value) {
        $text = str_replace('{' . $name . '}', (string)$value, $text);
    }
    return $text;
}
