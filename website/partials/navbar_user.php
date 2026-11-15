<?php
/* partials/navbar_user.php — شريط التنقل العلوي لصفحات الزوار والمستخدمين */
?>
    <nav class="navbar navbar-expand-lg navbar-gov">
        <div class="container">
            <a class="navbar-brand brand-title" href="index.php" data-i18n="brand">مفقودك</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#userNavbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="userNavbarNav">
                <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                    <li class="nav-item">
                        <a class="nav-link" href="index.php" data-i18n="home">الرئيسية</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="items.php" data-i18n="nav_browse_items">تصفح المفقودات والمعثورات</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="map.php" data-i18n="nav_map">خريطة البلاغات</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="report_found.php?kind=sighting" data-i18n="nav_report_sighting">الإبلاغ عن مشاهدة</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="download.php"><i class="bi bi-phone"></i> <span data-i18n="nav_download_app">تحميل التطبيق</span></a>
                    </li>
                </ul>
                <div class="d-flex flex-wrap gap-2 align-items-center">
                    <a href="report_lost.php" class="btn btn-gov-primary btn-sm" data-i18n="btn_report_lost">تقديم طلب مفقود</a>
                    <a href="report_found.php" class="btn btn-gov-gold btn-sm w-auto" data-i18n="btn_report_found">الإبلاغ عن موجود</a>

                    <div class="dropdown">
                        <button class="btn btn-outline-secondary btn-sm dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="bi bi-translate me-1"></i><span id="currentLangLabel">العربية</span>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><button class="dropdown-item lang-option" data-lang="ar" type="button">العربية</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="en" type="button">English</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="ur" type="button">اردو</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="tr" type="button">Türkçe</button></li>
                        </ul>
                    </div>

                    <?php if (function_exists('is_logged_in') && is_logged_in()): ?>
                        <?php if (isset($_SESSION['role']) && $_SESSION['role'] === 'admin'): ?>
                            <a href="admin_dashboard.php" class="btn btn-outline-secondary btn-sm px-3" data-i18n="nav_dashboard">لوحة التحكم</a>
                        <?php else: ?>
                            <?php
                            $navUnreadCount = 0;
                            if (isset($conn) && function_exists('notification_list')) {
                                try {
                                    $navNotifData   = notification_list($conn, (int)$_SESSION['uid']);
                                    $navUnreadCount = (int)$navNotifData['unread_count'];
                                } catch (Exception $e) {
                                    error_log('navbar notifications: ' . $e->getMessage());
                                }
                            }
                            ?>
                            <a href="notifications.php" class="btn btn-outline-secondary btn-sm px-3 position-relative">
                                <i class="bi bi-bell me-1"></i><span data-i18n="nav_notifications">الإشعارات</span>
                                <span class="badge rounded-pill <?php echo $navUnreadCount > 0 ? 'text-bg-danger' : 'text-bg-secondary'; ?> ms-1"><?php echo (int)$navUnreadCount; ?></span>
                            </a>
                            <a href="profile.php" class="btn btn-outline-secondary btn-sm px-3">
                                <i class="bi bi-person me-1"></i><span data-i18n="nav_profile">الملف الشخصي</span>
                            </a>
                            <a href="user_dashboard.php" class="btn btn-outline-secondary btn-sm px-3" data-i18n="s_back">لوحة المستخدم</a>
                        <?php endif; ?>
                        <a href="logout.php" class="btn btn-outline-secondary btn-sm px-3" data-i18n="btn_logout">تسجيل الخروج</a>
                    <?php else: ?>
                        <a href="login.php" class="btn btn-outline-secondary btn-sm px-3" data-i18n="btn_login">تسجيل الدخول</a>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </nav>
