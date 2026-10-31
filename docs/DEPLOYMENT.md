# تشغيل وتثبيت وزنة | Application Deployment Method

## 1. تجهيز بيئة التطوير

ثبّت Flutter متوافقًا مع إصدار Dart المحدد في pubspec.yaml، وAndroid Studio مع Android SDK. افتح Device Manager وأنشئ محاكي Android، ثم تحقق من البيئة:

```sh
flutter doctor
flutter pub get
flutter devices
```

## 2. تجربة المشروع دون قاعدة بيانات

من مجلد المشروع، انسخ lib/firebase_options.example.dart إلى lib/firebase_options.dart إذا لم يكن الملف موجودًا. تحتوي نسخة التسليم على قيم تجريبية لهذا الملف.

```sh
flutter run -d <ANDROID_DEVICE_ID> -t lib/demo.dart
```

في Android Studio افتح مجلد المشروع، واختر جهاز Android بدل Windows. أنشئ إعداد Flutter بملف دخول lib/demo.dart ثم اضغط Run. هذا المسار لا يسجل الدخول ولا يكتب في قاعدة بيانات سحابية؛ الحفظ محلي.

## 3. تفعيل الحسابات في مشروع Firebase مستقل

1. أنشئ مشروع Firebase وسجّل تطبيق Android بمعرف com.example.waznah، أو حدّث معرف التطبيق في المشروعين بشكل متطابق.
2. فعّل Authentication بطريقة Email/Password وأنشئ قاعدة Cloud Firestore.
3. ضع ملف google-services.json الخاص بمشروعك في android/app/، واملأ lib/firebase_options.dart بقيم FirebaseOptions المطابقة له: apiKey وappId وmessagingSenderId وprojectId وstorageBucket.
4. راجع firestore.rules وانشرها إلى مشروعك. لا تستخدم قواعد تسمح للجميع بالقراءة والكتابة.
5. قبل استخدام أدوات الإدارة على مشروع جديد، حدّث projectId في tool/admin/publish.mjs وtool/admin/download.mjs؛ تحتوي هذه الأدوات معرف مشروع التطوير الأصلي ولا تتضمن صلاحياته. الكتالوج المحلي متاح كبديل. لنشر catalog/published استخدم أدوات الكتالوج وفق tool/admin/README.md وبصلاحيات مشروعك فقط.
6. شغّل lib/main.dart وأنشئ حساب اختبار بنفسك، ثم اختبر تأكيد البريد وحفظ المفضلة واسترجاعها.

لا ترفع إعداداتك المحلية أو اعتماد المسؤول إلى المستودع. عينة الإعدادات لا تمثل اتصالًا جاهزًا بالحسابات.

## 4. بناء نسخة Android قابلة للتثبيت

للعرض الأكاديمي دون حساب سحابي:

```sh
flutter build apk --debug -t lib/demo.dart
```

يُنتج الملف:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

لتثبيته على محاكي أو جهاز مصرح بتوصيله:

```sh
adb -s <ANDROID_DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

إذا لم يكن adb ضمن PATH، استخدم نسخته من Android SDK/platform-tools. لتحديث النسخة المتصلة بقاعدة مشروعك، ابنِ باستخدام lib/main.dart بعد إعداد Firebase.

هذه طريقة تثبيت نسخة اختبار، وليست نشرًا في Google Play. إعداد release الحالي يستخدم مفتاح debug؛ نشر المتجر يتطلب إعداد توقيع إصدار مستقل ومراجعة متطلبات المتجر. لا توجد نسخة iOS مختبرة أو موقع عام ضمن هذا التسليم.

## 5. التحقق قبل التسليم

```sh
flutter analyze
flutter test
```

جرّب البحث والتصفية والمفضلة وقائمة الصيانة والتنقل ومقدمة التطبيق. اختبر الروابط الخارجية على جهاز متصل. لا تستخدم بيانات إنتاج لاختبارات قواعد Firebase؛ استخدم مشروع المحاكيات demo-waznah-rules المذكور في دليل الإدارة.

## 6. رابط GitHub

يُسلّم رابط المستودع العام بعد رفع الملفات. يجب أن يظهر README في الصفحة الرئيسية، وأن تعمل روابط docs/RESOURCES.md وdocs/DEPLOYMENT.md وملف التحليل PDF. لا يوجد رابط مستودع نهائي قبل إتمام الرفع والتحقق منه.
