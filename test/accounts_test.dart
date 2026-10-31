import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waznah/account_gate.dart';
import 'package:waznah/account_sign_in.dart';
import 'package:waznah/cloud_stores.dart';
import 'package:waznah/garage.dart';

class UnverifiedUser implements User {
  @override
  bool get emailVerified => false;
  @override
  String get email => 'test@example.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryDocuments implements AccountDocuments {
  final data = <String, Map<String, dynamic>>{};
  bool offline = false;
  bool loseWriteResponse = false;
  int writes = 0;
  @override
  Future<Map<String, dynamic>?> read(String uid, String name) async {
    if (offline) throw StateError('offline');
    final value = data['$uid/$name'];
    return value == null
        ? null
        : jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<void> write(
    String uid,
    String name,
    int revision,
    Map<String, dynamic> value,
  ) async {
    writes++;
    if (offline || (data['$uid/$name']?['revision'] ?? 0) != revision) {
      throw StateError('conflict or offline');
    }
    data['$uid/$name'] = {...value, 'revision': revision + 1};
    if (loseWriteResponse) throw StateError('Response lost after commit');
  }
}

void main() {
  test('Uncertain cloud writes require reload before a second write', () async {
    final db = MemoryDocuments();
    final favorites = CloudFavoritesStore(db, 'alice');
    final garage = CloudGarageStore(db, 'alice');
    await favorites.load();
    await garage.load();
    db.loseWriteResponse = true;
    await expectLater(favorites.save({'oil-filter'}), throwsStateError);
    await expectLater(
      garage.save(GarageData(items: {'oil-filter': 2})),
      throwsStateError,
    );
    db.loseWriteResponse = false;
    await expectLater(favorites.save({'battery'}), throwsStateError);
    await expectLater(garage.save(GarageData()), throwsStateError);
    expect(db.writes, 2);
    expect(await favorites.load(), {'oil-filter'});
    expect((await garage.load()).items, {'oil-filter': 2});
    await favorites.save({'battery'});
    await garage.save(GarageData(items: {'oil-filter': 3}));
    expect((await garage.load()).items, {'oil-filter': 3});
    expect(await favorites.load(), {'battery'});
  });
  testWidgets('Verification can retry network failure and refresh status', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountDetails(
            user: UnverifiedUser(),
            onSignOut: () async {},
            refreshVerification: () async {
              if (++calls == 1) {
                throw FirebaseAuthException(code: 'network-request-failed');
              }
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('تحققت من بريدي'));
    await tester.pumpAndSettle();
    expect(find.text(accountError('network-request-failed')), findsOneWidget);
    expect(find.text('البريد غير مؤكد'), findsOneWidget);
    await tester.tap(find.text('تحققت من بريدي'));
    await tester.pumpAndSettle();
    expect(find.text('البريد مؤكد'), findsOneWidget);
    expect(find.text('إرسال رابط تأكيد البريد'), findsNothing);
  });

  testWidgets(
    'Password reset validates email and recovers from connection failure',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSignIn(
            onGuest: () {},
            signIn: (_, _) async {},
            register: (_, _) async {},
            resetPassword: (email) async {
              expect(email, 'test@example.com');
              if (++calls == 1) {
                throw FirebaseAuthException(code: 'network-request-failed');
              }
              throw FirebaseAuthException(code: 'user-not-found');
            },
          ),
        ),
      );
      await tester.ensureVisible(find.text('نسيت كلمة المرور؟'));
      await tester.tap(find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('اكتب بريدك الإلكتروني أولًا.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.ensureVisible(find.text('نسيت كلمة المرور؟'));
      await tester.tap(find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      expect(find.text(accountError('network-request-failed')), findsOneWidget);
      await tester.ensureVisible(find.text('نسيت كلمة المرور؟'));
      await tester.tap(find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text(
          'إذا كان البريد مرتبطًا بحساب، ستصلك رسالة لاستعادة كلمة المرور.',
        ),
        findsOneWidget,
      );
    },
  );
  test(
    'Account stores restore data, isolate users and reject stale writes',
    () async {
      final db = MemoryDocuments();
      final first = CloudFavoritesStore(db, 'alice');
      await expectLater(first.save({'oil-filter'}), throwsStateError);
      expect(await first.load(), isEmpty);
      final stale = CloudFavoritesStore(db, 'alice');
      await stale.load();
      await first.save({'oil-filter'});
      await expectLater(stale.save({'battery'}), throwsStateError);
      expect(await CloudFavoritesStore(db, 'alice').load(), {'oil-filter'});
      expect(await CloudFavoritesStore(db, 'bob').load(), isEmpty);
      final garage = CloudGarageStore(db, 'alice');
      await garage.load();
      await garage.save(
        GarageData(
          car: const SavedCar('تويوتا', 'كامري', 2021, '6 سلندر'),
          items: {'oil-filter': 2},
        ),
      );
      expect((await CloudGarageStore(db, 'alice').load()).items, {
        'oil-filter': 2,
      });
      expect((await CloudGarageStore(db, 'bob').load()).car, isNull);
      db.offline = true;
      await expectLater(first.save({'battery'}), throwsStateError);
      await expectLater(first.load(), throwsStateError);
      db.offline = false;
      await expectLater(first.save({'battery'}), throwsStateError);
      expect(await first.load(), {'oil-filter'});
    },
  );

  testWidgets(
    'Registration validates confirmation and blocks duplicate submissions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AccountSignIn(
              onGuest: () {},
              signIn: (_, _) async {},
              resetPassword: (_) async {},
              register: (email, password) {
                calls++;
                expect(email, 'test@example.com');
                return pending.future;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('ما عندك حساب؟ أنشئ حسابًا'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await tester.ensureVisible(find.text('إنشاء الحساب'));
      await tester.tap(find.text('إنشاء الحساب'));
      await tester.pump();
      expect(calls, 0);
      expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), 'test-password');
      await tester.ensureVisible(find.text('إنشاء الحساب'));
      await tester.tap(find.text('إنشاء الحساب'));
      await tester.pump();
      expect(calls, 1);
      expect(
        tester
            .widget<CupertinoButton>(
              find.widgetWithText(CupertinoButton, 'جارٍ التنفيذ…'),
            )
            .onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
