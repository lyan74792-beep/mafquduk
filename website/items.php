<?php
/* items.php — تصفح البلاغات العامة (المفقودات والمعثورات) مع البحث والفلترة والترقيم */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

$rawType  = isset($_GET['type']) && !is_array($_GET['type']) ? trim((string)$_GET['type']) : 'all';
$type     = in_array($rawType, array('all', 'lost', 'found'), true) ? $rawType : 'all';
$category = isset($_GET['category']) && !is_array($_GET['category']) ? trim((string)$_GET['category']) : '';
$q        = isset($_GET['q']) && !is_array($_GET['q']) ? trim((string)$_GET['q']) : '';
$page     = isset($_GET['page']) && !is_array($_GET['page']) ? max(1, (int)$_GET['page']) : 1;

$categories = lookup_categories();
$items      = array();
$hasMore    = false;

try {
    $result  = item_browse($conn, $type, $category, $q, $page);
    $items   = $result['items'];
    $page    = (int)$result['page'];
    $hasMore = (bool)$result['has_more'];
} catch (Exception $e) {
    error_log('items browse error: ' . $e->getMessage());
}

function items_page_url($targetPage, $type, $category, $q)
{
    $params = array();
    if ($type !== '' && $type !== 'all') {
        $params['type'] = $type;
    }
    if ($category !== '') {
        $params['category'] = $category;
    }
    if ($q !== '') {
        $params['q'] = $q;
    }
    $params['page'] = max(1, (int)$targetPage);
    return 'items.php?' . http_build_query($params);
}

