import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'ios_style.dart';
import 'catalog_repository.dart';
import 'catalog_cache.dart';

import 'account_sign_in.dart';
import 'cloud_stores.dart';
import 'firebase_options.dart';
import 'main.dart' show WaznahHome;

class AccountGate extends StatefulWidget {
  const AccountGate({super.key});
  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  late Future<void> _ready;
  Stream<User?>? _users;
  bool _guest = false;
  @override
  void initState() {
    super.initState();
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Cloud accounts are configured for Android only');
    }
    await Firebase.initializeApp(options: androidFirebaseOptions);
    // Avoid leaving another account's data in a persistent device cache.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    _users = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(child: CupertinoActivityIndicator()),
        );
      }
      if (snapshot.hasError) {
        if (_guest) {
          return WaznahHome(onAccount: () => setState(() => _guest = false));
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تعذّر تجهيز الحسابات. الربط الحالي متاح لنسخة أندرويد فقط.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _ready = _initialize()),
                    child: const Text('إعادة المحاولة'),
                  ),
                  CupertinoButton(
                    onPressed: () => setState(() => _guest = true),
                    child: const Text('تصفح كضيف'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return StreamBuilder<User?>(
        stream: _users,
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;
          if (user == null && !_guest) {
            return AccountSignIn(
              onGuest: () => setState(() => _guest = true),
              signIn: (email, password) async {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
              },
              register: (email, password) async {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
              },
              resetPassword: (email) =>
                  FirebaseAuth.instance.sendPasswordResetEmail(email: email),
            );
          }
          // A separate navigator per identity also discards open detail/garage routes
          // when signing out, so a previous user's data is never left on screen.
          return Navigator(
            key: ValueKey(user?.uid ?? 'guest'),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) {
                if (user == null) {
                  return WaznahHome(
                    onAccount: () => setState(() => _guest = false),
                  );
                }
                return CloudAccountHome(
                  user: user,
                  onSignOut: () async {
                    _guest = false;
                    await FirebaseAuth.instance.signOut();
                  },
                );
              },
            ),
          );
        },
      );
    },
  );
}

class CloudAccountHome extends StatefulWidget {
  const CloudAccountHome({
    super.key,
    required this.user,
    required this.onSignOut,
  });
  final User user;
  final Future<void> Function() onSignOut;
  @override
  State<CloudAccountHome> createState() => _CloudAccountHomeState();
}

class _CloudAccountHomeState extends State<CloudAccountHome> {
  late final catalogCache = CatalogCache(widget.user.uid);
  late final catalog = CatalogController(
    readPublishedCatalog,
    loadCache: catalogCache.load,
    saveCache: catalogCache.save,
  );
  @override
  void initState() {
    super.initState();
    catalog.refresh();
  }

  @override
  void dispose() {
    catalog.dispose();
    super.dispose();
  }

  late final documents = FirebaseAccountDocuments(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
  late final favorites = CloudFavoritesStore(documents, widget.user.uid);
  late final garage = CloudGarageStore(documents, widget.user.uid);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: catalog,
    builder: (context, _) => WaznahHome(
      catalog: catalog.data,
      onRefreshCatalog: catalog.refresh,
      catalogBusy: catalog.busy,
      catalogFailed: catalog.failed,
      catalogNotPublished: catalog.notPublished,
      favoritesStore: favorites,
      garageStore: garage,
      cloudAccount: true,
      onAccount: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AccountDetails(
          user: widget.user,
          onSignOut: widget.onSignOut,
          refreshVerification: () async {
            await widget.user.reload();
            return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
          },
        ),
      ),
    ),
  );
}

class AccountDetails extends StatefulWidget {
  const AccountDetails({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.refreshVerification,
  });
  final User user;
  final Future<void> Function() onSignOut;
  final Future<bool> Function() refreshVerification;
  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails> {
  late bool _verified = widget.user.emailVerified;
  bool _busy = false;
  String? _message;
  Future<void> _perform(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = message);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = accountError(error.code));
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذّرت العملية، حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const IosSheetHeader(title: 'حسابي'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    size: 56,
                    color: waznahPrimary,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    widget.user.email ?? '',
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verified ? 'البريد مؤكد' : 'البريد غير مؤكد',
                    style: const TextStyle(color: Color(0xFFB0BDCD)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'بياناتك محفوظة في حسابك. يلزم اتصال للحفظ؛ استخدم زر تحديث بيانات الحساب لجلب تعديلات جهاز آخر.',
          ),
          if (_message != null) Text(_message!),
          if (!_verified)
            CupertinoButton(
              onPressed: _busy
                  ? null
                  : () => _perform(
                      widget.user.sendEmailVerification,
                      'أرسلنا رابط تأكيد البريد. افتح بريدك لإكمال التأكيد.',
                    ),
              child: const Text('إرسال رابط تأكيد البريد'),
            ),
          if (!_verified)
            CupertinoButton(
              onPressed: _busy
                  ? null
                  : () => _perform(
                      () async {
                        final verified = await widget.refreshVerification();
                        if (mounted) setState(() => _verified = verified);
                      },
                      'تم تحديث حالة البريد. إذا بقي غير مؤكد، افتح رابط التأكيد ثم حاول مجددًا.',
                    ),
              child: const Text('تحققت من بريدي'),
            ),
          CupertinoButton(
            onPressed: _busy ? null : () => _perform(widget.onSignOut, ''),
            child: Text(
              _busy ? 'جارٍ التنفيذ…' : 'تسجيل الخروج',
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
    ),
  );
}
