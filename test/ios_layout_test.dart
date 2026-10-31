import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/ios_style.dart';
import 'package:waznah/account_sign_in.dart';
import 'package:waznah/service_prices_page.dart';

void main() {
  testWidgets('Cupertino action wraps long Arabic labels at double text size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildIosTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: SizedBox(
                width: 220,
                child: IosActionButton.tinted(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.map),
                  label: const Text('تفاصيل الورشة والموقع'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('تفاصيل الورشة والموقع'), findsOneWidget);
  });

  testWidgets('Sign in stays scrollable with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
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
        home: AccountSignIn(
          onGuest: () {},
          signIn: (_, _) async {},
          register: (_, _) async {},
          resetPassword: (_) async {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب بريدك الإلكتروني أولًا.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Service prices remain readable with large text on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: const ServicePricesPage(),
        ),
      );
      final list = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: list,
      );
      await tester.enterText(find.byType(TextField), 'البواجي');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('من ١٢٠ \uFFFC إلى ٢٢٠ \uFFFC'),
        200,
        scrollable: list,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
