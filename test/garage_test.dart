import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/catalog_data.dart';
import 'package:waznah/garage.dart';
import 'package:waznah/garage_page.dart';
import 'package:waznah/ios_style.dart';

class MemoryGarage implements GarageStore {
  String? raw;
  bool fail = false;
  @override
  Future<GarageData> load() async =>
      raw == null ? GarageData() : GarageData.decode(raw!);
  @override
  Future<void> save(GarageData data) async {
    if (fail) throw StateError('Unavailable');
    raw = data.encode();
  }
}

void main() {
  test(
    'Garage restores car and quantities, totals halalas and excludes unknowns',
    () async {
      final store = MemoryGarage();
      final c = GarageController(store);
      await c.load();
      await c.saveCar(const SavedCar('تويوتا', 'كامري', 2021, '6 سلندر'));
      await c.setQuantity('oil-filter', 3);
      await c.setQuantity('shock-absorber', 2);
      final restored = GarageController(store);
      await restored.load();
      expect(restored.data.car!.year, 2021);
      expect(restored.data.items['oil-filter'], 3);
      expect(restored.data.knownTotalHalalas, 15093);
      expect(restored.data.unpricedCount, 2);
      store.fail = true;
      expect(await restored.setQuantity('oil-filter', 0), isFalse);
      expect(restored.data.items['oil-filter'], 3);
      expect(restored.error, isNotNull);
      c.dispose();
      restored.dispose();
    },
  );
  test(
    'Saved car normalizes Arabic digits and rejects wrong engine or year',
    () {
      final part = catalogParts.first;
      expect(
        const SavedCar('تويوتا', 'كامري', 2021, '6 سلندر').matches(part),
        isTrue,
      );
      expect(
        const SavedCar('تويوتا', 'كامري', 2021, '٤ سلندر').matches(part),
        isFalse,
      );
      expect(
        const SavedCar('تويوتا', 'كامري', 2025, '٦ سلندر').matches(part),
        isFalse,
      );
      expect(
        const SavedCar(
          'هيونداي',
          'النترا',
          2021,
          '2.0',
        ).matches(catalogParts[1]),
        isTrue,
      );
    },
  );
  test(
    'Corrupt storage stays protected until recovery; quantities are bounded',
    () async {
      final store = MemoryGarage()..raw = '{broken';
      final c = GarageController(store);
      await c.load();
      expect(c.ready, isFalse);
      expect(await c.setQuantity('oil-filter', 1), isFalse);
      expect(store.raw, '{broken');
      store.raw = null;
      await c.load();
      expect(await c.setQuantity('oil-filter', 100), isFalse);
      expect(await c.setQuantity('oil-filter', 1), isTrue);
      expect(await c.setQuantity('oil-filter', 0), isTrue);
      expect(c.data.items, isEmpty);
      c.dispose();
    },
  );
  testWidgets('Car editor validates and saves Arabic year on a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = GarageController(MemoryGarage());
    await c.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildIosTheme(),
        home: GaragePage(controller: c, onCarSaved: () {}, onBrowse: () {}),
      ),
    );
    await tester.tap(find.text('إضافة سيارتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ السيارة'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل الشركة'), findsOneWidget);
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('حفظ السيارة')).dy, lessThan(500));
    expect(tester.takeException(), isNull);
    for (final field in [
      ('الشركة', 'تويوتا'),
      ('الموديل', 'كامري'),
      ('سنة الصنع', '٢٠٢١'),
      ('المحرك', '٦ سلندر'),
    ]) {
      await tester.enterText(
        find.widgetWithText(TextFormField, field.$1),
        field.$2,
      );
    }
    await tester.tap(find.text('حفظ السيارة'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(c.data.car!.year, 2021);
    expect(find.textContaining('كامري'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
