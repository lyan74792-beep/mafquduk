<?php
/* ============================================================
   lib/services/lookup_service.php — option lists shared by the website
   forms and the app (docs/API.md "GET /lookups"). The values themselves
   live in config/lookups.php.
   ============================================================ */

/** The whole config/lookups.php array (loaded once). */
function lookup_config()
{
    static $config = null;
    if ($config === null) {
        $config = require __DIR__ . '/../../config/lookups.php';
    }
    return $config;
}

function lookup_other()
{
    return lookup_config()['other'];
}

function lookup_sighting_status()
{
    return lookup_config()['sighting_status'];
}

function lookup_categories()
{
    return lookup_config()['categories'];
}

/** Landmarks with approximate coordinates; the last entry is "other" (free text). */
function lookup_landmarks()
{
    $out = array();
    foreach (landmarks_map() as $name => $coords) {
        $out[] = array('name' => $name, 'lat' => $coords[0], 'lng' => $coords[1]);
    }
    $out[] = array('name' => lookup_other(), 'lat' => null, 'lng' => null);
    return $out;
}

/** Where a found item is now. The sighting entry marks a sighting report. */
function lookup_found_current_statuses()
{
    return lookup_config()['found_current_statuses'];
}

function lookup_cancel_reasons()
{
    return lookup_config()['cancel_reasons'];
}

function lookup_all()
{
    return array(
        'categories' => lookup_categories(),
        'landmarks' => lookup_landmarks(),
        'found_current_statuses' => lookup_found_current_statuses(),
        'cancel_reasons' => lookup_cancel_reasons(),
        'otp_dev_mode' => otp_dev_mode(),
    );
}

/* Backwards-compatible constants used by older code. */
if (!defined('OTHER_OPTION')) {
    define('OTHER_OPTION', lookup_other());
}
if (!defined('SIGHTING_STATUS')) {
    define('SIGHTING_STATUS', lookup_sighting_status());
}
