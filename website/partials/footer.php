<?php
/* partials/footer.php — الفوتر والسكربتات المشتركة (Bootstrap + Leaflet + i18n + app.js) */
?>
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
<?php
// صفحات تحتاج سكربتات إضافية تضعها في $footerScripts قبل تضمين هذا الملف
if (!empty($footerScripts)) {
    echo $footerScripts;
}
?>
</body>
</html>
