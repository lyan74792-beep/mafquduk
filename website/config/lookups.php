<?php
/* ============================================================
   config/lookups.php — fixed option lists stored in the database as
   Arabic values (category_name, location_name, …). They are data, shared by
   the website forms, the API (GET /lookups) and the app. Edit them here only.
   ============================================================ */

return array(
    // value used for "other" in category and landmark lists (free text follows)
    'other' => 'أخرى',

    'categories' => array(
        'وثائق وأوراق ثبوتية',
        'أجهزة إلكترونية',
        'حقائب ومقتنيات',
        'مجوهرات وساعات',
        'أخرى',
    ),

    // landmark => [latitude, longitude] (approximate; used when no exact GPS point)
    'landmarks' => array(
        'الحرم المكي (عام)'       => array(21.4225, 39.8262),
        'أبواب الحرم الرئيسية'     => array(21.4227, 39.8262),
        'برج الساعة وأبراج البيت'  => array(21.4189, 39.8256),
        'برج زمزم'                 => array(21.4188, 39.8267),
        'المسعى / المطاف'          => array(21.4225, 39.8262),
        'موقف سيارات أجياد'        => array(21.4170, 39.8250),
        'مشعر منى'                 => array(21.4133, 39.8933),
        'مشعر عرفات'               => array(21.3549, 39.9841),
        'مشعر مزدلفة'              => array(21.3892, 39.9360),
        'منطقة التنعيم'            => array(21.4627, 39.8313),
    ),

    // where a found item is now; the "sighting" one marks a sighting report
    'found_current_statuses' => array(
        'تم تسليمه لكبائن المفقودات',
        'تم تسليمه لرجل الأمن',
        'موجود بحوزتي حالياً',
        'تركته في مكانه (مشاهدة فقط)',
    ),
    'sighting_status' => 'تركته في مكانه (مشاهدة فقط)',

    'cancel_reasons' => array(
        'تم العثور على المفقود',
        'تم تقديم البلاغ بالخطأ',
        'سبب آخر',
    ),
);
