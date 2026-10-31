import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/service_prices_page.dart';

void main() {
  testWidgets('Services show price conditions and filter without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ServicePricesPage(),
        ),
      ),
    );
    expect(find.textContaining('يبدأ من ١٠ \uFFFC'), findsOneWidget);
    expect(find.textContaining('بشرط شراء الزيت من بروف'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'البواجي');
    await tester.pump();
    expect(find.textContaining('من ١٢٠ \uFFFC إلى ٢٢٠ \uFFFC'), findsOneWidget);
    expect(find.text('مصدر السعر وشروطه'), findsOneWidget);
    expect(find.text('اتصل لتأكيد السعر'), findsNothing);
    await tester.enterText(find.byType(TextField), 'المساعدات');
    await tester.pump();
    expect(find.text('اطلب تسعيرة'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(find.text('ما لقينا خدمة تطابق بحثك.'), findsOneWidget);
    await tester.tap(find.text('عرض كل الخدمات'));
    await tester.pump();
    expect(find.textContaining('يبدأ من ١٠ \uFFFC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
