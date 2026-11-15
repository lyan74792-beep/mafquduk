<?php
/* report_emergency.php — نموذج بلاغ طارئ بدون تعبئة تلقائية ومع تلميحات رسمية */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';

// إذا كان المستخدم مسجلاً دخوله، نقرأ رقمه اختياريًا أو نتركه فارغًا
$userPhone = '';
if (is_logged_in() && isset($_SESSION['uid'])) {
    $uid = (int)$_SESSION['uid'];
    $stmt = $conn->prepare("SELECT phone FROM users WHERE user_id = ?");
    $stmt->bind_param('i', $uid);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($row = $res->fetch_assoc()) {
        // يمكنك إبقاء الرقم فارغاً حتى لا يملأه المتصفح
        // $userPhone = $row['phone'];
    }
    $stmt->close();
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title data-i18n="em_page_title">بلاغ طارئ - منصة مفقودك</title>
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/style.css?v=8">
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

    <!-- محتوى النموذج -->
    <div class="container py-4">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="form-card">
                    
                    <!-- تنبيه طوارئ رسمي ومختصر -->
                    <div class="alert alert-danger d-flex align-items-center gap-2 mb-4" role="alert">
                        <i class="bi bi-exclamation-triangle-fill fs-5"></i>
                        <div>
                            <strong data-i18n="em_alert_strong">بلاغ طارئ:</strong> <span data-i18n="em_alert_text">مخصص للبلاغات العاجلة (الأطفال وكبار السن) للتنسيق المباشر مع فرق البحث.</span>
                        </div>
                    </div>

                    <h2 class="section-header-title" data-i18n="em_title">الإبلاغ عن شخص تائه (طفل / مسن)</h2>

                    <?php render_flash(); ?>

                    <!-- إضافة autocomplete="off" وحيل الإكمال التلقائي -->
                    <form id="emergencyForm" action="process_emergency.php" method="POST" enctype="multipart/form-data" autocomplete="off" class="needs-validation" novalidate>
                        
                        <!-- حقل مخفي لمنع المتصفح من ملء الحقول التالية تلقائياً -->
                        <input type="text" style="display:none" aria-hidden="true">
                        <input type="password" style="display:none" aria-hidden="true">

                        <div class="row g-3 mb-3">
                            <div class="col-md-7">
                                <label for="person_name" class="form-label"><span data-i18n="em_label_name">الاسم</span> <span class="text-muted fw-normal" data-i18n="optional_tag">(اختياري)</span></label>
                                <input type="text" class="form-control" id="person_name" name="person_name" autocomplete="off">
                            </div>
                            <div class="col-md-5">
                                <label for="approx_age" class="form-label"><span data-i18n="em_label_age">العمر التقريبي</span> *</label>
                                <input type="text" class="form-control" id="approx_age" name="approx_age" autocomplete="off" required>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label for="last_seen_location" class="form-label"><span data-i18n="em_label_location">آخر موقع شوهد فيه</span> *</label>
                            <select class="form-select mb-2" id="last_seen_location" name="last_seen_location" required>
                                <option value="" selected disabled data-i18n="em_select_location">اختر الموقع</option>
                                <option value="الحرم المكي (عام)" data-i18n-value="الحرم المكي (عام)">الحرم المكي (عام)</option>
                                <option value="أبواب الحرم الرئيسية" data-i18n-value="أبواب الحرم الرئيسية">أبواب الحرم الرئيسية</option>
                                <option value="صحن المطاف / المسعى" data-i18n-value="صحن المطاف / المسعى">صحن المطاف / المسعى</option>
                                <option value="برج الساعة وأبراج البيت" data-i18n-value="برج الساعة وأبراج البيت">برج الساعة وأبراج البيت</option>
                                <option value="مشعر منى" data-i18n-value="مشعر منى">مشعر منى</option>
                                <option value="مشعر عرفات" data-i18n-value="مشعر عرفات">مشعر عرفات</option>
                                <option value="مشعر مزدلفة" data-i18n-value="مشعر مزدلفة">مشعر مزدلفة</option>
                                <option value="أخرى" data-i18n="em_other_location">موقع آخر</option>
                            </select>
                            <input type="text" id="location_other" name="location_other" class="form-control d-none" data-i18n-placeholder="em_placeholder_location" placeholder="أدخل اسم الموقع بالتحديد">
                        </div>

                        <div class="mb-3">
                            <label for="clothing_description" class="form-label"><span data-i18n="em_label_clothing">وصف الملابس والعلامات المميزة</span> *</label>
                            <textarea class="form-control" id="clothing_description" name="clothing_description" rows="3" data-i18n-placeholder="em_placeholder_clothing" placeholder="أدخل لون الملابس وأي علامات فارقة تسهل التعرف عليه" required></textarea>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label for="reporter_phone" class="form-label"><span data-i18n="em_label_phone">رقم التواصل</span> *</label>
                                <!-- تغيير نوع الحقل مؤقتاً وحمايته بـ autocomplete لمنع التعبئة التلقائية -->
                                <input type="text" class="form-control" id="reporter_phone" name="reporter_phone" placeholder="05XXXXXXXX" value="<?php echo htmlspecialchars($userPhone); ?>" pattern="^05[0-9]{8}$" autocomplete="none" readonly onfocus="this.removeAttribute('readonly');" required>
                                <div class="invalid-feedback" data-i18n="em_phone_invalid">يرجى إدخال رقم جوال صحيح (05XXXXXXXX)</div>
                            </div>
                            <div class="col-md-6">
                                <label for="item_image" class="form-label"><span data-i18n="em_label_photo">صورة شخصية</span> <span class="text-muted fw-normal" data-i18n="optional_tag">(اختياري)</span></label>
                                <input type="file" class="form-control" id="item_image" name="item_image" accept="image/*">
                            </div>
                        </div>

                        <button type="submit" class="btn btn-danger w-100 py-2 fw-bold text-white shadow-sm">
                            <i class="bi bi-send-fill me-1"></i> <span data-i18n="em_submit">إرسال البلاغ الطارئ</span>
                        </button>
                    </form>

                </div>
            </div>
        </div>
    </div>

    <!-- الفوتر -->
    <footer class="text-center">
        <div class="container">
            <p class="mb-0 small" data-i18n="footer_text">منصة مفقودك - 2026</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="assets/i18n/ar.js?v=3"></script>
    <script src="assets/i18n/en.js?v=3"></script>
    <script src="assets/i18n/ur.js?v=3"></script>
    <script src="assets/i18n/tr.js?v=3"></script>
    <script src="assets/i18n/values.js?v=1"></script>
    <script src="assets/js/app.js?v=13"></script>
    <script>
        initSmartForm({ formId: 'emergencyForm', phoneField: 'reporter_phone' });
        initOtherToggle('last_seen_location', 'location_other', 'أخرى');

        document.addEventListener("DOMContentLoaded", function() {
            var phoneInput = document.getElementById('reporter_phone');
            if (phoneInput) {
                // مسح القيمة فور فتح الصفحة لمنع متصفح Edge من كتابة الرقم المحفوظ تلقائياً
                phoneInput.value = '';
                
                setTimeout(function() {
                    phoneInput.value = '';
                }, 150);
            }
        });
    </script>
</body>
</html>