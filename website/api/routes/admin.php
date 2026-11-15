<?php
/* ============================================================
   api/routes/admin.php — admin endpoints (see docs/API.md).
   ============================================================ */

route('GET', '/admin/stats', 'api_admin_stats', 'admin');
route('GET', '/admin/emergencies', 'api_admin_emergencies', 'admin');
route('POST', '/admin/emergencies/{id}/resolve', 'api_admin_resolve_emergency', 'admin');
route('GET', '/admin/reports', 'api_admin_reports', 'admin');
route('GET', '/admin/open-items', 'api_admin_open_items', 'admin');
route('POST', '/admin/matches', 'api_admin_manual_match', 'admin');
route('GET', '/admin/claims', 'api_admin_claims', 'admin');
route('POST', '/admin/claims/{id}/approve', 'api_admin_claim_approve', 'admin');
route('POST', '/admin/claims/{id}/reject', 'api_admin_claim_reject', 'admin');
route('POST', '/admin/claims/{id}/deliver', 'api_admin_claim_deliver', 'admin');
route('GET', '/admin/shipping', 'api_admin_shipping_list', 'admin');
route('POST', '/admin/shipping/{id}', 'api_admin_shipping_update', 'admin');
route('GET', '/admin/admins/pending', 'api_admin_pending_admins', 'admin');
route('POST', '/admin/admins/{id}/approve', 'api_admin_approve_admin', 'admin');
route('POST', '/admin/admins/{id}/reject', 'api_admin_reject_admin', 'admin');

function api_admin_stats()
{
    global $conn;
    api_ok(admin_stats($conn));
}

function api_admin_emergencies()
{
    global $conn;
    api_ok(admin_emergencies($conn, api_query('status', 'active')));
}

function api_admin_resolve_emergency($params, $actor)
{
    global $conn;
    admin_resolve_emergency($conn, $actor['id'], (int)$params['id']);
    api_ok();
}

function api_admin_reports()
{
    global $conn;
    api_ok(admin_reports($conn, api_query('type', 'all'), api_query('status', '')));
}

function api_admin_open_items()
{
    global $conn;
    api_ok(admin_open_items($conn));
}

function api_admin_manual_match()
{
    global $conn;
    $res = admin_manual_match($conn, (int)api_str('lost_item_id'), (int)api_str('found_item_id'));
    api_ok($res, 201);
}

function api_admin_claims()
{
    global $conn;
    api_ok(claim_admin_list($conn, api_query('status', 'Under Review')));
}

function api_admin_claim_approve($params)
{
    global $conn;
    claim_approve($conn, (int)$params['id']);
    api_ok();
}

function api_admin_claim_reject($params)
{
    global $conn;
    claim_reject($conn, (int)$params['id'], api_str('reason'));
    api_ok();
}

function api_admin_claim_deliver($params)
{
    global $conn;
    claim_deliver($conn, (int)$params['id']);
    api_ok();
}

function api_admin_shipping_list()
{
    global $conn;
    api_ok(shipping_list_all($conn, api_query('status', '')));
}

function api_admin_shipping_update($params)
{
    global $conn;
    shipping_update($conn, (int)$params['id'], api_input());
    api_ok();
}

function api_admin_pending_admins()
{
    global $conn;
    api_ok(admin_pending_admins($conn));
}

function api_admin_approve_admin($params)
{
    global $conn;
    admin_approve_admin($conn, (int)$params['id']);
    api_ok();
}

function api_admin_reject_admin($params)
{
    global $conn;
    admin_reject_admin($conn, (int)$params['id']);
    api_ok();
}
