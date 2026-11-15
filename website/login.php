<?php
require __DIR__ . '/auth.php';
$preselected_role = (isset($_GET['role']) && $_GET['role'] === 'admin') ? 'admin' : 'user';
$otp_phone = isset($_SESSION['otp_phone']) ? (string)$_SESSION['otp_phone'] : '';
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title>تسجيل الدخول - منصة مفقودك</title>
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/style.css?v=7">
</head>
<body class="page-form">

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

    <div class="auth-split">
        <div class="row g-0">
            <div class="col-lg-6">
                <div class="auth-form-wrap">
                    <?php render_flash(); ?>

                    <h2 class="auth-title" data-i18n="login_select_title">تسجيل الدخول</h2>
                    <p class="text-muted small mb-4" data-i18n="login_select_subtitle">اختر الفئة المناسبة لك للمتابعة</p>

                    <form id="loginForm" action="process_login.php" method="POST" class="needs-validation" novalidate>

                        <div class="mb-4">
                            <div class="role-choice mb-2">
                                <input type="radio" name="account_type" id="role_user" value="user" <?php echo $preselected_role === 'user' ? 'checked' : ''; ?>>
                                <label for="role_user">
                                    <i class="bi bi-person"></i>
                                    <span>
                                        <span class="d-block fw-bold" data-i18n="card_individuals_title">الأفراد</span>
                                        <span class="d-block small text-muted" data-i18n="card_individuals_desc">للبحث عن المفقودات، أو تسجيل بلاغ عن مفقود ومعثور.</span>
                                    </span>
                                </label>
                            </div>
                            <div class="role-choice">
                                <input type="radio" name="account_type" id="role_admin" value="admin" <?php echo $preselected_role === 'admin' ? 'checked' : ''; ?>>
                                <label for="role_admin">
                                    <i class="bi bi-shield-check"></i>
                                    <span>
                                        <span class="d-block fw-bold" data-i18n="card_admin_title">فريق الإدارة</span>
                                        <span class="d-block small text-muted" data-i18n="card_admin_desc">لمتابعة البلاغات، التحقق من الملكية، وإدارة المستردات.</span>
                                    </span>
                                </label>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label for="login_email" class="form-label"><span data-i18n="label_email">البريد الإلكتروني</span> *</label>
                            <input type="email" class="form-control" id="login_email" name="email" data-i18n-placeholder="placeholder_email" placeholder="example@email.com" required>
                        </div>

                        <div class="mb-4">
                            <label for="login_password" class="form-label"><span data-i18n="label_password">كلمة المرور</span> *</label>
                            <input type="password" class="form-control" id="login_password" name="password" required>
                        </div>

                        <button type="submit" class="btn btn-gov-submit" data-i18n="btn_login_submit">تسجيل الدخول</button>

                        <p class="text-center small text-muted mt-3 mb-1">
                            <span data-i18n="no_account_text">ماعندك حساب؟</span>
                            <a href="register.php" class="fw-bold text-decoration-none service-link" data-i18n="create_account_link">أنشئ حساب</a>
                        </p>
                        <p class="text-center small text-muted mb-0">
                            <span data-i18n="admin_no_account_text">من فريق الإدارة؟</span>
                            <a href="register_admin.php" class="fw-bold text-decoration-none service-link" data-i18n="admin_create_account_link">أنشئ حساب إدارة</a>
                        </p>
                    </form>

                    <!-- الدخول برمز الجوال (للأفراد فقط) -->
                    <div id="otpSection" class="mt-4 pt-3 border-top<?php echo $preselected_role === 'admin' ? ' d-none' : ''; ?>">
                        <h6 class="fw-bold mb-1" data-i18n="otp_login_title">الدخول برمز الجوال (للأفراد)</h6>
                        <p class="text-muted small mb-3" data-i18n="otp_login_desc">أدخل رقم جوالك المسجّل لإرسال رمز تحقق مكوّن من 4 أرقام.</p>

                        <form id="otpRequestForm" action="process_otp.php" method="POST" class="row g-2 align-items-end mb-3">
                            <input type="hidden" name="action" value="request">
                            <div class="col-sm-8">
                                <label for="otp_phone" class="form-label small mb-1"><span data-i18n="label_phone">رقم التواصل</span> *</label>
                                <input type="tel" class="form-control form-control-sm" id="otp_phone" name="phone"
                                       value="<?php echo e($otp_phone); ?>" data-i18n-placeholder="placeholder_phone" placeholder="05XXXXXXXX" pattern="^05[0-9]{8}$" required>
                            </div>
                            <div class="col-sm-4">
                                <button type="submit" class="btn btn-outline-secondary btn-sm w-100" data-i18n="otp_btn_send">إرسال الرمز</button>
                            </div>
                        </form>

                        <form id="otpVerifyForm" action="process_otp.php" method="POST" class="row g-2 align-items-end">
                            <input type="hidden" name="action" value="verify">
                            <input type="hidden" name="phone" id="otp_verify_phone" value="<?php echo e($otp_phone); ?>">
                            <div class="col-sm-8">
                                <label for="otp_code" class="form-label small mb-1"><span data-i18n="otp_label_code">رمز التحقق</span> *</label>
                                <input type="text" class="form-control form-control-sm" id="otp_code" name="code"
                                       inputmode="numeric" pattern="^[0-9]{4}$" maxlength="4"
                                       data-i18n-placeholder="otp_placeholder_code" placeholder="أدخل الرمز (4 أرقام)" required>
                            </div>
                            <div class="col-sm-4">
                                <button type="submit" class="btn btn-gov-primary btn-sm w-100" data-i18n="otp_btn_verify">تحقق ودخول</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

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
            const form = document.getElementById('loginForm');
            form.addEventListener('submit', function (e) {
                if (!form.checkValidity()) { e.preventDefault(); e.stopPropagation(); }
                form.classList.add('was-validated');
            });

            const roleUser = document.getElementById('role_user');
            const roleAdmin = document.getElementById('role_admin');
            const otpSection = document.getElementById('otpSection');
            const otpPhone = document.getElementById('otp_phone');
            const otpVerifyPhone = document.getElementById('otp_verify_phone');

            function syncRole() {
                if (otpSection && roleAdmin) {
                    otpSection.classList.toggle('d-none', roleAdmin.checked);
                }
            }
            if (roleUser) roleUser.addEventListener('change', syncRole);
            if (roleAdmin) roleAdmin.addEventListener('change', syncRole);

            if (otpPhone && otpVerifyPhone) {
                otpPhone.addEventListener('input', function () {
                    otpVerifyPhone.value = otpPhone.value.trim();
                });
            }
        })();
    </script>
</body>
</html>
