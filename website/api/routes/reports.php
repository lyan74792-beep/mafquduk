<?php
/* ============================================================
   api/routes/reports.php — lost, found, emergency reports & tracking.
   ============================================================ */

route('POST', '/reports/lost', 'api_report_lost', 'user');
route('POST', '/reports/found', 'api_report_found', 'user');
route('GET', '/reports/mine', 'api_reports_mine', 'user');
route('POST', '/reports/lost/{id}/cancel', 'api_report_cancel_lost', 'user');
route('GET', '/track/{id}', 'api_track_report', 'public');
route('POST', '/emergencies', 'api_report_emergency', 'optional');

function api_report_lost($params, $actor)
{
    global $conn;
    api_ok(report_create_lost($conn, $actor['id'], api_input(), 'image'), 201);
}

function api_report_found($params, $actor)
{
    global $conn;
    api_ok(report_create_found($conn, $actor['id'], api_input(), 'image'), 201);
}

function api_reports_mine($params, $actor)
{
    global $conn;
    api_ok(report_mine($conn, $actor['id']));
}

function api_report_cancel_lost($params, $actor)
{
    global $conn;
    report_cancel_lost($conn, $actor['id'], (int)$params['id'], api_str('reason'), api_str('details'));
    api_ok();
}

function api_track_report($params)
{
    global $conn;
    api_ok(report_track($conn, (int)$params['id']));
}

function api_report_emergency($params, $actor)
{
    global $conn;
    $userId = ($actor && $actor['type'] === 'user') ? $actor['id'] : null;
    api_ok(report_create_emergency($conn, $userId, api_input(), 'photo'), 201);
}
