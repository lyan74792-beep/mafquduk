<?php
/* ============================================================
   api/routes/account.php — health, lookups, auth, profile.
   Route handlers stay thin: read input → call a service → api_ok().
   ============================================================ */

route('GET', '/health', 'api_health');
route('GET', '/lookups', 'api_lookups');
route('POST', '/auth/register', 'api_register');
route('POST', '/auth/register-admin', 'api_register_admin');
route('POST', '/auth/login', 'api_login');
route('POST', '/auth/otp/request', 'api_otp_request');
route('POST', '/auth/otp/verify', 'api_otp_verify');
route('POST', '/auth/logout', 'api_logout', 'auth');
route('GET', '/me', 'api_me', 'auth');
route('PUT', '/me', 'api_update_me', 'user');
route('POST', '/me/password', 'api_change_password', 'user');

function api_health()
{
    api_ok(array('status' => 'ok', 'time' => date('c')));
}

function api_lookups()
{
    api_ok(lookup_all());
}

function api_register()
{
    global $conn;
    $user = account_register_user($conn, api_input());
    $token = api_issue_token($conn, 'user', $user['user_id']);
    api_ok(array('token' => $token, 'role' => 'user', 'user' => $user), 201);
}

function api_register_admin()
{
    global $conn;
    api_ok(account_register_admin($conn, api_input()), 201);
}

function api_login()
{
    global $conn;
    $type = api_str('account_type') === 'admin' ? 'admin' : 'user';
    $result = account_login($conn, api_str('email'), api_str('password'), $type);
    $id = $type === 'admin' ? $result['admin']['admin_id'] : $result['user']['user_id'];
    $result['token'] = api_issue_token($conn, $type, $id);
    api_ok($result);
}

function api_otp_request()
{
    global $conn;
    $otp = account_otp_request($conn, api_str('phone'));
    $data = array('sent' => true, 'expires_in' => $otp['expires_in']);
    if (otp_dev_mode()) {
        $data['debug_code'] = $otp['code'];   // no SMS provider yet: show the code
    }
    api_ok($data);
}

function api_otp_verify()
{
    global $conn;
    $user = account_otp_verify($conn, api_str('phone'), api_str('code'));
    $token = api_issue_token($conn, 'user', $user['user_id']);
    api_ok(array('token' => $token, 'role' => 'user', 'user' => $user));
}

function api_logout($params, $actor)
{
    global $conn;
    api_revoke_token($conn, $actor['token_hash']);
    api_ok();
}

function api_me($params, $actor)
{
    global $conn;
    if ($actor['type'] === 'admin') {
        api_ok(array('role' => 'admin', 'admin' => account_admin($conn, $actor['id'])));
    }
    api_ok(array('role' => 'user', 'user' => account_user($conn, $actor['id'])));
}

function api_update_me($params, $actor)
{
    global $conn;
    api_ok(array('user' => account_update_profile($conn, $actor['id'], api_input())));
}

function api_change_password($params, $actor)
{
    global $conn;
    account_change_password($conn, $actor['id'], api_str('current_password'), api_str('new_password'));
    api_ok();
}
