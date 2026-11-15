/// Strings for the items, claims, matches, and shipping screens: {'ar': {...}, 'en': {...}}.
/// Turkish and Urdu for these keys live in ../strings_tr.dart and ../strings_ur.dart.
const Map<String, Map<String, String>> itemsStrings = {
  'ar': {
    // BrowseItemsScreen
    'itemsBrowseTitle': 'تصفح المفقودات والمعثورات',
    'itemsSearchHint': 'ابحث باسم الغرض أو الوصف أو الموقع...',
    'itemsFilterAll': 'الكل',
    'itemsFilterLost': 'مفقود',
    'itemsFilterFound': 'معثور عليه',
    'itemsCategoryFilterLabel': 'التصنيف',
    'itemsAllCategories': 'جميع التصنيفات',
    'itemsEmptyBrowse': 'لا توجد عناصر مطابقة لمعايير البحث.',
    'itemsLoadMoreError': 'تعذّر تحميل المزيد من العناصر',

    // ItemDetailsScreen
    'itemsDetailsTitle': 'تفاصيل الغرض',
    'itemsNoImage': 'لا توجد صورة مرفقة',
    'itemsCategoryLabel': 'التصنيف',
    'itemsLocationLabel': 'الموقع',
    'itemsDateLabel': 'التاريخ',
    'itemsCurrentStatusLabel': 'الحالة الحالية للغرض',
    'itemsDescriptionSection': 'الوصف التفصيلي',
    'itemsMapPreviewSection': 'الموقع على الخريطة',
    'itemsClaimThisButton': 'هذا الغرض لي — مطالبة بالملكية',
    'itemsLoginToClaimNotice': 'يرجى تسجيل الدخول كمستخدم لتقديم مطالبة بالملكية',

    // ClaimItemScreen
    'itemsClaimTitle': 'تقديم مطالبة بالملكية',
    'itemsClaimVerifyBannerTitle': 'نظام التحقق وإثبات الملكية',
    'itemsClaimVerifyBannerSub':
        'يرجى كتابة أوصاف دقيقة وعلامات فارقة لا يعرفها إلا صاحب الغرض الحقيقي ليتم مراجعتها ومطابقتها من قِبل الإدارة.',
    'itemsClaimItemSummarySection': 'بيانات الغرض المطالب به',
    'itemsClaimReportIdLabel': 'رقم البلاغ',
    'itemsClaimProofSection': 'إثبات الملكية والعلامات الفارقة',
    'itemsClaimDescLabel': 'وصف العلامات الفارقة والأدلة (١٠ أحرف على الأقل)',
    'itemsClaimDescHint': 'اذكر المحتويات الدقيقة أو الخدوش أو الأرقام التسلسلية أو أي علامة مميزة...',
    'itemsClaimSecuritySection': 'سؤال الأمان من واجد الغرض',
    'itemsClaimSecurityQuestionPrefix': 'سؤال التحقق:',
    'itemsClaimSecurityAnswerLabel': 'إجابتك على سؤال الأمان',
    'itemsClaimSecurityAnswerHint': 'اكتب الإجابة الدقيقة هنا...',
    'itemsClaimSubmitButton': 'إرسال طلب المطالبة',
    'itemsClaimSuccessTitle': 'تم إرسال المطالبة بنجاح',
    'itemsClaimSuccessBody':
        'تم تسجيل مطالبتك برقم المرجع أدناه. ستتم مراجعتها من قِبل الإدارة وإشعارك بالنتيجة.',
    'itemsClaimIdLabel': 'رقم المطالبة',
    'itemsClaimDoneButton': 'العودة للتفاصيل',

    // ItemsMapScreen
    'itemsMapTitle': 'خريطة المفقودات والمعثورات',
    'itemsMapRefreshTooltip': 'تحديث الخريطة',
    'itemsMapViewDetails': 'عرض التفاصيل',
    'itemsMapEmptyNotice': 'لا توجد بلاغات بإحداثيات مسجلة في هذا التصنيف',

    // MatchesScreen
    'itemsMatchesTitle': 'التطابقات المقترحة',
    'itemsMatchesIntro': 'تم رصد هذه المعثورات التي تتطابق مع بلاغات الفقدان الخاصة بك. راجعها وأكد ملكيتك.',
    'itemsMatchesEmpty': 'لا توجد تطابقات مقترحة حالياً.',
    'itemsMatchScoreLabel': 'نسبة التطابق',
    'itemsMatchLostReportRef': 'مرتبط ببلاغ الفقدان رقم',
    'itemsMatchThisIsMine': 'هذا الغرض لي',
    'itemsMatchNotMine': 'ليس لي',
    'itemsMatchClaimSheetTitle': 'تأكيد الملكية وتقديم المطالبة',
    'itemsMatchClaimSheetSub': 'أدخل العلامات المميزة للغرض لتأكيد ملكيتك وإحالة الطلب للمراجعة.',
    'itemsMatchClaimSubmitted': 'تم تقديم المطالبة على التطابق بنجاح',
    'itemsMatchRejectTitle': 'استبعاد التطابق',
    'itemsMatchRejectBody': 'هل أنت متأكد أن هذا الغرض لا يخصك؟ سيتم إزالته من قائمة التطابقات المقترحة.',
    'itemsMatchRejectConfirm': 'نعم، ليس لي',
    'itemsMatchCancel': 'إلغاء',
    'itemsMatchRejectedMsg': 'تم استبعاد التطابق',

    // MyClaimsScreen
    'itemsMyClaimsTitle': 'مطالباتي والاستلام',
    'itemsMyClaimsPickupNotice':
        'ملاحظة: بعد الموافقة على المطالبة، يمكنك استلام الغرض مباشرة من مكتب المفقودات أو طلب توصيله لعنوانك.',
    'itemsMyClaimsEmpty': 'لم تقم برفع أي مطالبات ملكية حتى الآن.',
    'itemsClaimDateLabel': 'تاريخ المطالبة',
    'itemsClaimReviewedDateLabel': 'تاريخ المراجعة',
    'itemsClaimRejectReasonPrefix': 'سبب الرفض',
    'itemsRequestDeliveryButton': 'طلب توصيل وشحن',
    'itemsClaimShippingSection': 'بيانات الشحن والتوصيل',
    'itemsShippingCarrierLabel': 'شركة الشحن',
    'itemsShippingTrackingLabel': 'رقم التتبع',

    // ShippingRequestScreen
    'itemsShippingRequestTitle': 'طلب توصيل وشحن الغرض',
    'itemsShippingAddressSection': 'عنوان التوصيل وبيانات الاستلام',
    'itemsShippingCityLabel': 'المدينة',
    'itemsShippingCityHint': 'مثال: مكة المكرمة / جدة / الرياض',
    'itemsShippingDetailAddressLabel': 'العنوان التفصيلي',
    'itemsShippingDetailAddressHint': 'الحي، الشارع، رقم المبنى، أو العنوان الوطني...',
    'itemsShippingPhoneLabel': 'رقم الجوال للتواصل عند التسليم',
    'itemsShippingPhoneHint': '05XXXXXXXX',
    'itemsShippingNotesLabel': 'ملاحظات إضافية للمندوب (اختياري)',
    'itemsShippingNotesHint': 'أوقات التواجد المفضلة أو تعليمات الوصول...',
    'itemsShippingSubmitButton': 'تأكيد طلب الشحن',
    'itemsShippingCreatedMsg': 'تم إرسال طلب الشحن والتوصيل بنجاح',

    // MyShippingScreen
    'itemsMyShippingTitle': 'طلبات الشحن والتوصيل',
    'itemsShippingEmpty':
        'لا توجد طلبات شحن حالياً. يمكنك طلب الشحن من صفحة "مطالباتي والاستلام" بعد الموافقة على مطالبتك.',
    'itemsGoToMyClaims': 'الانتقال إلى مطالباتي',
    'itemsShippingOrderPrefix': 'طلب شحن رقم',
    'itemsShippingClaimRefPrefix': 'المطالبة رقم',
    'itemsShippingAdminNoteLabel': 'ملاحظة الإدارة',
    'itemsShippingStagesTitle': 'مراحل الشحن والتسليم',
    'itemsShippingStagePending': 'قيد المراجعة',
    'itemsShippingStageApproved': 'تمت الموافقة والتجهيز',
    'itemsShippingStageShipped': 'تم الشحن',
    'itemsShippingStageDelivered': 'تم التسليم',
    'itemsShippingStageRejected': 'تم رفض طلب الشحن',
  },
  'en': {
    // BrowseItemsScreen
    'itemsBrowseTitle': 'Browse Lost & Found',
    'itemsSearchHint': 'Search by item name, description, or location...',
    'itemsFilterAll': 'All',
    'itemsFilterLost': 'Lost',
    'itemsFilterFound': 'Found',
    'itemsCategoryFilterLabel': 'Category',
    'itemsAllCategories': 'All Categories',
    'itemsEmptyBrowse': 'No items match your search criteria.',
    'itemsLoadMoreError': 'Could not load more items',

    // ItemDetailsScreen
    'itemsDetailsTitle': 'Item Details',
    'itemsNoImage': 'No image attached',
    'itemsCategoryLabel': 'Category',
    'itemsLocationLabel': 'Location',
    'itemsDateLabel': 'Date',
    'itemsCurrentStatusLabel': 'Current Item Status',
    'itemsDescriptionSection': 'Detailed Description',
    'itemsMapPreviewSection': 'Location on Map',
    'itemsClaimThisButton': 'This is mine — Claim it',
    'itemsLoginToClaimNotice': 'Please log in as a user to claim ownership',

    // ClaimItemScreen
    'itemsClaimTitle': 'Claim Item Ownership',
    'itemsClaimVerifyBannerTitle': 'Ownership Verification System',
    'itemsClaimVerifyBannerSub':
        'Please provide accurate distinguishing marks that only the true owner would know for admin verification.',
    'itemsClaimItemSummarySection': 'Claimed Item Information',
    'itemsClaimReportIdLabel': 'Report Number',
    'itemsClaimProofSection': 'Proof of Ownership & Distinguishing Marks',
    'itemsClaimDescLabel': 'Distinguishing Marks & Proof (at least 10 chars)',
    'itemsClaimDescHint': 'Describe exact contents, scratches, serial numbers, or unique marks...',
    'itemsClaimSecuritySection': 'Finder\'s Security Question',
    'itemsClaimSecurityQuestionPrefix': 'Verification Question:',
    'itemsClaimSecurityAnswerLabel': 'Your Answer',
    'itemsClaimSecurityAnswerHint': 'Enter your exact answer here...',
    'itemsClaimSubmitButton': 'Submit Ownership Claim',
    'itemsClaimSuccessTitle': 'Claim Submitted Successfully',
    'itemsClaimSuccessBody':
        'Your ownership claim has been recorded under the reference below. It will be reviewed by an admin.',
    'itemsClaimIdLabel': 'Claim Reference',
    'itemsClaimDoneButton': 'Back to Details',

    // ItemsMapScreen
    'itemsMapTitle': 'Lost & Found Map',
    'itemsMapRefreshTooltip': 'Refresh Map',
    'itemsMapViewDetails': 'View Details',
    'itemsMapEmptyNotice': 'No items with map coordinates in this filter',

    // MatchesScreen
    'itemsMatchesTitle': 'Suggested Matches',
    'itemsMatchesIntro':
        'These found items potentially match your lost reports. Review them to claim or dismiss.',
    'itemsMatchesEmpty': 'No suggested matches right now.',
    'itemsMatchScoreLabel': 'Match Score',
    'itemsMatchLostReportRef': 'Linked to lost report #',
    'itemsMatchThisIsMine': 'This is mine',
    'itemsMatchNotMine': 'Not mine',
    'itemsMatchClaimSheetTitle': 'Confirm Ownership & Claim',
    'itemsMatchClaimSheetSub':
        'Provide distinguishing marks of the item to verify ownership and submit for review.',
    'itemsMatchClaimSubmitted': 'Match claim submitted successfully',
    'itemsMatchRejectTitle': 'Dismiss Match Suggestion',
    'itemsMatchRejectBody':
        'Are you sure this item does not belong to you? It will be removed from your matches.',
    'itemsMatchRejectConfirm': 'Yes, not mine',
    'itemsMatchCancel': 'Cancel',
    'itemsMatchRejectedMsg': 'Match suggestion dismissed',

    // MyClaimsScreen
    'itemsMyClaimsTitle': 'My Claims & Delivery',
    'itemsMyClaimsPickupNotice':
        'Note: Approved items can be picked up directly from the Lost & Found office or delivered to your address.',
    'itemsMyClaimsEmpty': 'You have not submitted any ownership claims yet.',
    'itemsClaimDateLabel': 'Claim Date',
    'itemsClaimReviewedDateLabel': 'Reviewed Date',
    'itemsClaimRejectReasonPrefix': 'Rejection Reason',
    'itemsRequestDeliveryButton': 'Request Delivery',
    'itemsClaimShippingSection': 'Shipping & Delivery Info',
    'itemsShippingCarrierLabel': 'Carrier',
    'itemsShippingTrackingLabel': 'Tracking Number',

    // ShippingRequestScreen
    'itemsShippingRequestTitle': 'Request Item Delivery',
    'itemsShippingAddressSection': 'Delivery Address & Contact',
    'itemsShippingCityLabel': 'City',
    'itemsShippingCityHint': 'e.g. Makkah / Jeddah / Riyadh',
    'itemsShippingDetailAddressLabel': 'Detailed Address',
    'itemsShippingDetailAddressHint': 'District, street, building number, or national address...',
    'itemsShippingPhoneLabel': 'Contact Phone for Delivery',
    'itemsShippingPhoneHint': '05XXXXXXXX',
    'itemsShippingNotesLabel': 'Delivery Notes (Optional)',
    'itemsShippingNotesHint': 'Preferred delivery times or directions...',
    'itemsShippingSubmitButton': 'Submit Shipping Request',
    'itemsShippingCreatedMsg': 'Shipping request submitted successfully',

    // MyShippingScreen
    'itemsMyShippingTitle': 'My Shipping Requests',
    'itemsShippingEmpty':
        'No shipping requests yet. Requests are made from "My Claims" after your claim is approved.',
    'itemsGoToMyClaims': 'Go to My Claims',
    'itemsShippingOrderPrefix': 'Shipping Request #',
    'itemsShippingClaimRefPrefix': 'Claim #',
    'itemsShippingAdminNoteLabel': 'Admin Note',
    'itemsShippingStagesTitle': 'Shipping & Delivery Progress',
    'itemsShippingStagePending': 'Pending Review',
    'itemsShippingStageApproved': 'Approved & Preparing',
    'itemsShippingStageShipped': 'Shipped',
    'itemsShippingStageDelivered': 'Delivered',
    'itemsShippingStageRejected': 'Shipping Request Rejected',
  },
};
