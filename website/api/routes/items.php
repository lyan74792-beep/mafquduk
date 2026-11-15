<?php
/* ============================================================
   api/routes/items.php — public item browsing, details, and map.
   ============================================================ */

route('GET', '/items', 'api_items_browse', 'public');
route('GET', '/items/{type}/{id}', 'api_item_details', 'public');
route('GET', '/map/items', 'api_items_map', 'public');

function api_items_browse()
{
    global $conn;
    $type = api_query('type', 'all');
    $cat  = api_query('category', '');
    $q    = api_query('q', '');
    $page = (int)api_query('page', '1');
    api_ok(item_browse($conn, $type, $cat, $q, $page > 0 ? $page : 1));
}

function api_item_details($params)
{
    global $conn;
    $type = $params['type'];
    if ($type !== 'lost' && $type !== 'found') {
        throw new NotFoundError(msg('item.invalid_type'));
    }
    api_ok(item_details($conn, $type, (int)$params['id']));
}

function api_items_map()
{
    global $conn;
    api_ok(item_map($conn, api_query('type', 'all')));
}
