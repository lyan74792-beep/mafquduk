<?php
/* profile.php — الملف الشخصي للمستخدم: تعديل البيانات الشخصية وتغيير كلمة المرور */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

$uid  = (int)$_SESSION['uid'];
$user = array('full_name' => '', 'email' => '', 'phone' => '', 'nationality' => '');

try {
    $user = account_user($conn, $uid);
} catch (Exception $e) {
    error_log('profile load error: ' . $e->getMessage());
}

$pageTitleKey = 'profile_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-4">
        <?php render_flash(); ?>

        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
            <div>
                <h2 class="section-title mb-1" data-i18n="profile_header">الملف الشخصي وإعدادات الحساب</h2>
                <p class="text-muted small mb-0" data-i18n="profile_subtitle">تحديث بياناتك الشخصية ورقم الجوال أو تغيير كلمة المرور.</p>
            </div>
            <a href="user_dashboard.php" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-arrow-right me-1"></i><span data-i18n="s_back">لوحة المستخدم</span>
            </a>
        </div>

        <div class="row g-4">
            <!-- 1. تعديل البيانات الشخصية -->
            <div class="col-lg-6">
                <div class="dash-card h-100">
                    <h4 class="section-header-title" data-i18n="profile_info_title">البيانات الشخصية</h4>
                    <form id="profileInfoForm" method="POST" action="process_profile.php" class="needs-validation" novalidate>
                        <input type="hidden" name="action" value="update_profile">

                        <div class="mb-3">
                            <label for="profile_email" class="form-label" data-i18n="label_email">البريد الإلكتروني</label>
                            <input type="email" class="form-control bg-light" id="profile_email" value="<?php echo e($user['email']); ?>" disabled readonly>
                        </div>

                        <div class="mb-3">
                            <label for="full_name" class="form-label"><span data-i18n="label_fullname">الاسم الكامل</span> *</label>
                            <input type="text" class="form-control" id="full_name" name="full_name"
                                   maxlength="100" required
                                   value="<?php echo e($user['full_name']); ?>"
                                   data-i18n-placeholder="placeholder_fullname" placeholder="أدخل اسمك الكامل">
                        </div>

                        <div class="mb-3">
                            <label for="phone" class="form-label"><span data-i18n="label_phone">رقم التواصل</span> <span class="text-muted fw-normal" data-i18n="optional_tag">(اختياري)</span></label>
                            <input type="tel" class="form-control" id="phone" name="phone"
                                   pattern="^05[0-9]{8}$"
                                   value="<?php echo e((string)$user['phone']); ?>"
                                   data-i18n-placeholder="placeholder_phone" placeholder="05XXXXXXXX">
                            <div class="invalid-feedback" data-i18n="phone_invalid">يرجى إدخال رقم جوال سعودي صحيح (05XXXXXXXX)</div>
                        </div>

                        <div class="mb-4">
                            <label for="nationality" class="form-label"><span data-i18n="label_nationality">الجنسية</span> <span class="text-muted fw-normal" data-i18n="optional_tag">(اختياري)</span></label>
                            <input type="text" class="form-control" id="nationality" name="nationality"
                                   maxlength="50"
                                   value="<?php echo e((string)$user['nationality']); ?>"
                                   data-i18n-placeholder="placeholder_nationality" placeholder="مثال: سعودي">
                        </div>

                        <button type="submit" class="btn btn-gov-submit" data-i18n="btn_save_profile">حفظ التغييرات</button>
                    </form>
                </div>
            </div>

            <!-- 2. تغيير كلمة المرور -->
            <div class="col-lg-6">
                <div class="dash-card h-100">
                    <h4 class="section-header-title" data-i18n="profile_password_title">تغيير كلمة المرور</h4>
                    <form id="profilePasswordForm" method="POST" action="process_profile.php" class="needs-validation" novalidate>
                        <input type="hidden" name="action" value="change_password">

                        <div class="mb-3">
                            <label for="current_password" class="form-label"><span data-i18n="label_current_password">كلمة المرور الحالية</span> *</label>
                            <input type="password" class="form-control" id="current_password" name="current_password" required>
                        </div>

                        <div class="mb-3">
                            <label for="new_password" class="form-label"><span data-i18n="label_new_password">كلمة المرور الجديدة</span> *</label>
                            <input type="password" class="form-control" id="new_password" name="new_password" minlength="8" required>
                            <div class="form-text small" data-i18n="password_hint">يجب أن تكون 8 أحرف على الأقل</div>
                        </div>

                        <div class="mb-4">
                            <label for="confirm_password" class="form-label"><span data-i18n="label_confirm_password">تأكيد كلمة المرور</span> *</label>
                            <input type="password" class="form-control" id="confirm_password" name="confirm_password" minlength="8" required>
                            <div class="invalid-feedback" data-i18n="password_mismatch">كلمتا المرور غير متطابقتين</div>
                        </div>

                        <button type="submit" class="btn btn-gov-gold" data-i18n="btn_change_password">تحديث كلمة المرور</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

<?php require __DIR__ . '/partials/footer.php'; ?>
