<?php
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('admin');

$adm         = array('lost' => 0, 'found' => 0, 'pending' => 0, 'claims' => 0);
$adm_rows    = array();
$emergencies = array();
$claims      = array();
$approved    = array();
$found_opts  = array();
$lost_opts   = array();
$kpi         = array('avg_hours' => null, 'top_place' => null, 'top_place_cnt' => 0, 'top_cat' => null, 'top_cat_pct' => 0, 'match_rate' => null);
$cat_dist    = array();
$loc_dist    = array();
$geo         = array();

// طلبات الشحن (مع فلتر الحالة) وحسابات المشرفين المعلقة
$ship_statuses  = array('pending', 'approved', 'shipped', 'delivered', 'rejected');
$ship_filter    = (isset($_GET['ship_status']) && in_array($_GET['ship_status'], $ship_statuses, true)) ? $_GET['ship_status'] : '';
$shipping       = array();
$pending_admins = array();
try {
    $shipping       = shipping_list_all($conn, $ship_filter)['requests'];
    $pending_admins = admin_pending_admins($conn)['admins'];
} catch (Exception $e) {
    error_log('admin shipping/accounts: ' . $e->getMessage());
}

// 1. جلب البلاغات الطارئة الخاصة بالأشخاص التائهين (أولوية قصوى)
try {
    $emData      = admin_emergencies($conn, 'active');
    $emergencies = $emData['emergencies'];
} catch (Exception $e) {
    error_log('emergency fetch error: ' . $e->getMessage());
}

// 2. المؤشرات والإحصائيات والخرائط الحرارية
try {
    $stats          = admin_stats($conn);
    $adm['lost']    = (int)$stats['total_lost'];
    $adm['found']   = (int)$stats['total_found'];
    $adm['pending'] = (int)$stats['pending_matches'];
    $adm['claims']  = (int)$stats['claims_under_review'];

    $kpi['avg_hours'] = $stats['avg_review_hours'];
    $cat_dist         = $stats['by_category'];
    if ($cat_dist) {
        $tot                = array_sum(array_column($cat_dist, 'count'));
        $kpi['top_cat']     = $cat_dist[0]['name'];
        $kpi['top_cat_pct'] = $tot ? (int)round($cat_dist[0]['count'] * 100 / $tot) : 0;
    }

    $loc_dist = $stats['top_locations'];
    if ($loc_dist) {
        $kpi['top_place']     = $loc_dist[0]['name'];
        $kpi['top_place_cnt'] = (int)$loc_dist[0]['count'];
    }

    $geo = $stats['heat_points'];
} catch (Exception $e) {
    error_log('admin stats: ' . $e->getMessage());
}

// 3. البلاغات (المفقودات والمعثورات)
try {
    $repData  = admin_reports($conn, 'all');
    $adm_rows = $repData['reports'];
} catch (Exception $e) {
    error_log('admin reports: ' . $e->getMessage());
}

// 4. طلبات التحقق من الملكية والمستردات
try {
    $claims    = claim_admin_list($conn, 'Under Review')['claims'];
    $approved  = claim_admin_list($conn, 'Approved')['claims'];
    $allClaims = claim_admin_list($conn, 'all')['claims'];
    $okClaims      = 0;
    $decidedClaims = 0;
    foreach ($allClaims as $cItem) {
        if (in_array($cItem['status'], array('Approved', 'Delivered'), true)) {
            $okClaims++;
            $decidedClaims++;
        } elseif ($cItem['status'] === 'Rejected') {
            $decidedClaims++;
        }
    }
    if ($decidedClaims > 0) {
        $kpi['match_rate'] = (int)round($okClaims * 100 / $decidedClaims);
    }
} catch (Exception $e) {
    error_log('claims: ' . $e->getMessage());
}

