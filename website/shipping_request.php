<?php
/* shipping_request.php — نموذج طلب الشحن والتوصيل للطلبات المعتمدة بدون شحن */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';
require_login('user');

$uid             = (int)$_SESSION['uid'];
$selectedClaimId = isset($_GET['claim_id']) && !is_array($_GET['claim_id']) ? (int)$_GET['claim_id'] : 0;
$eligibleClaims  = array();
$defaultPhone    = '';

try {
    $claimList = claim_list_for_user($conn, $uid);
    foreach ($claimList['claims'] as $cl) {
        if ($cl['status'] === 'Approved' && empty($cl['shipping'])) {
            $eligibleClaims[] = $cl;
        }
    }
} catch (Exception $e) {
    error_log('shipping request claims load: ' . $e->getMessage());
}

try {
    $u = account_user($conn, $uid);
    if (!empty($u['phone'])) {
        $defaultPhone = (string)$u['phone'];
    }
} catch (Exception $e) {
    error_log('shipping request user load: ' . $e->getMessage());
}

$pageTitleKey = 's_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="form-card">
                    <?php render_flash(); ?>

                    <h2 class="section-header-title" data-i18n="s_title">طلب شحن وتوصيل</h2>
                    <p class="text-muted small mb-4" data-i18n="s_desc">أدخل بيانات الغرض المطلوب توصيله وعنوانك، وسنتواصل معك لتأكيد الشحن.</p>

                    <?php if (!$eligibleClaims): ?>
                        <div class="alert alert-warning small mb-3" data-i18n="s_no_approved_claims">لا توجد لديك طلبات استرداد معتمدة بدون شحن حالياً.</div>
                    <?php endif; ?>

                    <form id="shippingForm" action="process_shipping.php" method="POST" class="needs-validation" novalidate>

                        <div class="mb-3">
                            <label for="claim_id" class="form-label" data-i18n="s_claim_label">طلب الاسترداد المعتمد *</label>
                            <select class="form-select" id="claim_id" name="claim_id" required>
                                <option value="" <?php echo $selectedClaimId === 0 ? 'selected' : ''; ?> disabled data-i18n="s_claim_choose">اختر الغرض المعتمد للاسترداد</option>
                                <?php foreach ($eligibleClaims as $cl): ?>
                                    <?php
                                    $cid  = (int)$cl['claim_id'];
                                    $item = $cl['item'];
                                    ?>
                                    <option value="<?php echo $cid; ?>" <?php echo $selectedClaimId === $cid ? 'selected' : ''; ?>>
                                        #<?php echo $cid; ?> — <?php echo e($item['item_name']); ?> (<?php echo e($item['category'] ?: '—'); ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <div class="invalid-feedback" data-i18n="s_claim_choose_err">يرجى اختيار طلب الاسترداد.</div>
                        </div>

                        <div class="mb-3">
                            <label for="city" class="form-label" data-i18n="s_city">المدينة *</label>
                            <input type="text" class="form-control" id="city" name="city" maxlength="100"
                                   data-i18n-placeholder="s_city_ph" placeholder="مثال: مكة المكرمة، جدة، الرياض" required>
                            <div class="invalid-feedback" data-i18n="s_city_err">يرجى إدخال المدينة.</div>
                        </div>

                        <div class="mb-3">
                            <label for="address" class="form-label" data-i18n="s_address">العنوان بالتفصيل *</label>
                            <textarea class="form-control" id="address" name="address" rows="3"
                                      data-i18n-placeholder="s_address_ph" placeholder="المدينة، الحي، الشارع، ورقم المبنى" maxlength="500" required></textarea>
                            <div class="invalid-feedback" data-i18n="s_address_err">يرجى كتابة العنوان.</div>
                        </div>

                        <div class="mb-3">
                            <label for="phone" class="form-label" data-i18n="s_phone">رقم التواصل *</label>
                            <input type="tel" class="form-control" id="phone" name="phone"
                                   value="<?php echo e($defaultPhone); ?>"
                                   data-i18n-placeholder="placeholder_phone" placeholder="05XXXXXXXX" pattern="^05[0-9]{8}$" required>
                            <div class="invalid-feedback" data-i18n="s_phone_err">يرجى إدخال رقم جوال سعودي صحيح (05XXXXXXXX).</div>
                        </div>

                        <div class="mb-4">
                            <label for="notes" class="form-label"><span data-i18n="s_notes">ملاحظات</span> <span class="text-muted fw-normal" data-i18n="optional_tag">(اختياري)</span></label>
                            <textarea class="form-control" id="notes" name="notes" rows="2"
                                      data-i18n-placeholder="s_notes_ph" placeholder="أي تفاصيل تساعد في التوصيل" maxlength="255"></textarea>
                        </div>

                        <button type="submit" class="btn btn-gov-submit" data-i18n="s_submit">إرسال طلب الشحن</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const form = document.getElementById('shippingForm');
            if (!form) return;
            form.addEventListener('submit', function (e) {
                if (!form.checkValidity()) {
                    e.preventDefault();
                    e.stopPropagation();
                }
                form.classList.add('was-validated');
            });
        });
    </script>

<?php require __DIR__ . '/partials/footer.php'; ?>
