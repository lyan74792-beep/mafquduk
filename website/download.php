<?php
/* download.php — صفحة تحميل تطبيق مفقودك للأندرويد (رابط مباشر + رمز QR + خطوات التثبيت) */
require __DIR__ . '/auth.php';

// ملف التطبيق: انسخ أحدث نسخة من final project/release/mafqoodak.apk إلى هذا المسار
$apkPath    = __DIR__ . '/download/mafqoodak.apk';
$apkUrl     = 'download/mafqoodak.apk';
$appVersion = '1.0.3';
$apkExists  = is_file($apkPath);
$apkSizeMb  = $apkExists ? number_format(filesize($apkPath) / 1048576, 1) : null;
$apkDate    = $apkExists ? date('Y-m-d', filemtime($apkPath)) : null;

$pageTitleKey = 'download_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>
    <div class="container py-4">
        <?php render_flash(); ?>
        <div class="row justify-content-center g-4">
            <!-- بطاقة التحميل -->
            <div class="col-lg-7">
                <div class="form-card text-center">
                    <div class="mb-3">
                        <img src="assets/images/app-icon.png" alt="" width="96" height="96" style="border-radius:22px;box-shadow:0 4px 14px rgba(13,74,58,.25);">
                    </div>
                    <h1 class="section-header-title mb-2" data-i18n="download_title">تحميل تطبيق مفقودك</h1>
                    <p class="text-muted mb-4" data-i18n="download_subtitle">بلّغ عن المفقودات والمعثورات، وتابع المطابقات والاسترداد من جوالك مباشرة.</p>

                    <?php if ($apkExists): ?>
                        <a href="<?php echo e($apkUrl); ?>" download class="btn btn-gov-primary btn-lg px-5 mb-3">
                            <i class="bi bi-android2 me-1"></i> <span data-i18n="download_button">تحميل التطبيق للأندرويد</span>
                        </a>
                        <div class="small text-muted mb-4">
                            <span data-i18n="download_version">الإصدار</span> <?php echo e($appVersion); ?> ·
                            <?php echo e($apkSizeMb); ?> <span data-i18n="download_mb">ميجابايت</span> ·
                            <span data-i18n="download_updated">آخر تحديث</span> <?php echo e($apkDate); ?>
                        </div>

                        <!-- رمز QR: يُنشأ في المتصفح من رابط الملف الكامل -->
                        <div class="d-inline-block p-3 border rounded-3 bg-white mb-2">
                            <div id="apkQr"></div>
                        </div>
                        <p class="small text-muted mb-0" data-i18n="download_qr">امسح الرمز بكاميرا الجوال لتحميل التطبيق مباشرة.</p>
                    <?php else: ?>
                        <div class="alert alert-warning" data-i18n="download_unavailable">ملف التطبيق غير متوفر حاليًا. حاول لاحقًا.</div>
                    <?php endif; ?>
                </div>
            </div>

            <!-- خطوات التثبيت -->
            <div class="col-lg-5">
                <div class="form-card">
                    <h2 class="h5 fw-bold mb-3" style="color:var(--gov-green);" data-i18n="download_steps_title">طريقة التثبيت</h2>
                    <ol class="small mb-3 ps-3 pe-3">
                        <li class="mb-2" data-i18n="download_step1">اضغط زر التحميل أو امسح رمز QR من جوال أندرويد.</li>
                        <li class="mb-2" data-i18n="download_step2">افتح الملف بعد اكتمال التحميل.</li>
                        <li class="mb-2" data-i18n="download_step3">إذا طُلب منك، اسمح بتثبيت التطبيقات من هذا المصدر، ثم اضغط «تثبيت».</li>
                        <li class="mb-2" data-i18n="download_step4">افتح تطبيق «مفقودك» وسجّل الدخول بحسابك نفسه في الموقع.</li>
                    </ol>
                    <div class="alert alert-light border small mb-0">
                        <i class="bi bi-info-circle me-1"></i>
                        <span data-i18n="download_android_only">التطبيق متاح حاليًا لأجهزة أندرويد. يمكن لمستخدمي الأجهزة الأخرى استخدام الموقع بكامل خدماته.</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

<?php
if ($apkExists) {
    // QR code of the full download address (works on any domain the site is served from)
    $footerScripts = '<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>' . PHP_EOL
        . '<script>new QRCode(document.getElementById("apkQr"), {'
        . 'text: new URL(' . json_encode($apkUrl) . ', window.location.href).href,'
        . 'width: 180, height: 180, colorDark: "#0d4a3a", colorLight: "#ffffff"});</script>' . PHP_EOL;
}
require __DIR__ . '/partials/footer.php';
