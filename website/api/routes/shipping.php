<?php
/* ============================================================
   api/routes/shipping.php — user shipping requests.
   ============================================================ */

route('POST', '/shipping', 'api_shipping_create', 'user');
route('GET', '/shipping/mine', 'api_shipping_mine', 'user');

function api_shipping_create($params, $actor)
{
    global $conn;
    api_ok(shipping_create($conn, $actor['id'], api_input()), 201);
}

function api_shipping_mine($params, $actor)
{
    global $conn;
    api_ok(shipping_list_for_user($conn, $actor['id']));
}
