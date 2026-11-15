<?php
// بدء الجلسة للحصول على البيانات الحالية
session_start();

// تفريغ كافة متغيرات الجلسة
$_SESSION = array();

// إتلاف الجلسة تماماً من الخادم
session_destroy();

// إعادة توجيه المستخدم إلى صفحة تسجيل الدخول
header('Location: login.php');
exit;
?>