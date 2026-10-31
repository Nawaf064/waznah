import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/catalog_data.dart';
import 'package:waznah/main.dart';
import 'package:waznah/favorites_store.dart';
import 'package:waznah/garage.dart';
import 'package:waznah/ios_style.dart';

import 'garage_test.dart' show MemoryGarage;

class MemoryFavorites implements FavoritesStore {
  Set<String> ids = {};
  bool failSave = false;
  bool failLoad = false;
  @override
  Future<Set<String>> load() async {
    if (failLoad) throw StateError('Storage unavailable');
    return {...ids};
  }

  @override
  Future<void> save(Set<String> value) async {
    if (failSave) throw StateError('Storage unavailable');
    ids = {...value};
  }
}

void main() {
  testWidgets(
    'iOS toolbar keeps account visible and runs overflow actions on small screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var refreshed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildIosTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: IosToolbar(
                title: 'وزنة',
                actions: [
                  IconButton(
                    tooltip: 'حسابي',
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.person),
                  ),
                  IconButton(
                    tooltip: 'تحديث القطع والأسعار',
                    onPressed: () => refreshed++,
                    icon: const Icon(CupertinoIcons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('حسابي'), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis_circle));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحديث القطع والأسعار'));
      await tester.pumpAndSettle();
      expect(refreshed, 1);
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Saved car filters catalog and maintenance updates quantity totals',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final garage = MemoryGarage()
        ..raw = GarageData(
          car: const SavedCar('تويوتا', 'كامري', 2021, '6 سلندر'),
        ).encode();
      await tester.pumpWidget(
        MyApp(favoritesStore: MemoryFavorites(), garageStore: garage),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PartCard), findsOneWidget);
      await tester.ensureVisible(find.text('تفاصيل السعر'));
      await tester.tap(find.text('تفاصيل السعر'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('أضف لقائمة الصيانة'));
      await tester.tap(find.text('أضف لقائمة الصيانة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض قائمة الصيانة'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('زيادة كمية فلتر زيت'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('زيادة كمية فلتر زيت'));
      await tester.pumpAndSettle();
      expect(GarageData.decode(garage.raw!).knownTotalHalalas, 10062);
      expect(find.text('١٠٠٫٦٢ \uFFFC'), findsOneWidget);
      await tester.ensureVisible(find.text('إزالة من القائمة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إزالة من القائمة'));
      await tester.pumpAndSettle();
      expect(GarageData.decode(garage.raw!).items, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  test('Search combines words and matches years inside a fitment range', () {
    expect(filterParts(query: 'كامري زيت ٢٠٢١').single.id, 'oil-filter');
    expect(filterParts(query: 'كامري 2025'), isEmpty);
    expect(
      matchesSearch('كهرباء السيارات فحص كمبيوتر', 'كمبيوتر كهرباء'),
      isTrue,
    );
  });

  testWidgets('Loading failure keeps saved favorites and can be retried', (
    tester,
  ) async {
    final store = MemoryFavorites()
      ..ids = {'oil-filter'}
      ..failLoad = true;
    await tester.pumpWidget(MyApp(favoritesStore: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    expect(find.text('مفضلتك تنتظر أول قطعة'), findsNothing);
    store.failLoad = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('فلتر زيت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workshop empty search can reset and survives tab navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp(favoritesStore: MemoryFavorites()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الورش'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'غير موجود');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('عرض كل الورش'));
    await tester.tap(find.text('عرض كل الورش'));
    await tester.pumpAndSettle();
    expect(find.text('مركز العاصمة الإلكتروني'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'كمبيوتر');
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الورش'));
    await tester.pumpAndSettle();
    expect(find.text('كمبيوتر'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Combined filters and sorting use the lowest supplier price', () {
    final parts = filterParts(
      query: 'فلتر',
      brand: 'تويوتا',
      category: 'فلاتر',
    );
    expect(parts.map((part) => part.id), [
      'corolla-oil-filter',
      'oil-filter',
      'corolla-cross-oil-filter',
      'yaris-cabin-filter-denso',
      'yaris-cabin-filter-japan',
      'camry-air-filter',
      'prado-cabin-filter',
    ]);
    expect(parts.first.lowestPrice, 32.29);
    expect(money(50.31), '٥٠٫٣١ ريال');
    expect(filterParts().last.lowestPrice, isNull);
    expect(filterParts(highestFirst: true).last.lowestPrice, isNull);
    expect(filterParts(highestFirst: true).first.id, 'battery');
    expect(filterParts(query: '  النترا ').single.id, 'brake-pads');
    expect(filterParts(query: 'غير موجود'), isEmpty);
  });

  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(1100, 1500),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp(favoritesStore: MemoryFavorites()));
    await tester.pumpAndSettle();
  }

  testWidgets('Search handles empty results and resets filters', (
    tester,
  ) async {
    await start(tester);
    expect(
      Directionality.of(tester.element(find.byType(WaznahHome))),
      TextDirection.rtl,
    );
    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pumpAndSettle();
    expect(find.text('ما لقينا قطعة بهالمواصفات'), findsOneWidget);
    await tester.ensureVisible(find.text('عرض كل القطع'));
    await tester.tap(find.text('عرض كل القطع'));
    await tester.pumpAndSettle();
    expect(find.byType(PartCard), findsNWidgets(catalogParts.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favorite survives navigation and can be removed', (
    tester,
  ) async {
    await start(tester);
    final save = find.byTooltip('حفظ فلتر زيت في المفضلة');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    expect(find.byType(PartCard), findsOneWidget);
    expect(find.text('فلتر زيت'), findsOneWidget);
    await tester.tap(find.byTooltip('إزالة فلتر زيت من المفضلة'));
    await tester.pumpAndSettle();
    expect(find.text('مفضلتك تنتظر أول قطعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Compare supplier prices and continue to workshop labor details',
    (tester) async {
      await start(tester);
      await tester.enterText(find.byType(TextField), 'فلتر هواء');
      await tester.pumpAndSettle();
      final compare = find.text('قارن الأسعار').first;
      await tester.ensureVisible(compare);
      await tester.tap(compare);
      await tester.pumpAndSettle();
      expect(find.text('قارن عروض المتاجر'), findsOneWidget);
      expect(find.text('الأقل ضمن الأسعار المنشورة'), findsOneWidget);
      expect(find.text('غير متوفر عند المراجعة'), findsOneWidget);
      final workshops = find.text('استكشف الورش واطلب تسعيرة');
      await tester.ensureVisible(workshops);
      await tester.tap(workshops);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'فحص كمبيوتر');
      await tester.pumpAndSettle();
      expect(find.text('مركز العاصمة الإلكتروني'), findsOneWidget);
      expect(
        find.text('مركز عبدالعزيز السبيعي لتعديل وصيانة السيارات'),
        findsNothing,
      );
      await tester.tap(find.text('تفاصيل الورشة والموقع'));
      await tester.pumpAndSettle();
      expect(find.text('الخدمات وأجرة الشغل'), findsOneWidget);
      expect(
        find.textContaining('لا تتوفر لدينا قائمة أسعار موثقة'),
        findsOneWidget,
      );
      expect(find.text('نسخ رابط الموقع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small phone has navigation and no layout overflow', (
    tester,
  ) async {
    await start(tester, size: const Size(360, 800));
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('الورش'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('شغل اليد'));
    await tester.pumpAndSettle();
    expect(find.text('اعرف وش يشمل السعر'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iPhone filters apply a selection and cancel without changing it',
    (tester) async {
      await start(tester, size: const Size(390, 844));
      await tester.tap(find.text('كل السيارات'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(
        find.widgetWithText(CupertinoActionSheetAction, 'تويوتا'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PartCard), findsNWidgets(8));
      expect(find.text('كل الموديلات'), findsOneWidget);
      await tester.tap(find.text('تويوتا').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CupertinoActionSheetAction, 'إلغاء'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PartCard), findsNWidgets(8));
      await tester.ensureVisible(find.text('فرامل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرامل'));
      await tester.pumpAndSettle();
      expect(find.text('ما لقينا قطعة بهالمواصفات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Favorites survive a new app instance and failed writes are not committed',
    (tester) async {
      final store = MemoryFavorites();
      await tester.binding.setSurfaceSize(const Size(1100, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MyApp(favoritesStore: store));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('حفظ فلتر زيت في المفضلة'));
      await tester.tap(find.byTooltip('حفظ فلتر زيت في المفضلة'));
      await tester.pumpAndSettle();
      expect(store.ids, contains('oil-filter'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MyApp(favoritesStore: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المفضلة'));
      await tester.pumpAndSettle();
      expect(find.text('فلتر زيت'), findsOneWidget);
      store.failSave = true;
      await tester.tap(find.byTooltip('إزالة فلتر زيت من المفضلة'));
      await tester.pumpAndSettle();
      expect(find.text('فلتر زيت'), findsOneWidget);
      expect(
        find.text('تعذّر تأكيد الحفظ. تأكد من الاتصال وحدّث البيانات.'),
        findsOneWidget,
      );
      expect(store.ids, contains('oil-filter'));
    },
  );

  test(
    'Vehicle fitment excludes unknown compatibility and out-of-range years',
    () {
      expect(
        filterParts(
          brand: 'تويوتا',
          model: 'كامري',
          year: 2020,
          engine: '٦ سلندر',
        ).single.id,
        'oil-filter',
      );
      expect(filterParts(model: 'كامري', year: 2025), isEmpty);
      expect(filterParts(model: 'كامري', engine: '٤ سلندر'), isEmpty);
      expect(filterParts(query: '28113-L1000').single.id, 'air-filter');
      expect(filterParts(query: '٢٨١١٣-L١٠٠٠').single.id, 'air-filter');
    },
  );
}
