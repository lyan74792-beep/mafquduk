<?php
/* ============================================================
   api/core/auth.php — bearer tokens for the mobile app.

   The raw token is returned once at login; only its sha256 is stored
   (api_tokens.token_hash). An "actor" is:
     array('type' => 'user'|'admin', 'id' => int, 'token_hash' => string)
   ============================================================ */

define('API_TOKEN_DAYS', 30);

/** Create a token for a user/admin and return the raw value. */
function api_issue_token($conn, $ownerType, $ownerId)
{
    $raw = bin2hex(random_bytes(32));
    $hash = hash('sha256', $raw);
    $days = API_TOKEN_DAYS;
    // expiry computed by the database, so PHP and MySQL clocks can't disagree
    $stmt = $conn->prepare('INSERT INTO api_tokens (owner_type, owner_id, token_hash, expires_at) VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))');
    $stmt->bind_param('sisi', $ownerType, $ownerId, $hash, $days);
    $stmt->execute();
    $stmt->close();
    return $raw;
}

function api_revoke_token($conn, $tokenHash)
{
    $stmt = $conn->prepare('DELETE FROM api_tokens WHERE token_hash = ?');
    $stmt->bind_param('s', $tokenHash);
    $stmt->execute();
    $stmt->close();
}

/** Raw bearer token from the request, or ''. */
function api_bearer_token()
{
    $h = '';
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $h = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $h = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    } elseif (function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strcasecmp($k, 'Authorization') === 0) {
                $h = $v;
            }
        }
    }
    return preg_match('/^Bearer\s+([a-f0-9]{64})$/i', trim($h), $m) ? strtolower($m[1]) : '';
}

/** Actor for the sent token, or null if none/invalid/expired. */
function api_current_actor($conn)
{
    $raw = api_bearer_token();
    if ($raw === '') {
        return null;
    }
    $hash = hash('sha256', $raw);
    $stmt = $conn->prepare('SELECT owner_type, owner_id FROM api_tokens WHERE token_hash = ? AND expires_at > NOW() LIMIT 1');
    $stmt->bind_param('s', $hash);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if (!$row) {
        return null;
    }
    $up = $conn->prepare('UPDATE api_tokens SET last_used_at = NOW() WHERE token_hash = ?');
    $up->bind_param('s', $hash);
    $up->execute();
    $up->close();
    return array('type' => $row['owner_type'], 'id' => (int)$row['owner_id'], 'token_hash' => $hash);
}

/** Enforce a route's access level; returns the actor (or null for public routes). */
function api_authorize($conn, $access)
{
    if ($access === 'public') {
        return null;
    }
    $actor = api_current_actor($conn);
    if ($access === 'optional') {
        return $actor;
    }
    if ($actor === null) {
        api_error(401, 'unauthorized', msg('api.login_required'));
    }
    if (($access === 'user' || $access === 'admin') && $actor['type'] !== $access) {
        api_error(403, 'forbidden', msg('api.forbidden'));
    }
    return $actor;
}
