<?php
/* item.php — تفاصيل الغرض المفقود أو المعثور، الخريطة المصغرة، ونموذج المطالبة بالملكية */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

$type = isset($_GET['type']) && !is_array($_GET['type']) ? trim((string)$_GET['type']) : '';
$id   = isset($_GET['id']) && !is_array($_GET['id']) ? (int)$_GET['id'] : 0;

$item     = null;
$errorMsg = null;

try {
    $item = item_details($conn, $type, $id);
} catch (UserError $e) {
    $errorMsg = $e->getMessage();
} catch (Exception $e) {
    error_log('item details error: ' . $e->getMessage());
    $errorMsg = msg('api.unexpected');
}

$pageTitleKey = 'item_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-4">
        <?php render_flash(); ?>

        <div class="mb-3">
            <a href="items.php" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-arrow-right me-1"></i><span data-i18n="back_to_items">العودة إلى قائمة البلاغات</span>
            </a>
        </div>

        <?php if ($errorMsg !== null || !$item): ?>
            <div class="dash-card text-center py-5">
                <div class="alert alert-warning d-inline-block mb-3"><?php echo e($errorMsg ?: msg('item.not_found')); ?></div>
                <div>
                    <a href="items.php" class="btn btn-gov-primary btn-sm" data-i18n="back_to_items">العودة إلى قائمة البلاغات</a>
                </div>
            </div>
        <?php else: ?>
            <?php
            $images = !empty($item['images']) ? $item['images'] : (!empty($item['image_url']) ? array($item['image_url']) : array());
            $hasCoords = ($item['lat'] !== null && $item['lng'] !== null);
            $canBeClaimed = ($item['type'] === 'found' && in_array($item['status'], array('received', 'matched'), true));
            ?>
            <div class="row g-4">
                <!-- العمود الأيمن: الصور وتفاصيل الغرض -->
                <div class="col-lg-7">
                    <div class="dash-card">
                        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                            <div class="d-flex align-items-center gap-2">
                                <span class="fw-bold text-muted">#<?php echo (int)$item['id']; ?></span>
                                <?php if ($item['type'] === 'lost'): ?>
                                    <span class="badge text-bg-secondary" data-i18n="type_lost">مفقود</span>
                                <?php else: ?>
                                    <span class="badge text-bg-warning" data-i18n="type_found">معثور</span>
                                <?php endif; ?>
                                <?php if (!empty($item['report_kind']) && $item['report_kind'] === 'sighting'): ?>
                                    <span class="badge text-bg-info" data-i18n="badge_sighting">مشاهدة</span>
                                <?php endif; ?>
                            </div>
                            <span class="badge text-bg-success" data-i18n="status_<?php echo e($item['status']); ?>">
                                <?php echo e($item['status_label']); ?>
                            </span>
                        </div>

                        <h3 class="fw-bold mb-3" style="color: var(--gov-green);"><?php echo e($item['item_name']); ?></h3>

                        <?php if ($images): ?>
                            <div class="row g-2 mb-4">
                                <?php foreach ($images as $imgUrl): ?>
                                    <div class="<?php echo count($images) === 1 ? 'col-12' : 'col-sm-6'; ?>">
                                        <a href="<?php echo e($imgUrl); ?>" target="_blank" class="d-block border rounded overflow-hidden bg-light">
                                            <img src="<?php echo e($imgUrl); ?>" alt="<?php echo e($item['item_name']); ?>"
                                                 style="width: 100%; max-height: 320px; object-fit: cover;">
                                        </a>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        <?php endif; ?>

                        <div class="row g-3 mb-3">
                            <div class="col-sm-6">
                                <div class="p-3 bg-light rounded border">
                                    <div class="small text-muted mb-1" data-i18n="th_cat">التصنيف</div>
                                    <div class="fw-semibold"><?php echo lv($item['category']); ?></div>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 bg-light rounded border">
                                    <div class="small text-muted mb-1" data-i18n="th_nearest">أقرب معلم</div>
                                    <div class="fw-semibold"><?php echo lv($item['location']); ?></div>
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="p-3 bg-light rounded border">
                                    <div class="small text-muted mb-1" data-i18n="th_date">التاريخ</div>
                                    <div class="fw-semibold"><?php echo e((string)$item['date']); ?></div>
                                </div>
                            </div>
                            <?php if ($item['type'] === 'found' && !empty($item['current_status'])): ?>
                                <div class="col-sm-6">
                                    <div class="p-3 bg-light rounded border">
                                        <div class="small text-muted mb-1" data-i18n="found_label_status">حالة الغرض الحالية</div>
                                        <div class="fw-semibold"><?php echo lv($item['current_status']); ?></div>
                                    </div>
                                </div>
                            <?php endif; ?>
                        </div>

                        <div class="mb-2">
                            <h6 class="fw-bold" data-i18n="item_description_label">الوصف والتفاصيل</h6>
                            <p class="mb-0 text-secondary" style="line-height: 1.7;"><?php echo e($item['description']); ?></p>
                        </div>
                    </div>
                </div>

                <!-- العمود الأيسر: الخريطة المصغرة ونموذج المطالبة بالملكية -->
                <div class="col-lg-5">
                    <?php if ($hasCoords): ?>
                        <div class="dash-card mb-4">
                            <h5 class="fw-bold mb-3" style="color: var(--gov-green);">
                                <i class="bi bi-geo-alt-fill me-1"></i><span data-i18n="item_map_title">الموقع على الخريطة</span>
                            </h5>
                            <div id="itemMiniMap" style="height: 260px; width: 100%; border-radius: 8px;"></div>
                        </div>
                    <?php endif; ?>

                    <?php if ($canBeClaimed): ?>
                        <div class="dash-card">
                            <h5 class="fw-bold mb-2" style="color: var(--gov-green);">
                                <i class="bi bi-patch-check me-1"></i><span data-i18n="claim_box_title">طلب استرداد وإثبات ملكية</span>
                            </h5>
                            <p class="text-muted small mb-3" data-i18n="claim_box_subtitle">إذا كان هذا الغرض يخصك، يرجى كتابة العلامات المميزة له ليتم التحقق من ملكيتك من قِبل فريق الإدارة.</p>

                            <?php if (is_logged_in() && isset($_SESSION['role']) && $_SESSION['role'] === 'user'): ?>
                                <form method="POST" action="process_claim_item.php" class="needs-validation" novalidate>
                                    <input type="hidden" name="found_item_id" value="<?php echo (int)$item['id']; ?>">

                                    <div class="mb-3">
                                        <label for="claim_description" class="form-label small fw-bold">
                                            <span data-i18n="claim_desc_label">صف العلامات المميزة للغرض (للتحقق من الملكية)</span> *
                                        </label>
                                        <textarea class="form-control" id="claim_description" name="claim_description"
                                                  rows="3" minlength="10" maxlength="250" required
                                                  data-i18n-placeholder="claim_desc_placeholder"
                                                  placeholder="مثال: حقيبة سوداء، سحّاب أحمر، بداخلها مصحف صغير"></textarea>
                                        <div class="form-text small" data-i18n="claim_desc_min_hint">يرجى كتابة 10 أحرف على الأقل توضح العلامات الفارقة للغرض.</div>
                                    </div>

                                    <?php if (!empty($item['security_question'])): ?>
                                        <div class="mb-3">
                                            <label for="security_answer" class="form-label small fw-bold">
                                                <span data-i18n="claim_sec_question_label">سؤال الأمان:</span>
                                                <?php echo e($item['security_question']); ?>
                                            </label>
                                            <input type="text" class="form-control" id="security_answer" name="security_answer"
                                                   maxlength="255"
                                                   data-i18n-placeholder="claim_sec_answer_placeholder"
                                                   placeholder="أدخل إجابة سؤال الأمان">
                                        </div>
                                    <?php endif; ?>

                                    <button type="submit" class="btn btn-gov-submit" data-i18n="btn_submit_claim">تقديم طلب الاسترداد</button>
                                </form>
                            <?php else: ?>
                                <div class="alert alert-light border mb-0">
                                    <p class="small mb-2" data-i18n="claim_login_prompt">يلزم تسجيل الدخول بحساب أفراد لتقديم طلب استرداد لهذا الغرض.</p>
                                    <a href="login.php" class="btn btn-gov-primary btn-sm" data-i18n="item_login_to_claim">سجّل الدخول للمطالبة بهذا الغرض</a>
                                </div>
                            <?php endif; ?>
                        </div>
                    <?php endif; ?>
                </div>
            </div>

            <?php if ($hasCoords): ?>
                <script>
                    document.addEventListener('DOMContentLoaded', function () {
                        const lat = <?php echo json_encode((float)$item['lat']); ?>;
                        const lng = <?php echo json_encode((float)$item['lng']); ?>;
                        const locName = <?php echo json_encode((string)$item['location'], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP); ?>;
                        const mapEl = document.getElementById('itemMiniMap');
                        if (mapEl && typeof L !== 'undefined') {
                            const map = L.map('itemMiniMap').setView([lat, lng], 16);
                            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                                maxZoom: 19,
                                attribution: '&copy; OpenStreetMap'
                            }).addTo(map);
                            L.marker([lat, lng]).addTo(map).bindPopup(locName || '');
                        }
                    });
                </script>
            <?php endif; ?>
        <?php endif; ?>
    </div>

<?php require __DIR__ . '/partials/footer.php'; ?>
