<?php
/* partials/head.php — الترويسة المشتركة لصفحات الزوار والمستخدمين ($pageTitleKey) */
if (!isset($pageTitleKey) || $pageTitleKey === '') {
    $pageTitleKey = 'brand';
}
if (!isset($bodyClass) || $bodyClass === '') {
    $bodyClass = 'page-form';
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title data-i18n="<?php echo e($pageTitleKey); ?>">منصة مفقودك</title>
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link rel="stylesheet" href="assets/css/style.css?v=7">
</head>
<body class="<?php echo e($bodyClass); ?>">
