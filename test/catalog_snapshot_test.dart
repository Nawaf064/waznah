import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waznah/main.dart';

import 'widget_test.dart' show MemoryFavorites;
import 'garage_test.dart' show MemoryGarage;

import 'package:waznah/catalog_snapshot.dart';
import 'package:waznah/catalog_repository.dart';
import 'package:waznah/catalog_data.dart';
import 'package:waznah/garage.dart';

Map<String, dynamic> draft() =>
    jsonDecode(jsonEncode(CatalogSnapshot.bundled.toJson()..['revision'] = 1))
        as Map<String, dynamic>;

void main() {
  test(
    'Catalog survives controller restart offline and rejects server rollback',
    () async {
      CatalogSnapshot? disk;
      final first = CatalogController(
        () async => CatalogSnapshot.fromJson(draft()..['revision'] = 3),
        saveCache: (data) async => disk = data,
      );
      await first.refresh();
      first.dispose();
      var offline = true;
      final reopened = CatalogController(() async {
        if (offline) throw StateError('offline');
        return CatalogSnapshot.fromJson(draft()..['revision'] = 2);
      }, loadCache: () async => disk);
      await reopened.refresh();
      expect(reopened.data.revision, 3);
      expect(reopened.failed, isTrue);
      offline = false;
      await reopened.refresh();
      expect(reopened.data.revision, 3);
      expect(reopened.failed, isTrue);
      reopened.dispose();
    },
  );

  test(
    'Broken cache and failed disk write do not discard a valid server result',
    () async {
      final c = CatalogController(
        () async => CatalogSnapshot.fromJson(draft()),
        loadCache: () async => throw const FormatException('damaged'),
        saveCache: (_) async => throw StateError('disk full'),
      );
      await c.refresh();
      expect(c.data.revision, 1);
      expect(c.failed, isFalse);
      c.dispose();
    },
  );

  test(
    'Signing out during a catalog request prevents late cache writes',
    () async {
      final response = Completer<CatalogSnapshot>();
      var saves = 0;
      final c = CatalogController(
        () => response.future,
        saveCache: (_) async {
          saves++;
        },
      );
      final pending = c.refresh();
      c.dispose();
      response.complete(CatalogSnapshot.fromJson(draft()));
      await pending;
      expect(saves, 0);
      expect(c.data.revision, 0);
    },
  );

  test(
    'Unpublished catalog is distinct from network failure and preserves data',
    () async {
      var state = 0;
      final c = CatalogController(() async {
        if (state == 0) throw const CatalogNotPublished();
        if (state == 2) throw StateError('offline');
        return CatalogSnapshot.fromJson(draft()..['revision'] = 2);
      });
      await c.refresh();
      expect(c.notPublished, isTrue);
      expect(c.failed, isFalse);
      expect(c.data.revision, 0);
      state = 1;
      await c.refresh();
      expect(c.notPublished, isFalse);
      expect(c.data.revision, 2);
      state = 0;
      await c.refresh();
      expect(c.notPublished, isTrue);
      expect(c.data.revision, 2);
      state = 2;
      await c.refresh();
      expect(c.notPublished, isFalse);
      expect(c.failed, isTrue);
      expect(c.data.revision, 2);
      c.dispose();
    },
  );
  testWidgets('Home and garage use the same injected catalog prices', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final json = draft();
    json['offers'][0]['priceHalalas'] = 6375;
    final catalog = CatalogSnapshot.fromJson(json);
    final garage = MemoryGarage()
      ..raw = GarageData(items: {'oil-filter': 2}).encode();
    await tester.pumpWidget(
      MaterialApp(
        home: WaznahHome(
          catalog: catalog,
          favoritesStore: MemoryFavorites(),
          garageStore: garage,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '04152-310903');
    await tester.pumpAndSettle();
    expect(find.byType(PartCard), findsOneWidget);
    expect(find.text('٦٣٫٧٥ \uFFFC'), findsOneWidget);
    await tester.tap(find.text('أضف سيارتك وجهّز قائمة الصيانة'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('مجموع الأسعار المعروفة'),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('١٢٧٫٥٠ \uFFFC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Published offers drive search and maintenance totals in halalas', () {
    final json = draft();
    json['offers'][0]['priceHalalas'] = 6375;
    final catalog = CatalogSnapshot.fromJson(json);
    expect(
      filterParts(
        source: catalog.parts,
        query: '04152-310903',
      ).single.lowestPrice,
      63.75,
    );
    final garage = GarageData(items: {'oil-filter': 2, 'retired-item': 1});
    expect(garage.totalFor(catalog.parts), 12750);
    expect(garage.unpricedFor(catalog.parts), 1);
    expect(catalog.toJson(), json);
  });
  test('Reject malformed snapshots instead of partially updating prices', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (j) => j['offers'][0]['priceHalalas'] = -1,
      (j) => j['offers'][0]['priceHalalas'] = 1.5,
      (j) => j['offers'][0]['partId'] = 'unknown',
      (j) => j['offers'][0]['sourceUrl'] = 'javascript:alert(1)',
      (j) => j['parts'][1]['id'] = j['parts'][0]['id'],
      (j) => j['partIds'] = ['other'],
      (j) => j['services'][3]['maxPriceHalalas'] = 100,
      (j) => j['services'][0]['source'] = null,
      (j) => j['schemaVersion'] = 20,
      (j) => j['reviewedAt'] = '2026-02-31',
    ];
    for (final mutate in mutations) {
      final json = draft();
      mutate(json);
      expect(() => CatalogSnapshot.fromJson(json), throwsFormatException);
    }
  });
  test('Catalog failure keeps fallback or last successful revision; retry recovers', () async {
    var fail = true;
    var revision = 2;
    final c = CatalogController(() async {
      if (fail) throw StateError('offline');
      return CatalogSnapshot.fromJson(draft()..['revision'] = revision);
    });
    await c.refresh();
    expect(c.failed, isTrue);
    expect(c.data.revision, 0);
    fail = false;
    await c.refresh();
    expect(c.failed, isFalse);
    expect(c.data.revision, 2);
    revision = 1;
    await c.refresh();
    expect(c.failed, isTrue);
    expect(c.data.revision, 2);
    revision = 3;
    await c.refresh();
    expect(c.data.revision, 3);
    c.dispose();
  });
}
