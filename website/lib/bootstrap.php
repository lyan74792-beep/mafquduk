<?php
/* ============================================================
   lib/bootstrap.php — load the shared business layer:
   helpers (functions.php), error types, messages (i18n) and every service.
   Used by the API (api/index.php), the web pages and tools/.
   ============================================================ */

require_once __DIR__ . '/../functions.php';   // also loads lib/errors.php + lib/i18n.php

$serviceFiles = glob(__DIR__ . '/services/*.php');
sort($serviceFiles);
foreach ($serviceFiles as $serviceFile) {
    require_once $serviceFile;
}
unset($serviceFiles, $serviceFile);
