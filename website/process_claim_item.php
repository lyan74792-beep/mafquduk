<?php
/* process_claim_item.php — معالجة طلب استرداد غرض معثور من صفحة تفاصيل الغرض (claim_found_item) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('items.php');
}

$uid     = (int)$_SESSION['uid'];
$foundId = isset($_POST['found_item_id']) ? (int)$_POST['found_item_id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);
$desc    = isset($_POST['claim_description']) ? (string)$_POST['claim_description'] : '';
$secAns  = isset($_POST['security_answer']) ? (string)$_POST['security_answer'] : '';

$backUrl = $foundId > 0 ? ('item.php?type=found&id=' . $foundId) : 'items.php';

try {
    claim_found_item($conn, $uid, $foundId, $desc, $secAns);
    flash_ok(msg('match.claimed_ok'));
    redirect($backUrl);
} catch (UserError $e) {
    flash($e->getMessage());
    redirect($backUrl);
} catch (Exception $e) {
    error_log('claim item error: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect($backUrl);
}
