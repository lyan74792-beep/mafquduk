<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title>منصة مفقودك</title>
    <!-- ربط الخط الرسمي ومكتبة بوتستراب -->
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- تنسيقات الهوية البصرية الرسمية للموقع -->
    <style>
        :root {
            --gov-green: #0d4a3a;       /* أخضر زيتي */
            --gov-green-dark: #072e24;  
            --gov-gold: #9E793E;       /* ذهبي ملكي ناعم */
            --gov-bg-light: #f8faf9;    /* رمادي خفيف جداً للخلفيات */
            --border-color: #e5e7eb;
        }

        body {
            font-family: 'IBM Plex Sans Arabic', 'Noto Sans', sans-serif;
            background-color: #ffffff;
            color: #1f2937;
        }

        /* شريط التنقل العلوي */
        .navbar-gov {
            background-color: #ffffff;
            border-bottom: 2px solid var(--gov-gold);
            padding: 14px 0;
        }

        .brand-title {
            color: var(--gov-green);
            font-weight: 700;
            font-size: 1.6rem;
            letter-spacing: -0.5px;
        }

        /* أزرار الهوية الرسمية */
        .btn-gov-primary {
            background-color: var(--gov-green);
            color: #ffffff;
            font-weight: 600;
            font-size: 0.95rem;
            border: none;
            border-radius: 6px;
            padding: 10px 22px;
            transition: background-color 0.2s;
        }
        .btn-gov-primary:hover {
            background-color: var(--gov-green-dark);
            color: #ffffff;
        }

        /* الواجهة الترحيبية */
        .hero-banner {
            position: relative;
            background-color: var(--gov-bg-light);
            background-image: linear-gradient(to top, rgba(255,255,255,0.92), rgba(255,255,255,0.55)), url('assets/images/haram-hero.jpg');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            border-bottom: 1px solid var(--border-color);
            padding: 100px 0;
        }

        /* بطاقات الخدمات والوظائف */
        .card-gov {
            background-color: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 32px 24px;
            height: 100%;
            transition: all 0.2s ease-in-out;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .card-gov:hover {
            border-color: var(--gov-gold);
            box-shadow: 0 6px 18px rgba(0, 0, 0, 0.03);
        }

        /* بطاقة البلاغ الطارئ */
        .card-gov-emergency {
            border-color: #fca5a5;
            background-color: #fffdfd;
        }
        .card-gov-emergency:hover {
            border-color: #dc2626;
            box-shadow: 0 6px 18px rgba(220, 38, 38, 0.08);
        }

        .icon-box {
            width: 56px;
            height: 56px;
            background-color: var(--gov-bg-light);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            margin-bottom: 20px;
            color: var(--gov-green);
        }

        .section-title {
            color: var(--gov-green);
            font-weight: 700;
            font-size: 1.5rem;
            margin-bottom: 8px;
        }

        /* الفوتر */
        footer {
            background-color: var(--gov-green-dark);
            color: #ffffff;
            padding: 24px 0;
            border-top: 3px solid var(--gov-gold);
        }

        /* روابط وأزرار الشريط العلوي */
        .nav-action {
            color: #374151 !important;
            font-weight: 500;
            font-size: 0.95rem;
            text-decoration: none;
            background: none;
            border: none;
            border-bottom: 2px solid transparent;
            border-radius: 6px 6px 0 0;
            padding: 8px 14px !important;
            margin: 0 2px;
            transition: all 0.15s;
        }
        .nav-action:hover, .nav-action:focus {
            color: var(--gov-green) !important;
            background-color: rgba(13, 74, 58, 0.07);
            border-bottom-color: var(--gov-green);
        }
    </style>
</head>
<body>

    <!-- شريط التنقل العلوي -->
    <nav class="navbar navbar-expand-lg navbar-gov sticky-top">
        <div class="container">
            <a class="navbar-brand brand-title" href="index.php" data-i18n="brand">مفقودك</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item"><a class="nav-action" href="index.php" data-i18n="home">الرئيسية</a></li>
                    <li class="nav-item"><a class="nav-action" href="#services" data-i18n="services_title">الخدمات الإلكترونية</a></li>
                    <li class="nav-item"><a class="nav-action" href="items.php" data-i18n="nav_browse_items">تصفح المفقودات والمعثورات</a></li>
                    <li class="nav-item"><a class="nav-action" href="map.php" data-i18n="nav_map">خريطة البلاغات</a></li>
                    <li class="nav-item"><a class="nav-action" href="#search-section" data-i18n="search_title">الاستعلام عن بلاغ</a></li>
                    <li class="nav-item"><a class="nav-action" href="download.php"><i class="bi bi-phone"></i> <span data-i18n="nav_download_app">تحميل التطبيق</span></a></li>
                </ul>
                <div class="d-flex flex-wrap gap-1 align-items-center">
                    <a href="report_lost.php" class="nav-action" data-i18n="btn_report_lost">تقديم طلب مفقود</a>
                    <a href="report_found.php" class="nav-action" data-i18n="btn_report_found">الإبلاغ عن موجود</a>
                    <a href="report_found.php?kind=sighting" class="nav-action" data-i18n="nav_report_sighting">الإبلاغ عن مشاهدة</a>
                    <a href="login.php" class="nav-action" data-i18n="btn_login"><i class="bi bi-box-arrow-in-left me-1"></i>تسجيل الدخول</a>

                    <!-- مبدل اللغات -->
                    <div class="dropdown">
                        <button class="nav-action dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="bi bi-translate me-1"></i><span id="currentLangLabel">العربية</span>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><button class="dropdown-item lang-option" data-lang="ar" type="button">العربية</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="en" type="button">English</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="ur" type="button">اردو</button></li>
                            <li><button class="dropdown-item lang-option" data-lang="tr" type="button">Türkçe</button></li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- البانر الرئيسي للمنصة -->
    <section class="hero-banner text-center">
        <div class="container">
            <h1 class="display-6 fw-bold mb-3" style="color: var(--gov-green);" data-i18n="hero_title">الخدمة الموحدة لإدارة المفقودات</h1>
            <p class="fs-6 text-muted mb-4 mx-auto" style="max-width: 680px; line-height: 1.8;" data-i18n="hero_desc">
                منصة رقمية متكاملة للتعرف على المفقودات واستردادها داخل الحرم المكي الشريف والمشاعر المقدسة.
            </p>
        </div>
    </section>

    <!-- قسم الخدمات الإلكترونية -->
    <section id="services" class="py-5 bg-white">
        <div class="container py-4">
            <div class="text-center mb-5">
                <h2 class="section-title" data-i18n="services_title">الخدمات الإلكترونية</h2>
                <p class="text-muted small" data-i18n="services_desc">اختر الخدمة المطلوبة لبدء إجراءات البلاغ أو الاستعلام</p>
            </div>

            <div class="row g-4">
                <!-- خدمة 1: تسجيل بلاغ مفقودات -->
                <div class="col-md-6 col-lg-3">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box">📋</div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service1_title">تسجيل بلاغ مفقودات</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service1_desc">تتيح للزائر إدخال بيانات الغرض المفقود وتحديد الموقع الجغرافي للفقدان لتسهيل عملية المطابقة.</p>
                        </div>
                        <a href="report_lost.php" class="text-decoration-none fw-bold small" style="color: var(--gov-green);" data-i18n="start_service">بدء الخدمة &larr;</a>
                    </div>
                </div>

                <!-- خدمة 2: تسجيل غرض معثور عليه -->
                <div class="col-md-6 col-lg-3">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box" style="color: var(--gov-gold);">📦</div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service2_title">تسجيل غرض معثور عليه</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service2_desc">تسمح للمكتشفين والجهات الإبلاغ عن الأغراض التي تم العثور عليها وتحديد حالة التسليم.</p>
                        </div>
                        <a href="report_found.php" class="text-decoration-none fw-bold small" style="color: var(--gov-gold);" data-i18n="start_service">بدء الخدمة &larr;</a>
                    </div>
                </div>

                <!-- خدمة 3: بلاغ طارئ (جديد) -->
                <div class="col-md-6 col-lg-3">
                    <div class="card-gov card-gov-emergency">
                        <div>
                            <div class="icon-box bg-danger-subtle border-danger-subtle text-danger">
                                <i class="bi bi-exclamation-triangle-fill fs-4"></i>
                            </div>
                            <h5 class="fw-bold mb-2 fs-6 text-danger" data-i18n="service_emergency_title">بلاغ طارئ (طفل / مسن)</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service_emergency_desc">خدمة عاجلة ومباشرة للإبلاغ الفوري عن تائهين بالحرم والمشاعر لإشعارات فورية لفرق البحث.</p>
                        </div>
                        <a href="report_emergency.php" class="text-decoration-none fw-bold small text-danger" data-i18n="service_emergency_btn">تقديم بلاغ طارئ &larr;</a>
                    </div>
                </div>

                <!-- خدمة 4: الاستعلام والمطابقة -->
                <div class="col-md-6 col-lg-3">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box">🔎</div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service3_title">المطابقة والاستعلام الآلي</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service3_desc">نظام آلي يقوم بمطابقة المواصفات بين البلاغات المسجلة والمعثورات بشكل مستمر.</p>
                        </div>
                        <a href="#search-section" class="text-decoration-none fw-bold small" style="color: var(--gov-green);" data-i18n="track_report">متابعة البلاغ &larr;</a>
                    </div>
                </div>

                <!-- خدمة 5: تصفح المفقودات والمعثورات -->
                <div class="col-md-6 col-lg-4">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box"><i class="bi bi-grid-3x3-gap"></i></div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service_browse_title">تصفح المفقودات والمعثورات</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service_browse_desc">استعراض البلاغات المسجلة والبحث فيها حسب التصنيف أو الكلمات المفتاحية للتعرف على غرضك.</p>
                        </div>
                        <a href="items.php" class="text-decoration-none fw-bold small" style="color: var(--gov-green);" data-i18n="service_browse_btn">تصفح البلاغات &larr;</a>
                    </div>
                </div>

                <!-- خدمة 6: خريطة البلاغات التفاعلية -->
                <div class="col-md-6 col-lg-4">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box"><i class="bi bi-geo-alt"></i></div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service_map_title">خريطة البلاغات التفاعلية</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service_map_desc">عرض مواقع المفقودات والمعثورات جغرافيًا داخل الحرم المكي الشريف والمشاعر المقدسة.</p>
                        </div>
                        <a href="map.php" class="text-decoration-none fw-bold small" style="color: var(--gov-green);" data-i18n="service_map_btn">فتح الخريطة &larr;</a>
                    </div>
                </div>

                <!-- خدمة 7: الإبلاغ عن مشاهدة غرض -->
                <div class="col-md-6 col-lg-4">
                    <div class="card-gov">
                        <div>
                            <div class="icon-box" style="color: var(--gov-gold);"><i class="bi bi-eye"></i></div>
                            <h5 class="fw-bold mb-2 fs-6" data-i18n="service_sighting_title">الإبلاغ عن مشاهدة غرض</h5>
                            <p class="text-secondary small mb-4" style="line-height: 1.6;" data-i18n="service_sighting_desc">الإبلاغ السريع عن غرض شاهدته في مكانه دون أخذه لتسهيل وصول صاحبه أو الفرق الميدانية إليه.</p>
                        </div>
                        <a href="report_found.php?kind=sighting" class="text-decoration-none fw-bold small" style="color: var(--gov-gold);" data-i18n="service_sighting_btn">إبلاغ عن مشاهدة &larr;</a>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- تطبيق الجوال -->
    <section id="app-download" class="py-4" style="background-color: var(--gov-green);">
        <div class="container">
            <div class="d-flex flex-column flex-md-row align-items-center justify-content-between gap-3 text-white">
                <div class="d-flex align-items-center gap-3">
                    <i class="bi bi-phone" style="font-size:2.4rem;color:var(--gov-gold);"></i>
                    <div>
                        <h3 class="h5 fw-bold mb-1" data-i18n="home_app_title">تطبيق مفقودك على جوالك</h3>
                        <p class="mb-0 small opacity-75" data-i18n="home_app_desc">كل خدمات المنصة في تطبيق أندرويد: البلاغات، المطابقات، الاسترداد والتنبيهات.</p>
                    </div>
                </div>
                <a href="download.php" class="btn btn-light fw-bold px-4">
                    <i class="bi bi-android2 me-1"></i> <span data-i18n="download_button">تحميل التطبيق للأندرويد</span>
                </a>
            </div>
        </div>
    </section>

    <!-- شريط البحث والاستعلام -->
    <section id="search-section" class="py-5" style="background-color: var(--gov-bg-light); border-top: 1px solid var(--border-color);">
        <div class="container py-3">
            <div class="row justify-content-center">
                <div class="col-md-8 text-center">
                    <h3 class="section-title mb-2" data-i18n="search_title">الاستعلام عن حالة بلاغ</h3>
                    <p class="text-muted small mb-4" data-i18n="search_desc">أدخل رقم البلاغ لمتابعة حالة المطابقة والاسترداد</p>
                    
                    <form id="trackForm" class="row g-2 justify-content-center mb-4">
                        <div class="col-md-7">
                            <input type="text" id="track_query" class="form-control form-control-lg fs-6" data-i18n-placeholder="search_placeholder" placeholder="أدخل رقم البلاغ" required>
                        </div>
                        <div class="col-md-3">
                            <button class="btn btn-gov-primary btn-lg w-100 fs-6" type="submit" data-i18n="search_btn">بحث</button>
                        </div>
                    </form>

                    <!-- منطقة نتائج البحث فارغة بانتظار الربط الحقيقي -->
                    <div id="searchResults" class="d-none mt-4 text-start bg-white p-4 rounded border shadow-sm">
                        <!-- سيتم عرض البيانات هنا لاحقاً -->
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- الفوتر الرسمي -->
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
   
</body>
</html>