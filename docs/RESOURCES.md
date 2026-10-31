# المجلدات والموارد | Resource Folder Information

| المسار | المحتوى والغرض |
| --- | --- |
| lib/main.dart | مدخل التطبيق المتصل بالحسابات وصفحات القطع والورش والمفضلة والتنقل |
| lib/demo.dart | مدخل العرض الأكاديمي المحلي دون اتصال بحسابات Firebase |
| lib/ios_style.dart | الهوية البصرية والألوان والعناصر المشتركة |
| lib/startup_intro.dart | حركة المفتاح والاسم عند بدء التطبيق والعودة إليه |
| lib/currency_text.dart | عرض رمز الريال مع المحافظة على قراءة السعر لذوي الإعاقة البصرية |
| lib/bilingual_labels.dart | الأسماء الإنجليزية للمنتجات والخدمات والقوائم |
| lib/catalog_data.dart وlib/service_data.dart | البيانات المرفقة ومعلومات الأسعار والخدمات |
| lib/catalog_snapshot.dart | التحقق من الكتالوج وتحويل البيانات |
| lib/catalog_repository.dart وlib/catalog_cache.dart | قراءة الكتالوج السحابي والتخزين المؤقت |
| lib/account_gate.dart وlib/account_sign_in.dart | تجهيز الحساب وصفحات الدخول والتسجيل والاستعادة |
| lib/cloud_stores.dart | حفظ بيانات المستخدم السحابية والتحقق من تعارض التعديلات |
| lib/favorites_store.dart وlib/favorites_storage_*.dart | حفظ المفضلة محليًا حسب المنصة |
| lib/garage.dart وlib/garage_page.dart | بيانات السيارة وقائمة الصيانة والكميات والمجموع |
| lib/external_link.dart | فتح الروابط الخارجية وإتاحة النسخ عند تعذر الفتح |
| assets/fonts/NotoSansArabic.ttf | الخط العربي المستخدم في التطبيق |
| assets/fonts/OFL.txt | ترخيص الخط |
| assets/currency/saudi-riyal.png | رمز الريال الرسمي؛ يتغير حجمه ولونه في الواجهة |
| assets/currency/SOURCE.md | مصدر الرمز الرسمي |
| android/ | ملفات البناء وبيان التطبيق وموارد أندرويد |
| ios/ | ملفات منصة iOS الأصلية؛ تحتاج تجهيزًا واختبارًا على macOS قبل اعتمادها |
| data/catalog-draft.json | مسودة الكتالوج؛ مبالغ العروض مخزنة بالهللة |
| firestore.rules وfirebase.json | قواعد الوصول وإعداد محاكيات Firebase المحلية |
| test/ | اختبارات Flutter وDart |
| tool/admin/ | أدوات إدارة الكتالوج واختبارات المحاكيات؛ لا تتضمن اعتماد دخول مسؤول |
| docs/ | توثيق التسليم وتحليل المشروع |
| sources.md | مصادر الأسعار والورش وشروط استخدامها |

الصور التصورية التي استُخدمت لاختيار الألوان ليست موارد داخل التطبيق. لا يعتمد التشغيل على ملفات صور خارج المستودع.

لا ترفع ملفات البناء أو المجلدات المؤقتة أو node_modules أو السجلات أو مفاتيح التوقيع أو بيانات اعتماد Google إلى GitHub. تُستثنى إعدادات Firebase المحلية، وتتوفر عينة إعدادات قابلة للنسخ.
