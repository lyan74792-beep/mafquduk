<?php
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

$uid            = (int)$_SESSION['uid'];
$my_rows        = array();
$my_matches     = array();
$my_claims      = array();
$my_shipping    = array();
$cancel_reasons = lookup_cancel_reasons();

try {
    $mine    = report_mine($conn, $uid);
    $my_rows = array_merge($mine['lost'], $mine['found']);
    usort($my_rows, function ($a, $b) {
        return strcmp((string)$b['date'], (string)$a['date']);
    });
} catch (Exception $e) {
    error_log('user dashboard reports: ' . $e->getMessage());
}

try {
    $matchList  = match_list_for_user($conn, $uid);
    $my_matches = $matchList['matches'];
} catch (Exception $e) {
    error_log('user dashboard matches: ' . $e->getMessage());
}

try {
    $claimList = claim_list_for_user($conn, $uid);
    $my_claims = $claimList['claims'];
} catch (Exception $e) {
    error_log('user dashboard claims: ' . $e->getMessage());
}

try {
    $shipList    = shipping_list_for_user($conn, $uid);
    $my_shipping = $shipList['requests'];
} catch (Exception $e) {
    error_log('user dashboard shipping: ' . $e->getMessage());
}

$pageTitleKey = 'u_dashboard_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-5">
        <?php render_flash(); ?>

        <!-- تبويبات الأقسام -->
        <div class="dash-tabs" role="tablist">
            <button type="button" class="dash-tab active" data-panel="panel-my-reports">
                <i class="bi bi-folder2-open"></i><span data-i18n="u_my_reports">بلاغاتي المسجلة</span>
            </button>
            <button type="button" class="dash-tab" data-panel="panel-matches">
                <i class="bi bi-link-45deg"></i><span data-i18n="u_matches">المطابقات المقترحة</span>
            </button>
            <button type="button" class="dash-tab" data-panel="panel-my-claims">
                <i class="bi bi-patch-check"></i><span data-i18n="u_my_claims">طلبات الاسترداد</span>
            </button>
            <button type="button" class="dash-tab" data-panel="panel-shipping-user">
                <i class="bi bi-truck"></i><span data-i18n="u_shipping">طلبات الشحن والتوصيل</span>
            </button>
        </div>

        <!-- محتوى الأقسام -->
        <div class="dash-content">

            <!-- 1. بلاغاتي المسجلة -->
            <div class="dash-panel active" id="panel-my-reports">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <h2 class="dash-title mb-0" data-i18n="u_my_reports">بلاغاتي المسجلة</h2>
                    <div class="d-flex flex-wrap gap-2">
                        <a href="report_lost.php" class="btn btn-gov-primary btn-sm w-auto" data-i18n="btn_report_lost">تقديم طلب مفقود</a>
                        <a href="report_found.php" class="btn btn-gov-gold btn-sm w-auto" data-i18n="btn_report_found">الإبلاغ عن موجود</a>
                    </div>
                </div>
                <p class="text-muted small mb-4" data-i18n="u_my_reports_desc">قائمة بجميع البلاغات والمفقودات التي قمت بتسجيلها في المنصة.</p>

                <div class="table-responsive">
                    <table class="table admin-table align-middle">
                        <thead>
                            <tr>
                                <th data-i18n="th_report_no">رقم البلاغ</th>
                                <th data-i18n="th_type">النوع</th>
                                <th data-i18n="th_cat">التصنيف</th>
                                <th data-i18n="th_report_date">تاريخ البلاغ</th>
                                <th data-i18n="th_status">الحالة</th>
                                <th data-i18n="th_action">إجراء</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (!$my_rows): ?>
                                <tr><td colspan="6" class="text-center text-muted small py-4" data-i18n="no_reports">لا توجد بلاغات مسجلة حتى الآن.</td></tr>
                            <?php else: foreach ($my_rows as $r): ?>
                                <tr>
                                    <td class="fw-bold">#<?php echo (int)$r['id']; ?></td>
                                    <td>
                                        <?php if ($r['type'] === 'lost'): ?>
                                            <span class="badge text-bg-secondary" data-i18n="type_lost"><?php echo e(msg('report.type_lost')); ?></span>
                                        <?php else: ?>
                                            <span class="badge text-bg-warning" data-i18n="type_found"><?php echo e(msg('report.type_found')); ?></span>
                                        <?php endif; ?>
                                    </td>
                                    <td><?php echo lv($r['category']); ?></td>
                                    <td><?php echo e((string)$r['date']); ?></td>
                                    <td>
                                        <div><?php echo e(status_label($r['status'])); ?></div>
                                        <?php if ($r['type'] === 'lost' && $r['status'] === 'cancelled' && !empty($r['cancel_reason'])): ?>
                                            <div class="small text-muted mt-1">
                                                <span data-i18n="cancel_reason_prefix">سبب الإلغاء:</span>
                                                <?php echo lv($r['cancel_reason']); ?>
                                            </div>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php if ($r['type'] === 'lost' && in_array($r['status'], array('searching', 'matched'), true)): ?>
                                            <button type="button" class="btn btn-outline-danger btn-sm btn-open-cancel-modal"
                                                    data-bs-toggle="modal" data-bs-target="#cancelReportModal"
                                                    data-lost-id="<?php echo (int)$r['id']; ?>"
                                                    data-i18n="btn_cancel_report">إلغاء البلاغ</button>
                                        <?php else: ?>
                                            <span class="text-muted small">—</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- 2. المطابقات المقترحة -->
            <div class="dash-panel" id="panel-matches">
                <h2 class="dash-title mb-3" data-i18n="u_matches">المطابقات المقترحة</h2>
                <p class="text-muted small mb-4" data-i18n="u_matches_desc">توجد مفقودات معثور عليها تتطابق مع تفاصيل بلاغكم المُسجّل. في حال التعرف على المعثورات، يُرجى تأكيد الملكية وتقديم طلب الاسترداد لإتمام الإجراءات.</p>
                <?php if (!$my_matches): ?>
                    <div class="text-muted small py-4 text-center" data-i18n="u_matches_empty">لا توجد مطابقات مقترحة حالياً.</div>
                <?php else: foreach ($my_matches as $mt): $f = $mt['found']; ?>
                    <div class="dash-card">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <h5 class="fw-bold mb-0"><?php echo e($f['item_name']); ?></h5>
                            <span class="badge text-bg-success"><?php echo number_format((float)$mt['score'], 0); ?>% <span data-i18n="match_percent_suffix">تطابق</span></span>
                        </div>
                        <p class="small text-muted mb-1">
                            <span data-i18n="th_cat">التصنيف</span>: <?php echo lv($f['category']); ?> &middot;
                            <span data-i18n="th_nearest">أقرب معلم</span>: <?php echo lv($f['location']); ?> &middot;
                            <span data-i18n="th_date">التاريخ</span>: <?php echo e((string)$f['date']); ?>
                        </p>
                        <p class="small mb-3"><?php echo e($f['description']); ?></p>
                        <form method="POST" action="match_action.php" class="border-top pt-3">
                            <input type="hidden" name="match_id" value="<?php echo (int)$mt['match_id']; ?>">
                            <label class="form-label small fw-bold" data-i18n="claim_desc_label">صف العلامات المميزة للغرض (للتحقق من الملكية)</label>
                            <textarea class="form-control mb-2" name="claim_description" rows="2" maxlength="250" data-i18n-placeholder="claim_desc_placeholder" placeholder="مثال: حقيبة سوداء، سحّاب أحمر، بداخلها مصحف صغير"></textarea>
                            <?php if (!empty($mt['security_question'])): ?>
                                <div class="mb-2">
                                    <label class="form-label small fw-bold">
                                        <span data-i18n="claim_sec_question_label">سؤال الأمان:</span>
                                        <?php echo e($mt['security_question']); ?>
                                    </label>
                                    <input type="text" class="form-control form-control-sm" name="security_answer" maxlength="255"
                                           data-i18n-placeholder="claim_sec_answer_placeholder" placeholder="أدخل إجابة سؤال الأمان">
                                </div>
                            <?php endif; ?>
                            <div class="d-flex gap-2">
                                <button type="submit" name="action" value="claim" class="btn btn-gov-primary btn-sm" data-i18n="btn_this_is_mine">هذا غرضي</button>
                                <button type="submit" name="action" value="reject" class="btn btn-outline-secondary btn-sm" formnovalidate data-i18n="btn_not_mine">ليس غرضي</button>
                            </div>
                        </form>
                    </div>
                <?php endforeach; endif; ?>
            </div>

            <!-- 3. طلبات الاسترداد (My Claims) -->
            <div class="dash-panel" id="panel-my-claims">
                <h2 class="dash-title mb-2" data-i18n="u_my_claims">طلبات الاسترداد</h2>
                <p class="text-muted small mb-4" data-i18n="u_my_claims_desc">متابعة حالة طلبات استرداد المعثورات وإثبات الملكية التي قدمتها.</p>

                <div class="table-responsive">
                    <table class="table admin-table align-middle">
                        <thead>
                            <tr>
                                <th data-i18n="th_claim_no">رقم الطلب</th>
                                <th data-i18n="th_item">الغرض</th>
                                <th data-i18n="th_claim_date">تاريخ الطلب</th>
                                <th data-i18n="th_status">الحالة</th>
                                <th data-i18n="th_reject_reason">سبب الرفض</th>
                                <th data-i18n="th_shipping_status">حالة الشحن</th>
                                <th data-i18n="th_action">إجراء</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (!$my_claims): ?>
                                <tr><td colspan="7" class="text-center text-muted small py-4" data-i18n="u_claims_empty">لا توجد طلبات استرداد مسجلة حتى الآن.</td></tr>
                            <?php else: foreach ($my_claims as $cl): ?>
                                <?php $clItem = $cl['item']; ?>
                                <tr>
                                    <td class="fw-bold">#<?php echo (int)$cl['claim_id']; ?></td>
                                    <td>
                                        <a href="item.php?type=found&amp;id=<?php echo (int)$clItem['id']; ?>" class="text-decoration-none fw-semibold text-dark">
                                            <?php echo e($clItem['item_name']); ?>
                                        </a>
                                        <div class="small text-muted"><?php echo lv($clItem['category']); ?></div>
                                    </td>
                                    <td><?php echo e((string)$cl['claim_date']); ?></td>
                                    <td>
                                        <span class="badge text-bg-<?php echo $cl['status'] === 'Approved' || $cl['status'] === 'Delivered' ? 'success' : ($cl['status'] === 'Rejected' ? 'danger' : 'warning'); ?>">
                                            <?php echo e($cl['status_label']); ?>
                                        </span>
                                    </td>
                                    <td class="small text-muted"><?php echo e($cl['reject_reason'] ?: '—'); ?></td>
                                    <td>
                                        <?php if (!empty($cl['shipping'])): ?>
                                            <span class="badge text-bg-info"><?php echo e($cl['shipping']['status_label']); ?></span>
                                            <?php if (!empty($cl['shipping']['tracking_number'])): ?>
                                                <div class="small text-muted mt-1"><?php echo e($cl['shipping']['tracking_number']); ?></div>
                                            <?php endif; ?>
                                        <?php else: ?>
                                            <span class="text-muted small" data-i18n="ship_not_requested">لم يُطلب شحن</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php if ($cl['status'] === 'Approved' && empty($cl['shipping'])): ?>
                                            <a href="shipping_request.php?claim_id=<?php echo (int)$cl['claim_id']; ?>" class="btn btn-gov-primary btn-sm" data-i18n="btn_request_delivery">طلب توصيل</a>
                                        <?php else: ?>
                                            <span class="text-muted small">—</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- 4. طلبات الشحن والتوصيل -->
            <div class="dash-panel" id="panel-shipping-user">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <h2 class="dash-title mb-0" data-i18n="u_shipping">طلبات الشحن والتوصيل</h2>
                    <a href="shipping_request.php" class="btn btn-gov-primary btn-sm w-auto" data-i18n="u_ship_new">طلب شحن جديد</a>
                </div>
                <p class="text-muted small mb-4" data-i18n="u_ship_desc">متابعة حالة شحن وإيصال مفقوداتك إلى عنوانك.</p>

                <div class="table-responsive">
                    <table class="table admin-table align-middle">
                        <thead>
                            <tr>
                                <th data-i18n="th_ship_no">رقم الشحنة</th>
                                <th data-i18n="th_item">الغرض</th>
                                <th data-i18n="th_city">المدينة</th>
                                <th data-i18n="th_address">العنوان</th>
                                <th data-i18n="th_status">الحالة</th>
                                <th data-i18n="th_carrier_tracking">الناقل / التتبع</th>
                                <th data-i18n="th_date">التاريخ</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (!$my_shipping): ?>
                                <tr><td colspan="7" class="text-center text-muted small py-4" data-i18n="u_ship_empty">لا توجد طلبات شحن مسجلة حتى الآن.</td></tr>
                            <?php else: foreach ($my_shipping as $sh): ?>
                                <tr>
                                    <td class="fw-bold">#<?php echo (int)$sh['shipping_id']; ?></td>
                                    <td><?php echo e($sh['item_name']); ?></td>
                                    <td><?php echo e($sh['city']); ?></td>
                                    <td class="small"><?php echo e($sh['address']); ?></td>
                                    <td>
                                        <span class="badge text-bg-<?php echo $sh['status'] === 'delivered' || $sh['status'] === 'approved' ? 'success' : ($sh['status'] === 'rejected' ? 'danger' : 'secondary'); ?>">
                                            <?php echo e($sh['status_label']); ?>
                                        </span>
                                    </td>
                                    <td class="small text-muted">
                                        <?php if (!empty($sh['carrier']) || !empty($sh['tracking_number'])): ?>
                                            <?php echo e(trim($sh['carrier'] . ' ' . $sh['tracking_number'])); ?>
                                        <?php else: ?>
                                            —
                                        <?php endif; ?>
                                    </td>
                                    <td class="small text-muted"><?php echo e((string)$sh['created_at']); ?></td>
                                </tr>
                            <?php endforeach; endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
    </div>

    <!-- نافذة إلغاء البلاغ المفقود -->
    <div class="modal fade" id="cancelReportModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <form method="POST" action="process_cancel.php">
                    <div class="modal-header">
                        <h5 class="modal-title" data-i18n="cancel_modal_title">إلغاء بلاغ المفقود</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <input type="hidden" name="lost_item_id" id="cancel_lost_item_id" value="">

                        <div class="mb-3">
                            <label for="cancel_reason" class="form-label" data-i18n="cancel_reason_label">سبب الإلغاء *</label>
                            <select class="form-select" id="cancel_reason" name="reason" required>
                                <option value="" selected disabled data-i18n="cancel_reason_select">اختر سبب الإلغاء</option>
                                <?php foreach ($cancel_reasons as $cr): ?>
                                    <option value="<?php echo e($cr); ?>" data-i18n-value="<?php echo e($cr); ?>"><?php echo e($cr); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-2">
                            <label for="cancel_details" class="form-label" data-i18n="cancel_details_label">تفاصيل إضافية (اختياري)</label>
                            <textarea class="form-control" id="cancel_details" name="details" rows="2" maxlength="200"
                                      data-i18n-placeholder="cancel_details_placeholder"
                                      placeholder="أضف أي ملاحظات إضافية حول الإلغاء"></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal" data-i18n="map_cancel_btn">إلغاء</button>
                        <button type="submit" class="btn btn-danger" data-i18n="btn_confirm_cancel">تأكيد إلغاء البلاغ</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            document.querySelectorAll('.dash-tab').forEach(function (tab) {
                tab.addEventListener('click', function () {
                    document.querySelectorAll('.dash-tab').forEach(function (t) { t.classList.remove('active'); });
                    document.querySelectorAll('.dash-panel').forEach(function (p) { p.classList.remove('active'); });
                    tab.classList.add('active');
                    const panel = document.getElementById(tab.getAttribute('data-panel'));
                    if (panel) panel.classList.add('active');
                });
            });

            document.querySelectorAll('.btn-open-cancel-modal').forEach(function (btn) {
                btn.addEventListener('click', function () {
                    const input = document.getElementById('cancel_lost_item_id');
                    if (input) input.value = btn.getAttribute('data-lost-id') || '';
                });
            });
        });
    </script>

<?php require __DIR__ . '/partials/footer.php'; ?>