$pageTitleKey = 'items_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-4">
        <?php render_flash(); ?>

        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
            <div>
                <h2 class="section-title mb-1" data-i18n="items_header">تصفح المفقودات والمعثورات</h2>
                <p class="text-muted small mb-0" data-i18n="items_subtitle">ابحث في البلاغات المسجلة أو صفِّ النتائج حسب النوع والتصنيف للوصول إلى غرضك.</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a href="map.php" class="btn btn-outline-secondary btn-sm">
                    <i class="bi bi-map me-1"></i><span data-i18n="nav_map">خريطة البلاغات</span>
                </a>
                <a href="report_found.php?kind=sighting" class="btn btn-gov-gold btn-sm w-auto">
                    <i class="bi bi-eye me-1"></i><span data-i18n="nav_report_sighting">الإبلاغ عن مشاهدة</span>
                </a>
            </div>
        </div>

        <!-- نموذج البحث والفلترة -->
        <div class="dash-card mb-4">
            <form method="GET" action="items.php" class="row g-3 align-items-end">
                <div class="col-md-4">
                    <label for="filter_q" class="form-label small" data-i18n="items_search_label">كلمة البحث</label>
                    <input type="text" class="form-control" id="filter_q" name="q"
                           value="<?php echo e($q); ?>"
                           data-i18n-placeholder="items_search_placeholder"
                           placeholder="ابحث بالاسم أو الوصف أو العلامات المميزة">
                </div>
                <div class="col-md-3">
                    <label for="filter_type" class="form-label small" data-i18n="th_type">النوع</label>
                    <select class="form-select" id="filter_type" name="type">
                        <option value="all" <?php echo $type === 'all' ? 'selected' : ''; ?> data-i18n="filter_type_all">الكل (مفقود ومعثور)</option>
                        <option value="lost" <?php echo $type === 'lost' ? 'selected' : ''; ?> data-i18n="type_lost">مفقود</option>
                        <option value="found" <?php echo $type === 'found' ? 'selected' : ''; ?> data-i18n="type_found">معثور</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="filter_category" class="form-label small" data-i18n="th_cat">التصنيف</label>
                    <select class="form-select" id="filter_category" name="category">
                        <option value="" <?php echo $category === '' ? 'selected' : ''; ?> data-i18n="filter_cat_all">جميع التصنيفات</option>
                        <?php foreach ($categories as $cat): ?>
                            <option value="<?php echo e($cat); ?>" data-i18n-value="<?php echo e($cat); ?>" <?php echo $category === $cat ? 'selected' : ''; ?>><?php echo e($cat); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-2 d-flex gap-2">
                    <button type="submit" class="btn btn-gov-primary w-100" data-i18n="search_btn">بحث</button>
                    <?php if ($q !== '' || $type !== 'all' || $category !== ''): ?>
                        <a href="items.php" class="btn btn-outline-secondary" data-i18n="filter_reset">إعادة</a>
                    <?php endif; ?>
                </div>
            </form>
        </div>

        <!-- شبكة البطاقات -->
        <?php if (!$items): ?>
            <div class="dash-card text-center py-5">
                <i class="bi bi-inbox fs-1 text-muted d-block mb-2"></i>
                <p class="text-muted mb-0" data-i18n="items_empty">لا توجد عناصر مطابقة لخيارات البحث الحالية.</p>
            </div>
        <?php else: ?>
            <div class="row g-4">
                <?php foreach ($items as $it): ?>
                    <?php
                    $itemUrl = 'item.php?type=' . urlencode((string)$it['type']) . '&id=' . (int)$it['id'];
                    $hasImg  = !empty($it['image_url']);
                    ?>
                    <div class="col-sm-6 col-lg-4 col-xl-3">
                        <div class="card-gov p-0 overflow-hidden h-100 d-flex flex-column justify-content-between">
                            <div>
                                <?php if ($hasImg): ?>
                                    <a href="<?php echo e($itemUrl); ?>" class="d-block bg-light border-bottom" style="height: 180px; overflow: hidden;">
                                        <img src="<?php echo e($it['image_url']); ?>" alt="<?php echo e($it['item_name']); ?>"
                                             style="width: 100%; height: 180px; object-fit: cover;">
                                    </a>
                                <?php else: ?>
                                    <a href="<?php echo e($itemUrl); ?>" class="d-flex align-items-center justify-content-center bg-light border-bottom text-decoration-none" style="height: 180px; color: var(--gov-green);">
                                        <i class="bi bi-box-seam" style="font-size: 2.5rem;"></i>
                                    </a>
                                <?php endif; ?>

                                <div class="p-3">
                                    <div class="d-flex flex-wrap justify-content-between align-items-center gap-1 mb-2">
                                        <div>
                                            <?php if ($it['type'] === 'lost'): ?>
                                                <span class="badge text-bg-secondary" data-i18n="type_lost">مفقود</span>
                                            <?php else: ?>
                                                <span class="badge text-bg-warning" data-i18n="type_found">معثور</span>
                                            <?php endif; ?>
                                            <?php if (!empty($it['report_kind']) && $it['report_kind'] === 'sighting'): ?>
                                                <span class="badge text-bg-info" data-i18n="badge_sighting">مشاهدة</span>
                                            <?php endif; ?>
                                        </div>
                                        <span class="badge text-bg-light border text-dark" data-i18n="status_<?php echo e($it['status']); ?>">
                                            <?php echo e($it['status_label']); ?>
                                        </span>
                                    </div>

                                    <h6 class="fw-bold mb-2 text-truncate" title="<?php echo e($it['item_name']); ?>">
                                        <a href="<?php echo e($itemUrl); ?>" class="text-decoration-none text-dark">
                                            <?php echo e($it['item_name']); ?>
                                        </a>
                                    </h6>

                                    <ul class="list-unstyled small text-muted mb-0">
                                        <li class="mb-1 text-truncate">
                                            <i class="bi bi-tag me-1"></i>
                                            <span data-i18n="th_cat">التصنيف</span>: <?php echo lv($it['category']); ?>
                                        </li>
                                        <li class="mb-1 text-truncate">
                                            <i class="bi bi-geo-alt me-1"></i>
                                            <span data-i18n="th_nearest">أقرب معلم</span>: <?php echo lv($it['location']); ?>
                                        </li>
                                        <li>
                                            <i class="bi bi-calendar3 me-1"></i>
                                            <span data-i18n="th_date">التاريخ</span>: <?php echo e((string)$it['date']); ?>
                                        </li>
                                    </ul>
                                </div>
                            </div>

                            <div class="px-3 pb-3 pt-2 border-top bg-light">
                                <a href="<?php echo e($itemUrl); ?>" class="btn btn-outline-secondary btn-sm w-100" data-i18n="item_view_details">عرض التفاصيل</a>
                            </div>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>

            <!-- الترقيم (Pagination) -->
            <nav class="d-flex justify-content-center align-items-center gap-3 mt-4" aria-label="Pagination">
                <?php if ($page > 1): ?>
                    <a href="<?php echo e(items_page_url($page - 1, $type, $category, $q)); ?>" class="btn btn-outline-secondary btn-sm" data-i18n="page_prev">السابق</a>
                <?php else: ?>
                    <button type="button" class="btn btn-outline-secondary btn-sm" disabled data-i18n="page_prev">السابق</button>
                <?php endif; ?>

                <span class="small fw-semibold">
                    <span data-i18n="page_label">صفحة</span> <?php echo (int)$page; ?>
                </span>

                <?php if ($hasMore): ?>
                    <a href="<?php echo e(items_page_url($page + 1, $type, $category, $q)); ?>" class="btn btn-outline-secondary btn-sm" data-i18n="page_next">التالي</a>
                <?php else: ?>
                    <button type="button" class="btn btn-outline-secondary btn-sm" disabled data-i18n="page_next">التالي</button>
                <?php endif; ?>
            </nav>
        <?php endif; ?>
    </div>

<?php require __DIR__ . '/partials/footer.php'; ?>
