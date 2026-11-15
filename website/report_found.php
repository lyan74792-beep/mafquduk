<?php
require __DIR__ . '/auth.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

$isSighting      = (isset($_GET['kind']) && $_GET['kind'] === 'sighting');
$categories      = lookup_categories();
$landmarks       = lookup_landmarks();
$currentStatuses = lookup_found_current_statuses();
$sightingStatus  = lookup_sighting_status();
$otherValue      = lookup_other();
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title>الإبلاغ عن موجود - منصة مفقودك</title>
    <!-- ربط البوتستراب والخط الرسمي -->
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- خريطة Leaflet (لاختيار الموقع بدون مفتاح API) -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    
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

    <!-- محتوى النموذج -->
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="form-card">
                    <?php render_flash(); ?>

                    <?php if ($isSighting): ?>
                        <h2 class="section-header-title" data-i18n="sighting_header">الإبلاغ عن مشاهدة غرض</h2>
                        <p class="text-muted small mb-4" data-i18n="sighting_subtitle">أبلغ عن غرض شاهدته دون أخذه لتسهيل وصول صاحبه أو فرق الميدان إليه.</p>
                    <?php else: ?>
                        <h2 class="section-header-title" data-i18n="found_header">الإبلاغ عن غرض معثور عليه</h2>
                        <p class="text-muted small mb-4" data-i18n="found_subtitle">يُرجى تسجيل تفاصيل المعثورات بدقة لمساعدة مالكها الأصلي في التعرف عليها واستردادها.</p>
                    <?php endif; ?>

                    <!-- نموذج تسجيل المعثورات -->
                    <form id="foundForm" action="process_found.php" method="POST" enctype="multipart/form-data" class="needs-validation" novalidate>
                        <input type="hidden" name="report_kind" value="<?php echo $isSighting ? 'sighting' : 'found'; ?>">
                        
                        <!-- بيانات المُبلّغ / المكتشف -->
                        <div class="row g-3 mb-4">
                            <div class="col-12">
                                <label for="finder_phone" class="form-label"><span data-i18n="label_phone">رقم التواصل</span> *</label>
                                <input type="tel" class="form-control" id="finder_phone" name="finder_phone" data-i18n-placeholder="placeholder_phone" placeholder="05XXXXXXXX" pattern="^05[0-9]{8}$" required>
                                <div class="invalid-feedback" data-i18n="phone_invalid">يرجى إدخال رقم جوال سعودي صحيح (05XXXXXXXX)</div>
                            </div>
                        </div>

                        <!-- تفاصيل الغرض المعثور عليه -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label for="item_category" class="form-label"><span data-i18n="found_label_category">تصنيف المعثور عليه</span> *</label>
                                <select class="form-select" id="item_category" name="item_category" required>
                                    <option value="" selected disabled data-i18n="cat_select">اختر التصنيف</option>
                                    <?php foreach ($categories as $cat): ?>
                                        <option value="<?php echo e($cat); ?>" data-i18n-value="<?php echo e($cat); ?>"><?php echo e($cat); ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label for="found_location" class="form-label"><span data-i18n="lost_label_location">أقرب معلم</span> *</label>
                                <select class="form-select" id="found_location" name="found_location" required>
                                    <option value="" selected disabled data-i18n="lost_loc_select">اختر أقرب معلم</option>
                                    <?php foreach ($landmarks as $lm): ?>
                                        <option value="<?php echo e($lm['name']); ?>" data-i18n-value="<?php echo e($lm['name']); ?>"><?php echo e($lm['name']); ?></option>
                                    <?php endforeach; ?>
                                </select>
                                <input type="text" id="found_location_other" name="found_location_other" class="form-control mt-2 d-none" data-i18n-placeholder="lost_placeholder_location" placeholder="اكتب اسم المعلم أو المكان تحديدًا">
                            </div>
                        </div>

                        <!-- مشاركة الموقع الدقيق -->
                        <div class="mb-4">
                            <label class="form-label" data-i18n="location_share_label">تحديد الموقع الدقيق (اختياري)</label>
                            <div class="location-share-box">
                                <div class="d-flex flex-wrap gap-2 mb-2">
                                    <button type="button" id="found_gps_btn" class="btn btn-outline-success btn-sm" data-i18n="btn_gps">📍 استخدم موقعي الحالي</button>
                                    <button type="button" id="found_map_btn" class="btn btn-outline-secondary btn-sm" data-i18n="btn_map">🗺️ اختر من الخريطة</button>
                                </div>
                                <small id="found_location_status" class="text-muted d-block" data-i18n="location_status_idle">لم يتم تحديد موقع دقيق بعد</small>
                                <input type="hidden" id="found_lat" name="found_lat">
                                <input type="hidden" id="found_lng" name="found_lng">
                            </div>
                        </div>

                        <!-- التاريخ ومكان التسليم الحالي -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label for="found_date" class="form-label"><span data-i18n="found_label_date">تاريخ العثور عليه</span> *</label>
                                <input type="date" class="form-control" id="found_date" name="found_date" required>
                            </div>
                            <div class="col-md-6">
                                <label for="current_status" class="form-label"><span data-i18n="found_label_status">حالة الغرض الحالية</span> *</label>
                                <select class="form-select" id="current_status" name="current_status" required>
                                    <option value="" <?php echo !$isSighting ? 'selected' : ''; ?> disabled data-i18n="found_status_select">أين يوجد الغرض الآن؟</option>
                                    <?php foreach ($currentStatuses as $st): ?>
                                        <option value="<?php echo e($st); ?>" data-i18n-value="<?php echo e($st); ?>" <?php echo ($isSighting && $st === $sightingStatus) ? 'selected' : ''; ?>><?php echo e($st); ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>

                        <!-- الوصف والصورة -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-12 mb-3">
                                <label for="item_image" class="form-label" data-i18n="found_label_image">إرفاق صورة المعثور عليه (تساعد في المطابقة السريعة)</label>
                                <input type="file" class="form-control" id="item_image" name="item_image" accept="image/*">
                            </div>
                            <div class="col-md-12">
                                <label for="item_description" class="form-label"><span data-i18n="found_label_description">وصف الغرض المعثور عليه</span> * <button type="button" class="btn btn-sm btn-outline-secondary ms-2" id="voiceBtn" aria-pressed="false"><i class="bi bi-mic-fill"></i> <span data-i18n="voice_button">إملاء صوتي</span></button></label>
                                <textarea class="form-control" id="item_description" name="item_description" rows="4" maxlength="250" data-i18n-placeholder="found_placeholder_description" placeholder="اكتب اللون، الماركة، أو أي تفاصيل واضحة تساعد صاحب الغرض في التعرف عليه" required></textarea>
                            </div>
                        </div>

                        <!-- سؤال الأمان وإجابته (اختياري) -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label for="security_question" class="form-label" data-i18n="found_label_sec_question">سؤال أمان للتحقق من الملكية (اختياري)</label>
                                <input type="text" class="form-control" id="security_question" name="security_question" maxlength="255"
                                       data-i18n-placeholder="found_placeholder_sec_question" placeholder="مثال: ما لون الغلاف الداخلي أو الخلفية؟">
                            </div>
                            <div class="col-md-6">
                                <label for="security_answer" class="form-label" data-i18n="found_label_sec_answer">إجابة سؤال الأمان (اختياري)</label>
                                <input type="text" class="form-control" id="security_answer" name="security_answer" maxlength="255"
                                       data-i18n-placeholder="found_placeholder_sec_answer" placeholder="اكتب الإجابة الصحيحة (تظهر للإدارة فقط)">
                            </div>
                            <div class="col-12">
                                <small class="text-muted" data-i18n="found_sec_qa_hint">عند كتابة سؤال أمان يجب إدخال إجابته معه، أو ترك الحقلين فارغين.</small>
                            </div>
                        </div>

                        <!-- زر الإرسال -->
                        <button type="submit" class="btn btn-gov-gold mt-2" data-i18n="found_btn_submit">تسجيل البلاغ</button>
                    </form>

                </div>
            </div>
        </div>
    </div>

    <!-- نافذة اختيار الموقع من الخريطة -->
    <div class="modal fade" id="found_map_modal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" data-i18n="map_modal_title">اختر الموقع على الخريطة</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div id="found_map_container"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" data-i18n="map_cancel_btn">إلغاء</button>
                    <button type="button" id="found_map_confirm" class="btn btn-gov-gold btn-modal-confirm" data-i18n="map_confirm_btn">تأكيد الموقع</button>
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
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="assets/i18n/ar.js?v=3"></script>
    <script src="assets/i18n/en.js?v=3"></script>
    <script src="assets/i18n/ur.js?v=3"></script>
    <script src="assets/i18n/tr.js?v=3"></script>
    <script src="assets/i18n/values.js?v=1"></script>
    <script src="assets/js/app.js?v=13"></script>
    <script>
        initVoiceInput('voiceBtn', 'item_description');
        initLocationPicker('found');
        initSmartForm({ formId: 'foundForm', phoneField: 'finder_phone', dateField: 'found_date' });
        initOtherToggle('found_location', 'found_location_other', <?php echo json_encode($otherValue, JSON_UNESCAPED_UNICODE); ?>);
    </script>
</body>
</html>
