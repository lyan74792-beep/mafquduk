<?php require __DIR__ . '/auth.php'; ?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title>تسجيل فريق الإدارة - منصة مفقودك</title>
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/style.css?v=6">
</head>
<body class="page-form">

    <!-- شريط التنقل العلوي -->
    <nav class="navbar navbar-expand-lg navbar-gov">
        <div class="container">
            <a class="navbar-brand brand-title" href="index.php" data-i18n="brand">مفقودك</a>
            <div class="d-flex gap-2 align-items-center">
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
                <a href="index.php" class="btn btn-outline-secondary btn-sm px-3" data-i18n="home">الرئيسية</a>
            </div>
        </div>
    </nav>

    <!-- صفحة تسجيل الإدارة: النموذج + الصورة -->
    <div class="auth-split">
        <div class="row g-0">

            <!-- النموذج -->
            <div class="col-lg-6">
                <div class="auth-form-wrap">
                    <?php render_flash(); ?>
                    <h2 class="auth-title" data-i18n="register_admin_header">إنشاء حساب فريق الإدارة</h2>
                    <p class="text-muted small mb-3" data-i18n="register_admin_subtitle">لمتابعة البلاغات، التحقق من الملكية، وإدارة المستردات.</p>

                    <!-- تنبيه الموافقة -->
                    <div class="alert alert-warning small d-flex gap-2 align-items-start" role="alert">
                        <i class="bi bi-info-circle mt-1"></i>
                        <span data-i18n="admin_approval_notice">سيتم مراجعة طلبك وتفعيل الحساب بعد موافقة المسؤول.</span>
                    </div>


                    <form id="registerAdminForm" action="process_register.php" method="POST" class="needs-validation" novalidate>
                        <input type="hidden" name="account_type" value="admin">

                        <div class="mb-3">
                            <label for="full_name" class="form-label"><span data-i18n="label_fullname">الاسم الكامل</span> *</label>
                            <input type="text" class="form-control" id="full_name" name="full_name" data-i18n-placeholder="placeholder_fullname" placeholder="أدخل اسمك الكامل" required>
                        </div>

                        <div class="mb-3">
                            <label for="email" class="form-label"><span data-i18n="label_email">البريد الإلكتروني</span> *</label>
                            <input type="email" class="form-control" id="email" name="email" data-i18n-placeholder="placeholder_email" placeholder="example@email.com" required>
                        </div>

                        <div class="row g-3 mb-2">
                            <div class="col-md-6">
                                <label for="password" class="form-label"><span data-i18n="label_password">كلمة المرور</span> *</label>
                                <input type="password" class="form-control" id="password" name="password" minlength="8" required>
                            </div>
                            <div class="col-md-6">
                                <label for="confirm_password" class="form-label"><span data-i18n="label_confirm_password">تأكيد كلمة المرور</span> *</label>
                                <input type="password" class="form-control" id="confirm_password" name="confirm_password" minlength="8" required>
                            </div>
                        </div>
                        <small id="password_mismatch_msg" class="text-danger d-none" data-i18n="password_mismatch">كلمتا المرور غير متطابقتين</small>
                        <small class="text-muted d-block mb-3" data-i18n="password_hint">يجب أن تكون 8 أحرف على الأقل</small>

                        <div class="form-check mb-4">
                            <input class="form-check-input" type="checkbox" id="accept_terms" name="accept_terms" required>
                            <label class="form-check-label small" for="accept_terms">
                                <span data-i18n="accept_terms_text">أوافق على الشروط والأحكام وسياسة الخصوصية</span>
                            </label>
                        </div>

                        <button type="submit" class="btn btn-gov-submit" data-i18n="btn_register">إنشاء الحساب</button>

                        <p class="text-center small text-muted mt-3 mb-1">
                            <span data-i18n="already_have_account">لديك حساب بالفعل؟</span>
                            <a href="login.php?role=admin" class="fw-bold text-decoration-none service-link" data-i18n="login_link_text">سجّل الدخول</a>
                        </p>
                        <p class="text-center small text-muted mb-0">
                            <a href="register.php" class="text-decoration-none service-link" data-i18n="register_as_individual">التسجيل كفرد؟ أنشئ حساب أفراد</a>
                        </p>
                    </form>
                </div>
            </div>

            <!-- الصورة (تختفي بالجوال) -->
            <div class="col-lg-6 d-none d-lg-block">
                <div class="auth-image"></div>
            </div>

        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="assets/i18n/ar.js?v=3"></script>
    <script src="assets/i18n/en.js?v=3"></script>
    <script src="assets/i18n/ur.js?v=3"></script>
    <script src="assets/i18n/tr.js?v=3"></script>
    <script src="assets/i18n/values.js?v=1"></script>
    <script src="assets/js/app.js?v=13"></script>
    <script>
        (function () {
            const form = document.getElementById('registerAdminForm');
            const pass = document.getElementById('password');
            const confirm = document.getElementById('confirm_password');
            const msg = document.getElementById('password_mismatch_msg');

            function checkMatch() {
                const mismatch = confirm.value && pass.value !== confirm.value;
                confirm.setCustomValidity(mismatch ? 'mismatch' : '');
                msg.classList.toggle('d-none', !mismatch);
            }
            pass.addEventListener('input', checkMatch);
            confirm.addEventListener('input', checkMatch);

            form.addEventListener('submit', function (e) {
                checkMatch();
                if (!form.checkValidity()) { e.preventDefault(); e.stopPropagation(); }
                form.classList.add('was-validated');
            });
        })();
    </script>
</body>
</html>