// 5. عناصر الربط اليدوي المفتوحة
try {
    $openItems  = admin_open_items($conn);
    $found_opts = $openItems['found'];
    $lost_opts  = $openItems['lost'];
} catch (Exception $e) {
    error_log('match opts: ' . $e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="assets/images/favicon.png">
    <link rel="apple-touch-icon" href="assets/images/apple-touch-icon.png">
    <title>لوحة فريق الإدارة - منصة مفقودك</title>
    <link id="bootstrap-css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.rtl.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=Noto+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link rel="stylesheet" href="assets/css/style.css?v=7">
<style>
        .an-head { margin-bottom: 20px; }
        .an-stat { background:#fff; border:1px solid var(--border-color); border-radius:10px; padding:20px; text-align:center; height:100%; }
        .an-stat > i { font-size:1.4rem; color:var(--gov-gold); }
        .an-value { font-size:1.8rem; font-weight:700; color:#9ca3af; margin:8px 0 4px; }
        .an-label { font-weight:600; color:var(--gov-green); font-size:.95rem; }
        .an-hint { font-size:.8rem; color:#9ca3af; margin-top:4px; }
        .an-card { background:#fff; border:1px solid var(--border-color); border-radius:10px; padding:18px; }
        .an-card-head { display:flex; flex-wrap:wrap; justify-content:space-between; align-items:center; gap:8px; margin-bottom:14px; }
        .an-card-head h5 { color:var(--gov-green); font-weight:700; font-size:1.05rem; margin:0; }
        .an-note { font-size:.8rem; color:#6b7280; }
        .an-map-wrap { position:relative; }
        #heatmapContainer { height:380px; width:100%; border-radius:8px; }
        .an-map-empty { position:absolute; top:12px; left:50%; transform:translateX(-50%); z-index:500; background:rgba(255,255,255,.95); border:1px solid var(--border-color); border-radius:20px; padding:6px 16px; font-size:.85rem; color:#6b7280; white-space:nowrap; }
        .an-empty { min-height:200px; display:flex; align-items:center; justify-content:center; color:#9ca3af; font-size:.9rem; text-align:center; border:1px dashed var(--border-color); border-radius:8px; padding:16px; }
        .an-bar { margin-bottom:12px; }
        .an-bar-label { display:flex; justify-content:space-between; font-size:.88rem; margin-bottom:4px; color:#374151; gap:8px; }
        .an-bar-track { height:10px; background:#eef2f1; border-radius:6px; overflow:hidden; }
        .an-bar-fill { height:100%; background:linear-gradient(90deg,#0d4a3a,#9E793E); border-radius:6px; }
        .img-preview-table { width: 45px; height: 45px; object-fit: cover; border-radius: 6px; border: 1px solid var(--border-color); transition: transform 0.2s; }
        .img-preview-table:hover { transform: scale(1.15); }
        .nav-btn-emergency { color: #dc3545 !important; }
        .nav-btn-emergency.active, .nav-btn-emergency:hover { background-color: #f8d7da !important; color: #842029 !important; }
    </style>
</head>
<body class="page-form">

<nav class="navbar navbar-expand-lg navbar-gov">
    <div class="container-fluid px-4">
        <!-- عنوان المنصة -->
        <a class="navbar-brand brand-title" href="index.php" data-i18n="brand">مفقودك</a>
        
        <div class="d-flex gap-2 align-items-center">
            
            <!-- 1. قائمة اختيار اللغة -->
            <div class="dropdown">
                <button class="btn btn-outline-secondary btn-sm dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                    <i class="bi bi-translate me-1"></i><span id="currentLangLabel">العربية</span>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow-sm">
                    <li><button class="dropdown-item lang-option" data-lang="ar" type="button">العربية</button></li>
                    <li><button class="dropdown-item lang-option" data-lang="en" type="button">English</button></li>
                    <li><button class="dropdown-item lang-option" data-lang="ur" type="button">اردو</button></li>
                    <li><button class="dropdown-item lang-option" data-lang="tr" type="button">Türkçe</button></li>
                </ul>
            </div>

            <!-- 2. زر الحساب الحكومي الموحد (الاسم مخفي ويظهر فقط بعد النقر) -->
            <div class="dropdown">
                <button class="btn btn-outline-secondary btn-sm dropdown-toggle d-flex align-items-center gap-1" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                    <i class="bi bi-person-badge-fill text-success fs-6"></i>
                    <span data-i18n="sb_admin_name">الحساب الإداري</span>
                </button>
                
                <!-- القائمة المنسدلة التي تنبثق عند الضغط -->
                <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 mt-2 p-2" style="min-width: 220px;">
                    <!-- كرت معلومات المشرف التي تظهر داخل القائمة -->
                    <li class="px-3 py-2 bg-light rounded-3 mb-2">
                        <div class="text-muted extra-small" style="font-size: 0.75rem;" data-i18n="adm_logged_in_as">المشرف المسجل حالياً:</div>
                        <div class="fw-bold text-dark text-truncate fs-6">
                            <?php if (!empty($_SESSION['name'])): ?>
                                <?php echo e($_SESSION['name']); ?>
                            <?php else: ?>
                                <span data-i18n="adm_default_admin">أدمن النظام</span>
                            <?php endif; ?>
                        </div>
                    </li>
                    
                    <li><hr class="dropdown-divider my-1"></li>
                    
                    <!-- خيار تسجيل الخروج -->
                    <li>
                        <a class="dropdown-item text-danger d-flex align-items-center gap-2 rounded-2 py-2" href="logout.php">
                            <i class="bi bi-box-arrow-right"></i>
                            <span data-i18n="btn_logout">تسجيل الخروج</span>
                        </a>
                    </li>
                </ul>
            </div>

        </div>
    </div>
</nav>

    <?php render_flash(); ?>
    <div class="container-fluid admin-wrap">
        <div class="row g-4">

            <!-- القائمة الجانبية الثابتة (يمين) -->
            <aside class="col-lg-3 col-xl-2">
                <nav class="admin-sidebar" role="tablist">
                    <button type="button" class="admin-nav-btn active" data-panel="panel-overview">
                        <i class="bi bi-speedometer2"></i><span data-i18n="admin_overview">نظرة عامة</span>
                    </button>

                    <!-- القسم الجانبي المنفصل للبلاغات الطارئة -->
                    <button type="button" class="admin-nav-btn nav-btn-emergency d-flex align-items-center justify-content-between" data-panel="panel-emergency">
                        <span><i class="bi bi-exclamation-triangle-fill text-danger me-1"></i> <span data-i18n="adm_nav_emergency">بلاغات الطوارئ</span></span>
                        <?php if (!empty($emergencies)): ?>
                            <span class="badge bg-danger rounded-pill"><?php echo (int)count($emergencies); ?></span>
                        <?php endif; ?>
                    </button>

                    <button type="button" class="admin-nav-btn" data-panel="panel-analytics">
                        <i class="bi bi-graph-up-arrow"></i><span data-i18n="adm_analytics">المؤشرات والخرائط الحرارية</span>
                    </button>
                    <button type="button" class="admin-nav-btn" data-panel="panel-reports">
                        <i class="bi bi-folder2-open"></i><span data-i18n="admin_reports">البلاغات</span>
                    </button>
                    <button type="button" class="admin-nav-btn" data-panel="panel-verify">
                        <i class="bi bi-patch-check"></i><span data-i18n="admin_verify">التحقق من الملكية</span>
                    </button>
                    <button type="button" class="admin-nav-btn" data-panel="panel-returns">
                        <i class="bi bi-box-seam"></i><span data-i18n="admin_returns">المستردات</span>
                    </button>
                    <button type="button" class="admin-nav-btn" data-panel="panel-shipping">
                        <i class="bi bi-truck"></i><span data-i18n="adm_shipping">إدارة الشحنات والتوصيل</span>
                    </button>
                    <button type="button" class="admin-nav-btn d-flex align-items-center justify-content-between" data-panel="panel-accounts">
                        <span><i class="bi bi-person-badge me-1"></i><span data-i18n="adm_accounts">حسابات المشرفين</span></span>
                        <?php if (!empty($pending_admins)): ?>
                            <span class="badge bg-warning text-dark rounded-pill"><?php echo (int)count($pending_admins); ?></span>
                        <?php endif; ?>
                    </button>
                </nav>
            </aside>

            <!-- محتوى الأقسام -->
            <main class="col-lg-9 col-xl-10">

                <!-- 1. نظرة عامة -->
                <section class="admin-panel active" id="panel-overview">
                    <h2 class="dash-title mb-4" data-i18n="admin_overview">نظرة عامة</h2>
                    <div class="row g-3 mb-4">
                        <div class="col-sm-6 col-xl-3">
                            <div class="stat-card">
                                <div class="stat-icon"><i class="bi bi-search"></i></div>
                                <div><div class="stat-number"><?php echo (int)$adm['lost']; ?></div><div class="small text-muted" data-i18n="adm_stat_lost">بلاغات المفقودات</div></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="stat-card">
                                <div class="stat-icon"><i class="bi bi-box"></i></div>
                                <div><div class="stat-number"><?php echo (int)$adm['found']; ?></div><div class="small text-muted" data-i18n="adm_stat_found">المعثورات المسجلة</div></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="stat-card">
                                <div class="stat-icon"><i class="bi bi-link-45deg"></i></div>
                                <div><div class="stat-number"><?php echo (int)$adm['pending']; ?></div><div class="small text-muted" data-i18n="adm_stat_matches">مطابقات بانتظار المراجعة</div></div>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="stat-card">
                                <div class="stat-icon"><i class="bi bi-patch-check"></i></div>
                                <div><div class="stat-number"><?php echo (int)$adm['claims']; ?></div><div class="small text-muted" data-i18n="adm_stat_claims">طلبات استرداد جديدة</div></div>
                            </div>
                        </div>
                    </div>
                    <h5 class="fw-bold mb-3" style="color: var(--gov-green);" data-i18n="admin_recent">آخر النشاط</h5>
                    <div class="text-muted small py-3" data-i18n="adm_no_activity">لا توجد أنشطة حديثة مسجلة حتى الآن.</div>
                </section>

                <!-- قسم مستقل للبلاغات الطارئة -->
                <section class="admin-panel" id="panel-emergency">
                    <h2 class="dash-title mb-3 text-danger"><i class="bi bi-exclamation-triangle-fill me-2"></i><span data-i18n="adm_em_title">بلاغات الطوارئ العاجلة</span></h2>
                    <p class="text-muted small mb-4" data-i18n="adm_em_subtitle">قائمة بلاغات الأشخاص التائهين (الأطفال وكبار السن) للتواصل المباشر والإنقاذ السريع.</p>

                    <div class="card border-danger mb-4 shadow-sm">
                        <div class="card-header bg-danger text-white d-flex justify-content-between align-items-center py-2">
                            <h5 class="mb-0 fs-6 fw-bold" data-i18n="adm_em_active_title">حالات التائهين النشطة</h5>
                            <span class="badge bg-white text-danger fw-bold"><?php echo (int)count($emergencies); ?> <span data-i18n="adm_em_pending_suffix">حالة معلقة</span></span>
                        </div>
                        <div class="card-body p-0">
                            <?php if (empty($emergencies)): ?>
                                <div class="text-center text-muted small py-5">
                                    <i class="bi bi-check-circle text-success fs-3 d-block mb-2"></i>
                                    <span data-i18n="adm_em_empty">لا توجد بلاغات طوارئ نشطة حالياً.</span>
                                </div>
                            <?php else: ?>
                                <div class="table-responsive">
                                    <table class="table table-hover align-middle mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th data-i18n="th_no">الرقم</th>
                                                <th data-i18n="th_photo">الصورة</th>
                                                <th data-i18n="adm_th_person">الاسم / الوصف</th>
                                                <th data-i18n="adm_th_age">العمر</th>
                                                <th data-i18n="adm_th_last_seen">آخر موقع شوهد فيه</th>
                                                <th data-i18n="adm_th_clothing">وصف الملابس</th>
                                                <th data-i18n="label_phone">رقم التواصل</th>
                                                <th data-i18n="th_date">التاريخ</th>
                                                <th data-i18n="th_action">الإجراء</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ($emergencies as $em): ?>
                                            <tr class="table-danger-subtle">
                                                <td class="fw-bold text-danger">#EM-<?php echo (int)$em['id']; ?></td>
                                                <td>
                                                    <?php if (!empty($em['photo_url'])): ?>
                                                        <a href="<?php echo e($em['photo_url']); ?>" target="_blank">
                                                            <img src="<?php echo e($em['photo_url']); ?>" alt="<?php echo e($em['person_name'] ?: ''); ?>" class="img-preview-table" style="border-color: #dc3545;">
                                                        </a>
                                                    <?php else: ?>
                                                        <span class="text-muted small">—</span>
                                                    <?php endif; ?>
                                                </td>
                                                <td>
                                                    <?php if (!empty($em['person_name'])): ?>
                                                        <strong><?php echo e($em['person_name']); ?></strong>
                                                    <?php else: ?>
                                                        <strong data-i18n="adm_unspecified">غير محدد</strong>
                                                    <?php endif; ?>
                                                </td>
                                                <td><?php echo e($em['approx_age']); ?></td>
                                                <td><span class="badge text-bg-warning"><?php echo e($em['last_seen_location']); ?></span></td>
                                                <td class="small"><?php echo e($em['clothing_description']); ?></td>
                                                <td>
                                                    <a href="tel:<?php echo e($em['reporter_phone']); ?>" class="btn btn-sm btn-outline-danger dir-ltr">
                                                        <i class="bi bi-telephone-fill me-1"></i><?php echo e($em['reporter_phone']); ?>
                                                    </a>
                                                </td>
                                                <td class="small text-muted"><?php echo e(substr((string)$em['created_at'], 0, 16)); ?></td>
                                                <td>
                                                    <form method="POST" action="resolve_emergency.php" style="display:inline;">
                                                        <input type="hidden" name="emergency_id" value="<?php echo (int)$em['id']; ?>">
                                                        <button type="submit" class="btn btn-success btn-sm">
                                                            <i class="bi bi-check-circle me-1"></i><span data-i18n="adm_btn_mark_found">تم العثور عليه</span>
                                                        </button>
                                                    </form>
                                                </td>
                                            </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                </section>

                <!-- 2. المؤشرات والخرائط الحرارية (بدون بيانات وهمية: تُملأ من القاعدة) -->
                <section class="admin-panel" id="panel-analytics">
                    <div class="an-head">
                        <h2 class="dash-title mb-1" data-i18n="adm_an_title">لوحة الذكاء التشغيلي والخرائط الحرارية الميدانية</h2>
                        <p class="text-muted small mb-0" data-i18n="adm_an_desc">مؤشرات إحصائية وتحليل جغرافي لدعم متخذي القرار بالمشاعر المقدسة والحرم المكي.</p>
                    </div>

                    <div class="row g-3 mb-4">
                        <div class="col-sm-6 col-xl-3">
                            <div class="an-stat">
                                <i class="bi bi-clock"></i>
                                <div class="an-value">
                                    <?php if ($kpi['avg_hours'] !== null): ?>
                                        <?php echo e((string)$kpi['avg_hours']); ?> <span data-i18n="adm_hours_unit">ساعة</span>
                                    <?php else: ?>
                                        —
                                    <?php endif; ?>
                                </div>
                                <div class="an-label" data-i18n="adm_an_avg">متوسط زمن الاسترجاع</div>
                                <?php if ($kpi['avg_hours'] !== null): ?>
                                    <div class="an-hint" data-i18n="adm_from_claim_to_approval">من طلب الاسترداد إلى الموافقة</div>
                                <?php else: ?>
                                    <div class="an-hint" data-i18n="adm_wait_recovery">بانتظار أول عملية استرداد</div>
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="an-stat">
                                <i class="bi bi-geo-alt"></i>
                                <div class="an-value"><span style="font-size:1.1rem"><?php echo e($kpi['top_place'] ?: '—'); ?></span></div>
                                <div class="an-label" data-i18n="adm_an_top_place">أكثر الأماكن فقدًا</div>
                                <?php if ($kpi['top_place']): ?>
                                    <div class="an-hint"><?php echo (int)$kpi['top_place_cnt']; ?> <span data-i18n="adm_reports_unit">بلاغ</span></div>
                                <?php else: ?>
                                    <div class="an-hint" data-i18n="adm_wait_reports">بانتظار البلاغات</div>
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="an-stat">
                                <i class="bi bi-phone"></i>
                                <div class="an-value"><span style="font-size:1.1rem"><?php echo e($kpi['top_cat'] ?: '—'); ?></span></div>
                                <div class="an-label" data-i18n="adm_an_top_item">الأكثر تكرارًا بالبلاغات</div>
                                <?php if ($kpi['top_cat']): ?>
                                    <div class="an-hint"><?php echo (int)$kpi['top_cat_pct']; ?>% <span data-i18n="adm_of_reports">من البلاغات</span></div>
                                <?php else: ?>
                                    <div class="an-hint" data-i18n="adm_wait_reports">بانتظار البلاغات</div>
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="col-sm-6 col-xl-3">
                            <div class="an-stat">
                                <i class="bi bi-shield-check"></i>
                                <div class="an-value"><?php echo $kpi['match_rate'] !== null ? (int)$kpi['match_rate'] . '%' : '—'; ?></div>
                                <div class="an-label" data-i18n="adm_an_match_rate">نسبة النجاح بالمطابقة</div>
                                <?php if ($kpi['match_rate'] !== null): ?>
                                    <div class="an-hint" data-i18n="adm_from_decided_matches">من المطابقات المحسومة</div>
                                <?php else: ?>
                                    <div class="an-hint" data-i18n="adm_wait_matches">بانتظار المطابقات</div>
                                <?php endif; ?>
                            </div>
                        </div>
                    </div>

                    <div class="an-card mb-4">
                        <div class="an-card-head">
                            <h5><i class="bi bi-map me-2"></i><span data-i18n="adm_map_title">الخريطة الحرارية لكثافة الفقدان بالحرم والمشاعر</span></h5>
                            <span class="an-note"><i class="bi bi-info-circle me-1"></i><span data-i18n="adm_map_note">تظهر المناطق الأعلى تركيزًا للبلاغات</span></span>
                        </div>
                        <div class="an-map-wrap">
                            <div id="heatmapContainer"></div>
                            <div class="an-map-empty" data-i18n="adm_map_empty">لا توجد بلاغات بإحداثيات بعد</div>
                        </div>
                    </div>

                    <div class="row g-4">
                        <div class="col-lg-6">
                            <div class="an-card h-100">
                                <div class="an-card-head"><h5 data-i18n="adm_chart_cat">توزيع الفقدان حسب التصنيف</h5></div>
                                <?php if (!$cat_dist): ?><div class="an-empty" data-i18n="adm_no_dist">لا توجد بيانات كافية لعرض التوزيع.</div>
                                <?php else: $tot_c = array_sum(array_column($cat_dist, 'count')); foreach ($cat_dist as $b): $p = $tot_c ? (int)round($b['count'] * 100 / $tot_c) : 0; ?>
                                <div class="an-bar"><div class="an-bar-label"><span><?php echo e($b['name']); ?></span><span><?php echo (int)$b['count']; ?> (<?php echo (int)$p; ?>%)</span></div><div class="an-bar-track"><div class="an-bar-fill" style="width:<?php echo (int)$p; ?>%"></div></div></div>
                                <?php endforeach; endif; ?>
                            </div>
                        </div>
                        <div class="col-lg-6">
                            <div class="an-card h-100">
                                <div class="an-card-head"><h5 data-i18n="adm_chart_loc">أعلى المواقع تسجيلاً للبلاغات</h5></div>
                                <?php if (!$loc_dist): ?><div class="an-empty" data-i18n="adm_no_loc">لا توجد بيانات كافية لعرض المواقع.</div>
                                <?php else: $max_l = max(1, (int)$loc_dist[0]['count']); foreach ($loc_dist as $b): $p = (int)round((int)$b['count'] * 100 / $max_l); ?>
                                <div class="an-bar"><div class="an-bar-label"><span><?php echo e($b['name']); ?></span><span><?php echo (int)$b['count']; ?> <span data-i18n="adm_reports_unit">بلاغ</span></span></div><div class="an-bar-track"><div class="an-bar-fill" style="width:<?php echo (int)$p; ?>%"></div></div></div>
                                <?php endforeach; endif; ?>
                            </div>
                        </div>
                    </div>
                </section>

                <!-- 3. البلاغات -->
                <section class="admin-panel" id="panel-reports">
                    <h2 class="dash-title mb-3" data-i18n="admin_reports">البلاغات</h2>
                    <div class="an-card mb-4">
                        <h5 class="mb-2" style="color:var(--gov-green);font-weight:700;" data-i18n="adm_mm_title">المطابقة والتنسيق اليدوي</h5>
                        <p class="small text-muted mb-3" data-i18n="adm_mm_desc">تتيح هذه الخدمة لمشرفي النظام ربط المعثورات بالبلاغات المسجلة يدوياً، حيث يتم إرسال إشعار فوري لصاحب البلاغ لمعاينة الغرض وتحديد ملكيته.</p>
                        <?php if (!$found_opts || !$lost_opts): ?>
                            <div class="small text-muted" data-i18n="adm_mm_empty">تتطلب هذه الخدمة وجود غرض معثور وبلاغ مفقود نَشِطين في النظام على الأقل.</div>
                        <?php else: ?>
                        <form method="POST" action="manual_match.php" class="row g-2 align-items-end">
                            <div class="col-md-5">
                                <label class="form-label small fw-bold" data-i18n="adm_mm_found_label">الغرض المعثور</label>
                                <select name="found_id" class="form-select form-select-sm" required>
                                    <?php foreach ($found_opts as $fo): ?>
                                        <option value="<?php echo (int)$fo['id']; ?>">#<?php echo (int)$fo['id']; ?> - <?php echo e($fo['item_name']); ?> (<?php echo e($fo['category'] ?: '—'); ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-5">
                                <label class="form-label small fw-bold" data-i18n="adm_mm_lost_label">البلاغ المفقود</label>
                                <select name="lost_id" class="form-select form-select-sm" required>
                                    <?php foreach ($lost_opts as $lo): ?>
                                        <option value="<?php echo (int)$lo['id']; ?>">#<?php echo (int)$lo['id']; ?> - <?php echo e($lo['item_name']); ?> (<?php echo e($lo['category'] ?: '—'); ?>)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <button type="submit" class="btn btn-gov-primary btn-sm w-100" data-i18n="adm_mm_submit">ربط وإرسال</button>
                            </div>
                        </form>
                        <?php endif; ?>
                    </div>
                    <div class="table-responsive">
                        <table class="table admin-table align-middle">
                            <thead>
                                <tr>
                                    <th data-i18n="th_no">الرقم</th>
                                    <th data-i18n="th_photo">الصورة</th>
                                    <th data-i18n="th_type">النوع</th>
                                    <th data-i18n="th_cat">التصنيف</th>
                                    <th data-i18n="th_nearest">أقرب معلم</th>
                                    <th data-i18n="th_date">التاريخ</th>
                                    <th data-i18n="th_status">الحالة</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php if (!$adm_rows): ?>
                                <tr><td colspan="7" class="text-center text-muted small py-4" data-i18n="no_reports">لا توجد بلاغات مسجلة حتى الآن.</td></tr>
                            <?php else: foreach ($adm_rows as $r): ?>
                                <tr>
                                    <td class="fw-bold">#<?php echo (int)$r['id']; ?></td>
                                    <td>
                                        <?php if (!empty($r['image_url'])): ?>
                                            <a href="<?php echo e($r['image_url']); ?>" target="_blank">
                                                <img src="<?php echo e($r['image_url']); ?>" alt="<?php echo e($r['item_name']); ?>" class="img-preview-table">
                                            </a>
                                        <?php else: ?>
                                            <span class="text-muted small">—</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php if ($r['type'] === 'lost'): ?>
                                            <span class="badge text-bg-secondary" data-i18n="type_lost"><?php echo e(msg('report.type_lost')); ?></span>
                                        <?php else: ?>
                                            <span class="badge text-bg-warning" data-i18n="type_found"><?php echo e(msg('report.type_found')); ?></span>
                                        <?php endif; ?>
                                    </td>
                                    <td><?php echo lv($r['category']); ?></td>
                                    <td><?php echo lv($r['location']); ?></td>
                                    <td><?php echo e(substr((string)$r['date'], 0, 10)); ?></td>
                                    <td><?php echo e($r['status_label']); ?></td>
                                </tr>
                            <?php endforeach; endif; ?>
                            </tbody>
                        </table>
                    </div>
                </section>

                <!-- 4. التحقق من الملكية -->
                <section class="admin-panel" id="panel-verify">
                    <h2 class="dash-title mb-3" data-i18n="admin_verify">التحقق من الملكية</h2>
                    <p class="text-muted small mb-4" data-i18n="admin_verify_hint">طلبات استرداد مقدّمة من الأفراد. يُرجى مراجعة وتدقيق وصف العلامات الفارقة قبل القبول.</p>
                    <?php if (!$claims): ?>
                        <div class="text-muted small py-4 text-center" data-i18n="adm_no_verify">لا توجد طلبات إثبات ملكية معلقة حالياً. تظهر الطلبات في هذه القائمة فور تأكيد المستفيد لملكيته للغرض.</div>
                    <?php else: foreach ($claims as $cl): ?>
                        <?php
                        $clItem       = $cl['item'];
                        $claimant     = $cl['claimant'];
                        $normCorrect  = mb_strtolower(preg_replace('/\s+/u', '', (string)($cl['correct_answer'] ?? '')), 'UTF-8');
                        $normClaimant = mb_strtolower(preg_replace('/\s+/u', '', (string)($cl['security_answer'] ?? '')), 'UTF-8');
                        $qaEqual      = ($normCorrect !== '' && $normCorrect === $normClaimant);
                        $qaBoxClass   = $qaEqual ? 'border-success bg-success-subtle text-success-emphasis' : 'border-danger bg-danger-subtle text-danger-emphasis';
                        $qaBadgeClass = $qaEqual ? 'text-bg-success' : 'text-bg-danger';
                        ?>
                        <div class="an-card mb-3">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <h5 class="mb-0" style="color:var(--gov-green);font-weight:700;"><?php echo e($clItem['item_name']); ?></h5>
                                <span class="badge text-bg-warning"><span data-i18n="adm_claim_badge_prefix">طلب</span> #<?php echo (int)$cl['claim_id']; ?></span>
                            </div>
                            <p class="small text-muted mb-1">
                                <span data-i18n="adm_claimant_label">مقدّم الطلب:</span>
                                <strong><?php echo e($claimant['full_name']); ?></strong> (<?php echo e($claimant['email']); ?>)
                            </p>
                            <p class="small text-muted mb-1">
                                <span data-i18n="th_cat">التصنيف</span>: <?php echo lv($clItem['category']); ?> &middot;
                                <span data-i18n="th_nearest">أقرب معلم</span>: <?php echo lv($clItem['location']); ?>
                            </p>
                            <p class="small mb-2">
                                <strong data-i18n="adm_claim_desc_label">وصف صاحب الغرض:</strong>
                                <?php echo e($cl['claim_description']); ?>
                            </p>

                            <div class="p-3 rounded border mb-3 <?php echo $qaBoxClass; ?>" style="background-color: <?php echo $qaEqual ? '#d1e7dd' : '#f8d7da'; ?>; color: <?php echo $qaEqual ? '#0f5132' : '#842029'; ?>;">
                                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-2">
                                    <div class="small">
                                        <strong data-i18n="claim_sec_question_label">سؤال الأمان:</strong>
                                        <span><?php echo e($cl['security_question'] !== null && $cl['security_question'] !== '' ? $cl['security_question'] : '—'); ?></span>
                                    </div>
                                    <span class="badge <?php echo $qaBadgeClass; ?>" data-i18n="<?php echo $qaEqual ? 'adm_qa_match' : 'adm_qa_mismatch'; ?>">
                                        <?php echo $qaEqual ? 'إجابة مطابقة' : 'إجابة غير مطابقة'; ?>
                                    </span>
                                </div>
                                <div class="row g-2 small">
                                    <div class="col-sm-6">
                                        <div class="p-2 rounded bg-white bg-opacity-75 border">
                                            <span class="fw-bold" data-i18n="adm_correct_answer_label">الإجابة الصحيحة (المبلّغ):</span>
                                            <span><?php echo e($cl['correct_answer'] !== null && $cl['correct_answer'] !== '' ? $cl['correct_answer'] : '—'); ?></span>
                                        </div>
                                    </div>
                                    <div class="col-sm-6">
                                        <div class="p-2 rounded bg-white bg-opacity-75 border">
                                            <span class="fw-bold" data-i18n="adm_claimant_answer_label">إجابة طالب الاسترداد:</span>
                                            <span><?php echo e($cl['security_answer'] !== null && $cl['security_answer'] !== '' ? $cl['security_answer'] : '—'); ?></span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <form method="POST" action="claim_action.php" class="row g-2 align-items-center">
                                <input type="hidden" name="claim_id" value="<?php echo (int)$cl['claim_id']; ?>">
                                <div class="col-auto">
                                    <button type="submit" name="action" value="approve" class="btn btn-gov-primary btn-sm" data-i18n="adm_btn_approve_claim">قبول الملكية</button>
                                </div>
                                <div class="col-sm-6 col-md-5">
                                    <input type="text" name="reject_reason" class="form-control form-control-sm" maxlength="255"
                                           data-i18n-placeholder="adm_reject_reason_ph" placeholder="سبب الرفض (اختياري)">
                                </div>
                                <div class="col-auto">
                                    <button type="submit" name="action" value="reject" class="btn btn-outline-danger btn-sm" data-i18n="btn_reject">رفض</button>
                                </div>
                            </form>
                        </div>
                    <?php endforeach; endif; ?>
                </section>

                <!-- 5. المستردات -->
                <section class="admin-panel" id="panel-returns">
                    <h2 class="dash-title mb-3" data-i18n="admin_returns">المستردات</h2>
                    <p class="text-muted small mb-4" data-i18n="admin_returns_hint">معثورات تم التحقق من ملكيتها وهي جاهزة للتسليم. يُرجى تسجيل وتسديد عملية التسليم فور استلام المستفيد للغرض.</p>
                    <?php if (!$approved): ?>
                        <div class="text-muted small py-4 text-center" data-i18n="adm_no_returns">لا توجد أغراض جاهزة للتسليم حالياً.</div>
                    <?php else: foreach ($approved as $ap): ?>
                        <?php
                        $apItem     = $ap['item'];
                        $apClaimant = $ap['claimant'];
                        ?>
                        <div class="an-card mb-3 d-flex flex-wrap justify-content-between align-items-center gap-3">
                            <div>
                                <h5 class="mb-1" style="color:var(--gov-green);font-weight:700;"><?php echo e($apItem['item_name']); ?></h5>
                                <p class="small text-muted mb-0">
                                    <span data-i18n="th_recipient">المستلم</span>: <strong><?php echo e($apClaimant['full_name']); ?></strong> &middot;
                                    <span data-i18n="label_phone">رقم التواصل</span>: <?php echo e($apClaimant['phone'] ?: '—'); ?> &middot;
                                    <span data-i18n="th_nearest">أقرب معلم</span>: <?php echo lv($apItem['location']); ?>
                                </p>
                            </div>
                            <form method="POST" action="delivery_action.php">
                                <input type="hidden" name="claim_id" value="<?php echo (int)$ap['claim_id']; ?>">
                                <button type="submit" class="btn btn-gov-primary btn-sm" data-i18n="btn_record_delivery">تسجيل التسليم</button>
                            </form>
                        </div>
                    <?php endforeach; endif; ?>
                </section>

                <!-- 6. إدارة الشحنات والتوصيل -->
                <section class="admin-panel" id="panel-shipping">
                    <h2 class="dash-title mb-3" data-i18n="adm_ship_title">متابعة طلبات الشحن والتوصيل</h2>

                    <!-- فلتر الحالة -->
                    <div class="d-flex flex-wrap gap-2 mb-3">
                        <a href="admin_dashboard.php#panel-shipping" class="btn btn-sm <?php echo $ship_filter === '' ? 'btn-gov-primary' : 'btn-outline-secondary'; ?>" data-i18n="adm_ship_all">الكل</a>
                        <?php foreach ($ship_statuses as $st): ?>
                            <a href="admin_dashboard.php?ship_status=<?php echo e($st); ?>#panel-shipping"
                               class="btn btn-sm <?php echo $ship_filter === $st ? 'btn-gov-primary' : 'btn-outline-secondary'; ?>"
                               data-i18n="ship_status_<?php echo e($st); ?>"><?php echo e(status_label($st)); ?></a>
                        <?php endforeach; ?>
                    </div>

                    <?php if (empty($shipping)): ?>
                        <div class="text-muted small py-4 text-center" data-i18n="adm_no_ship">لا توجد طلبات شحن مسجلة حالياً.</div>
                    <?php else: ?>
                        <?php foreach ($shipping as $sh): ?>
                            <div class="card mb-3">
                                <div class="card-body">
                                    <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-2">
                                        <div>
                                            <strong>#<?php echo (int)$sh['shipping_id']; ?> — <?php echo e($sh['item_name']); ?></strong>
                                            <div class="small text-muted">
                                                <i class="bi bi-person"></i> <?php echo e($sh['user']['full_name']); ?> ·
                                                <i class="bi bi-telephone"></i> <?php echo e($sh['phone']); ?> ·
                                                <i class="bi bi-calendar3"></i> <?php echo e(substr((string)$sh['created_at'], 0, 10)); ?>
                                            </div>
                                        </div>
                                        <span class="badge text-bg-secondary"><?php echo e($sh['status_label']); ?></span>
                                    </div>
                                    <div class="small mb-2">
                                        <i class="bi bi-geo-alt"></i> <?php echo e($sh['city']); ?> — <?php echo e($sh['address']); ?>
                                        <?php if (!empty($sh['notes'])): ?>
                                            <div class="text-muted"><i class="bi bi-chat-left-text"></i> <?php echo e($sh['notes']); ?></div>
                                        <?php endif; ?>
                                    </div>
                                    <form method="POST" action="admin_shipping_action.php" class="row g-2 align-items-end">
                                        <input type="hidden" name="shipping_id" value="<?php echo (int)$sh['shipping_id']; ?>">
                                        <div class="col-md-3">
                                            <label class="form-label small" data-i18n="adm_ship_status">الحالة</label>
                                            <select name="status" class="form-select form-select-sm">
                                                <?php foreach ($ship_statuses as $st): ?>
                                                    <option value="<?php echo e($st); ?>" <?php echo $sh['status'] === $st ? 'selected' : ''; ?>
                                                            data-i18n="ship_status_<?php echo e($st); ?>"><?php echo e(status_label($st)); ?></option>
                                                <?php endforeach; ?>
                                            </select>
                                        </div>
                                        <div class="col-md-2">
                                            <label class="form-label small" data-i18n="adm_ship_carrier">شركة الشحن</label>
                                            <input type="text" name="carrier" class="form-control form-control-sm" maxlength="60" value="<?php echo e($sh['carrier']); ?>">
                                        </div>
                                        <div class="col-md-3">
                                            <label class="form-label small" data-i18n="adm_ship_tracking">رقم التتبع</label>
                                            <input type="text" name="tracking_number" class="form-control form-control-sm" maxlength="80" value="<?php echo e($sh['tracking_number']); ?>">
                                        </div>
                                        <div class="col-md-2">
                                            <label class="form-label small" data-i18n="adm_ship_note">ملاحظة</label>
                                            <input type="text" name="admin_note" class="form-control form-control-sm" maxlength="255" value="<?php echo e($sh['admin_note']); ?>">
                                        </div>
                                        <div class="col-md-2 d-grid">
                                            <button type="submit" class="btn btn-sm btn-gov-primary" data-i18n="adm_ship_save">تحديث</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </section>

                <!-- حسابات المشرفين بانتظار الموافقة -->
                <section class="admin-panel" id="panel-accounts">
                    <h2 class="dash-title mb-3" data-i18n="adm_accounts_title">طلبات تسجيل المشرفين</h2>
                    <?php if (empty($pending_admins)): ?>
                        <div class="text-muted small py-4 text-center" data-i18n="adm_accounts_empty">لا توجد طلبات معلقة.</div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th data-i18n="adm_accounts_name">الاسم</th>
                                        <th data-i18n="adm_accounts_email">البريد الإلكتروني</th>
                                        <th data-i18n="adm_accounts_date">تاريخ الطلب</th>
                                        <th></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($pending_admins as $pa): ?>
                                        <tr>
                                            <td><strong><?php echo e($pa['full_name']); ?></strong></td>
                                            <td dir="ltr"><?php echo e($pa['email']); ?></td>
                                            <td><?php echo e(substr((string)$pa['created_at'], 0, 10)); ?></td>
                                            <td class="text-end">
                                                <form method="POST" action="admin_accounts_action.php" class="d-inline">
                                                    <input type="hidden" name="admin_id" value="<?php echo (int)$pa['admin_id']; ?>">
                                                    <button type="submit" name="action" value="approve" class="btn btn-sm btn-success" data-i18n="adm_accounts_approve">قبول</button>
                                                    <button type="submit" name="action" value="reject" class="btn btn-sm btn-outline-danger"
                                                            onclick="return confirm(t(localStorage.getItem('mafqodak_lang') || 'ar', 'adm_accounts_reject_confirm'));"
                                                            data-i18n="adm_accounts_reject">رفض</button>
                                                </form>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </section>

            </main>
        </div>
    </div>

    <footer class="text-center py-3">
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
        const GEO = <?php echo json_encode($geo, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP); ?>;
        let mapInstance = null;
        function esc(t) { const d = document.createElement('div'); d.textContent = t; return d.innerHTML; }
        function initAnalytics() {
            if (!mapInstance) {
                mapInstance = L.map('heatmapContainer').setView([21.4225, 39.8262], 14);
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap'
                }).addTo(mapInstance);

                const pts = [];
                GEO.forEach(function (g) {
                    const lat = parseFloat(g.lat !== undefined ? g.lat : g.latitude);
                    const lng = parseFloat(g.lng !== undefined ? g.lng : g.longitude);
                    const c = parseInt(g.weight !== undefined ? g.weight : g.cnt, 10);
                    if (!isNaN(lat) && !isNaN(lng)) {
                        L.circleMarker([lat, lng], {
                            radius: 10 + Math.min(c * 4, 30),
                            color: '#9E793E', weight: 1,
                            fillColor: '#0d4a3a', fillOpacity: 0.55
                        }).bindPopup((g.location_name ? '<b>' + esc(g.location_name) + '</b><br>' : '') + t(localStorage.getItem('mafqodak_lang') || 'ar', 'adm_heat_count') + ' ' + c).addTo(mapInstance);
                        pts.push([lat, lng]);
                    }
                });

                if (pts.length) {
                    mapInstance.fitBounds(pts, { padding: [40, 40], maxZoom: 15 });
                    const empty = document.querySelector('.an-map-empty');
                    if (empty) { empty.style.display = 'none'; }
                }
            } else {
                setTimeout(function () { mapInstance.invalidateSize(); }, 200);
            }
        }

        document.querySelectorAll('.admin-nav-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                document.querySelectorAll('.admin-nav-btn').forEach(function (b) { b.classList.remove('active'); });
                document.querySelectorAll('.admin-panel').forEach(function (p) { p.classList.remove('active'); });
                btn.classList.add('active');
                const target = btn.getAttribute('data-panel');
                document.getElementById(target).classList.add('active');
                if (target === 'panel-analytics') { initAnalytics(); }
            });
        });

        // Open the panel named in the URL (e.g. after saving: admin_dashboard.php#panel-shipping)
        if (location.hash) {
            const navBtn = document.querySelector('.admin-nav-btn[data-panel="' + location.hash.substring(1) + '"]');
            if (navBtn) { navBtn.click(); }
        }
    </script>
</body>
</html>