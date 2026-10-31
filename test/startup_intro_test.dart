import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/startup_intro.dart';

void main() {
  testWidgets(
    'Reopening immediately replays intro without remounting destination',
    (tester) async {
      var mounts = 0;
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WaznahIntro(
            child: Builder(
              builder: (_) {
                mounts++;
                return const Text('ready');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('وزنة'), findsNothing);
      final initialMounts = mounts;
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      expect(find.text('وزنة'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      expect(find.text('وزنة'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('وزنة'), findsNothing);
      expect(mounts, initialMounts);
    },
  );
  testWidgets(
    'Cold startup defers destination work until animation completes',
    (tester) async {
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WaznahIntro(
            deferDestination: true,
            child: Builder(
              builder: (_) {
                builds++;
                return const Text('destination');
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      expect(builds, 0);
      await tester.pumpAndSettle();
      expect(builds, 1);
      expect(find.text('destination'), findsOneWidget);
    },
  );
  testWidgets('Waits for visible first frame before zoom and word reveal', (
    tester,
  ) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: WaznahIntro(
          firstFrameReady: ready.future,
          child: const Text('ready'),
        ),
      ),
    );
    double opacity() => tester
        .widget<Opacity>(find.byKey(const ValueKey('intro-wordmark')))
        .opacity;
    double scale() => tester
        .widget<Transform>(find.byKey(const ValueKey('intro-zoom')))
        .transform
        .entry(0, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(opacity(), 0);
    expect(scale(), 1.8);
    ready.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2700));
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));
    expect(scale(), closeTo(.8, .001));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('intro-wordmark')), findsNothing);
  });
  testWidgets(
    'Intro rotates, reveals branding, and releases destination once',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => WaznahIntro(child: child!),
          home: Scaffold(
            body: TextButton(
              onPressed: () => taps++,
              child: const Text('destination'),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('وزنة'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text('وزنة'), findsNothing);
      await tester.tap(find.text('destination'));
      expect(taps, 1);
    },
  );
  testWidgets('Reduced motion skips startup animation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: WaznahIntro(child: child!),
        ),
        home: const Scaffold(body: Text('ready')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('وزنة'), findsNothing);
    expect(find.text('ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
