import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/external_link.dart';
import 'package:waznah/garage.dart';
import 'package:waznah/garage_page.dart';
import 'package:waznah/ios_style.dart';

import 'garage_test.dart' show MemoryGarage;
import 'widget_test.dart' show MemoryFavorites;

import 'package:waznah/main.dart';

void main() {
  testWidgets(
    'Failed external link remains selectable and copies exact destination',
    (tester) async {
      String? copied;
      const launcher = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        launcher,
        (_) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          launcher,
          null,
        ),
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final destination = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': 'ورشة غرب الرياض',
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildIosTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => openExternal(context, destination),
                child: const Text('فتح'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();
      expect(find.text('تعذّر فتح الرابط'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.tap(find.text('نسخ'));
      await tester.pumpAndSettle();
      expect(copied, destination.toString());
      expect(find.text('تعذّر فتح الرابط'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Car form can save with keyboard and enlarged Arabic text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final controller = GarageController(MemoryGarage());
    await controller.load();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildIosTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => CarEditor(controller: controller),
              ),
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    final values = ['تويوتا', 'كامري', '٢٠٢١', '٦ سلندر'];
    for (var i = 0; i < values.length; i++) {
      await tester.ensureVisible(find.byType(TextFormField).at(i));
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
    await tester.ensureVisible(find.text('حفظ السيارة'));
    await tester.tap(find.text('حفظ السيارة'));
    await tester.pumpAndSettle();
    expect(controller.data.car?.year, 2021);
    expect(find.byType(CarEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Part details scroll with enlarged text on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MyApp(favoritesStore: MemoryFavorites(), garageStore: MemoryGarage()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('تفاصيل السعر').first);
    await tester.tap(find.text('تفاصيل السعر').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('أضف لقائمة الصيانة'));
    await tester.pumpAndSettle();
    expect(find.text('أضف لقائمة الصيانة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
