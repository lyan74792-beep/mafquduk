<?php
/* map.php — الخريطة التفاعلية العامة لبلاغات المفقودات والمعثورات (item_map) */
require __DIR__ . '/auth.php';
require __DIR__ . '/db.php';
require __DIR__ . '/functions.php';
require_once __DIR__ . '/lib/bootstrap.php';

$rawType = isset($_GET['type']) && !is_array($_GET['type']) ? trim((string)$_GET['type']) : 'all';
$type    = in_array($rawType, array('all', 'lost', 'found'), true) ? $rawType : 'all';

$mapItems = array();
try {
    $res      = item_map($conn, $type);
    $mapItems = $res['items'];
} catch (Exception $e) {
    error_log('public map error: ' . $e->getMessage());
}

$pageTitleKey = 'map_page_title';
require __DIR__ . '/partials/head.php';
require __DIR__ . '/partials/navbar_user.php';
?>

    <div class="container dash-wrap my-4">
        <?php render_flash(); ?>

        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <div>
                <h2 class="section-title mb-1" data-i18n="map_header">خريطة المفقودات والمعثورات</h2>
                <p class="text-muted small mb-0" data-i18n="map_subtitle">استعرض مواقع البلاغات المسجلة على الخريطة في الحرم المكي الشريف والمشاعر المقدسة.</p>
            </div>

            <!-- أزرار تصفية الخريطة (الكل / مفقود / معثور) -->
            <div class="btn-group" role="group" aria-label="Map filter">
                <a href="map.php?type=all" class="btn btn-sm <?php echo $type === 'all' ? 'btn-gov-primary' : 'btn-outline-secondary'; ?>" data-i18n="filter_type_all">الكل (مفقود ومعثور)</a>
                <a href="map.php?type=lost" class="btn btn-sm <?php echo $type === 'lost' ? 'btn-gov-primary' : 'btn-outline-secondary'; ?>" data-i18n="type_lost">مفقود</a>
                <a href="map.php?type=found" class="btn btn-sm <?php echo $type === 'found' ? 'btn-gov-primary' : 'btn-outline-secondary'; ?>" data-i18n="type_found">معثور</a>
            </div>
        </div>

        <div class="dash-card position-relative">
            <div id="publicMapContainer" style="height: 500px; width: 100%; border-radius: 8px;"></div>
            <?php if (!$mapItems): ?>
                <div class="mt-3 text-center text-muted small" data-i18n="adm_map_empty">لا توجد بلاغات بإحداثيات بعد</div>
            <?php endif; ?>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const ITEMS = <?php echo json_encode($mapItems, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP); ?>;
            const mapEl = document.getElementById('publicMapContainer');
            if (!mapEl || typeof L === 'undefined') return;

            function esc(s) {
                const d = document.createElement('div');
                d.textContent = s == null ? '' : String(s);
                return d.innerHTML;
            }

            const map = L.map('publicMapContainer').setView([21.4225, 39.8262], 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap'
            }).addTo(map);

            const lang = localStorage.getItem('mafqodak_lang') || 'ar';
            const viewLabel = (typeof t === 'function') ? t(lang, 'item_view_details') : 'عرض التفاصيل';

            const pts = [];
            ITEMS.forEach(function (it) {
                const lat = parseFloat(it.lat);
                const lng = parseFloat(it.lng);
                if (isNaN(lat) || isNaN(lng)) return;

                const isLost = it.type === 'lost';
                const typeBadge = isLost
                    ? ((typeof t === 'function') ? t(lang, 'type_lost') : 'مفقود')
                    : ((typeof t === 'function') ? t(lang, 'type_found') : 'معثور');
                const itemUrl = 'item.php?type=' + encodeURIComponent(it.type) + '&id=' + encodeURIComponent(it.id);

                const popupHtml =
                    '<div style="min-width:180px;">' +
                    '<div class="fw-bold mb-1">' + esc(it.item_name) + '</div>' +
                    '<div class="small text-muted mb-1">' + esc(typeBadge) + ' &middot; ' + esc(it.category || '—') + '</div>' +
                    '<div class="small text-muted mb-2">' + esc(it.location || '—') + ' (' + esc(it.date || '') + ')</div>' +
                    '<a href="' + esc(itemUrl) + '" class="btn btn-gov-primary btn-sm text-white text-decoration-none py-1 px-2" style="font-size:0.8rem;">' + esc(viewLabel) + '</a>' +
                    '</div>';

                L.circleMarker([lat, lng], {
                    radius: 10,
                    color: isLost ? '#6b7280' : '#9E793E',
                    weight: 2,
                    fillColor: isLost ? '#374151' : '#0d4a3a',
                    fillOpacity: 0.75
                }).bindPopup(popupHtml).addTo(map);

                pts.push([lat, lng]);
            });

            if (pts.length) {
                map.fitBounds(pts, { padding: [40, 40], maxZoom: 15 });
            }
        });
    </script>

<?php require __DIR__ . '/partials/footer.php'; ?>
