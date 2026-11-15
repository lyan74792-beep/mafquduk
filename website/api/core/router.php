<?php
/* ============================================================
   api/core/router.php — minimal path router.

   route('GET', '/items/{type}/{id}', 'handler_fn', 'public');
   Access levels: 'public' | 'optional' (token used if sent) | 'auth' (user or admin)
                  | 'user' | 'admin'
   Handlers receive (array $params, array|null $actor).
   ============================================================ */

$GLOBALS['API_ROUTES'] = array();

function route($method, $pattern, $handler, $access = 'public')
{
    $regex = '#^' . preg_replace('#\{([a-z_]+)\}#', '(?P<$1>[^/]+)', rtrim($pattern, '/')) . '/?$#';
    $GLOBALS['API_ROUTES'][] = array(
        'method' => strtoupper($method),
        'regex' => $regex,
        'handler' => $handler,
        'access' => $access,
    );
}

/** Path after ".../api/v1", e.g. "/items/found/3". */
function api_request_path()
{
    $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $uri = rawurldecode($uri);
    $pos = strpos($uri, '/api/v1');
    if ($pos === false) {
        return null;
    }
    $path = substr($uri, $pos + strlen('/api/v1'));
    return $path === '' ? '/' : $path;
}

function api_dispatch($conn)
{
    $path = api_request_path();
    if ($path === null) {
        api_error(404, 'not_found', msg('api.use_v1'));
    }
    $method = $_SERVER['REQUEST_METHOD'];
    $methodMismatch = false;

    foreach ($GLOBALS['API_ROUTES'] as $r) {
        if (!preg_match($r['regex'], $path, $m)) {
            continue;
        }
        if ($r['method'] !== $method) {
            $methodMismatch = true;
            continue;
        }
        $params = array();
        foreach ($m as $k => $v) {
            if (is_string($k)) {
                $params[$k] = $v;
            }
        }
        $actor = api_authorize($conn, $r['access']);
        call_user_func($r['handler'], $params, $actor);
        api_ok(); // handler forgot to respond
    }

    if ($methodMismatch) {
        api_error(405, 'method_not_allowed', msg('api.method_not_allowed'));
    }
    api_error(404, 'not_found', msg('api.route_not_found'));
}
