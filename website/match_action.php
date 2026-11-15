<?php
/* match_action.php — المستخدم: يؤكد "هذا غرضي" (match_claim) أو يرفض المطابقة (match_reject) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    redirect('user_dashboard.php');
}

$uid    = (int)$_SESSION['uid'];
$mid    = isset($_POST['match_id']) ? (int)$_POST['match_id'] : 0;
$act    = isset($_POST['action']) ? (string)$_POST['action'] : '';
$desc   = isset($_POST['claim_description']) ? (string)$_POST['claim_description'] : '';
$secAns = isset($_POST['security_answer']) ? (string)$_POST['security_answer'] : '';

try {
    if ($act === 'reject') {
        match_reject($conn, $uid, $mid);
        flash_ok(msg('match.rejected_ok'));
    } elseif ($act === 'claim') {
        match_claim($conn, $uid, $mid, $desc, $secAns);
        flash_ok(msg('match.claimed_ok'));
    }
    redirect('user_dashboard.php');
} catch (UserError $e) {
    flash($e->getMessage());
    redirect('user_dashboard.php');
} catch (Exception $e) {
    error_log('match action: ' . $e->getMessage());
    flash(msg('api.unexpected'));
    redirect('user_dashboard.php');
}
