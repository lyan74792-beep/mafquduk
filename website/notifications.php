<?php
/* notifications.php — قائمة إشعارات المستخدم (غير المقروءة بخط عريض) مع تعليم واحد أو الكل كمقروء */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

$uid           = (int)$_SESSION['uid'];
$unreadCount   = 0;
$notifications = array();

try {
    $res           = notification_list($conn, $uid);
    $unreadCount   = (int)$res['unread_count'];
    $notifications = $res['notifications'];
} catch (Exception $e) {
    error_log('notifications load error: ' . $e->getMessage());
}

$pageTitleKey = 'notifications_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-4">
        <?php render_flash(); ?>

        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
            <div>
                <h2 class="section-title mb-1">
                    <span data-i18n="notifications_header">مركز الإشعارات</span>
                    <?php if ($unreadCount > 0): ?>
                        <span class="badge text-bg-danger rounded-pill fs-6 ms-1"><?php echo (int)$unreadCount; ?></span>
                    <?php endif; ?>
                </h2>
                <p class="text-muted small mb-0" data-i18n="notifications_subtitle">متابعة التنبيهات الخاصة بالمطابقات وطلبات الاسترداد والشحن.</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <?php if ($unreadCount > 0): ?>
                    <form method="POST" action="notification_action.php" class="d-inline">
                        <input type="hidden" name="action" value="mark_all_read">
                        <button type="submit" class="btn btn-gov-primary btn-sm">
                            <i class="bi bi-check2-all me-1"></i><span data-i18n="btn_mark_all_read">تعليم الكل كمقروء</span>
                        </button>
                    </form>
                <?php endif; ?>
                <a href="user_dashboard.php" class="btn btn-outline-secondary btn-sm">
                    <i class="bi bi-arrow-right me-1"></i><span data-i18n="s_back">لوحة المستخدم</span>
                </a>
            </div>
        </div>

        <?php if (!$notifications): ?>
            <div class="dash-card text-center py-5">
                <i class="bi bi-bell-slash fs-1 text-muted d-block mb-2"></i>
                <p class="text-muted mb-0" data-i18n="notifications_empty">لا توجد إشعارات حالياً.</p>
            </div>
        <?php else: ?>
            <?php foreach ($notifications as $n): ?>
                <?php
                $isUnread = empty($n['is_read']);
                $icon = 'bi-bell';
                if ($n['notification_type'] === 'match') {
                    $icon = 'bi-link-45deg';
                } elseif ($n['notification_type'] === 'claim') {
                    $icon = 'bi-patch-check';
                } elseif ($n['notification_type'] === 'shipping') {
                    $icon = 'bi-truck';
                }
                ?>
                <div class="notif-item <?php echo $isUnread ? 'unread' : ''; ?>">
                    <div class="notif-icon">
                        <i class="bi <?php echo e($icon); ?>"></i>
                    </div>
                    <div class="flex-grow-1">
                        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-1">
                            <h6 class="mb-0 <?php echo $isUnread ? 'fw-bold text-dark' : 'fw-semibold text-secondary'; ?>">
                                <?php echo e($n['title']); ?>
                                <?php if ($isUnread): ?>
                                    <span class="badge text-bg-success ms-1" data-i18n="badge_unread">غير مقروء</span>
                                <?php endif; ?>
                            </h6>
                            <span class="small text-muted"><?php echo e((string)$n['created_at']); ?></span>
                        </div>
                        <p class="small mb-0 <?php echo $isUnread ? 'fw-bold text-dark' : 'text-muted'; ?>">
                            <?php echo e($n['message']); ?>
                        </p>
                    </div>
                    <?php if ($isUnread): ?>
                        <div class="ms-auto">
                            <form method="POST" action="notification_action.php">
                                <input type="hidden" name="action" value="mark_read">
                                <input type="hidden" name="notification_id" value="<?php echo (int)$n['notification_id']; ?>">
                                <button type="submit" class="btn btn-outline-secondary btn-sm" data-i18n="btn_mark_read">تعليم كمقروء</button>
                            </form>
                        </div>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

<?php require __DIR__ . '/partials/footer.php'; ?>
