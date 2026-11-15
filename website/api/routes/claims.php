<?php
/* ============================================================
   api/routes/claims.php — matches and claims for logged-in users.
   ============================================================ */

route('GET', '/matches', 'api_matches_list', 'user');
route('POST', '/matches/{id}/claim', 'api_match_claim', 'user');
route('POST', '/matches/{id}/reject', 'api_match_reject', 'user');
route('POST', '/items/found/{id}/claim', 'api_item_claim', 'user');
route('GET', '/claims/mine', 'api_claims_mine', 'user');

function api_matches_list($params, $actor)
{
    global $conn;
    api_ok(match_list_for_user($conn, $actor['id']));
}

function api_match_claim($params, $actor)
{
    global $conn;
    $res = match_claim(
        $conn,
        $actor['id'],
        (int)$params['id'],
        api_str('claim_description'),
        api_str('security_answer')
    );
    api_ok($res, 201);
}

function api_match_reject($params, $actor)
{
    global $conn;
    match_reject($conn, $actor['id'], (int)$params['id']);
    api_ok();
}

function api_item_claim($params, $actor)
{
    global $conn;
    $res = claim_found_item(
        $conn,
        $actor['id'],
        (int)$params['id'],
        api_str('claim_description'),
        api_str('security_answer')
    );
    api_ok($res, 201);
}

function api_claims_mine($params, $actor)
{
    global $conn;
    api_ok(claim_list_for_user($conn, $actor['id']));
}
