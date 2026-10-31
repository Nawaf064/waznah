import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'favorites_store.dart';
import 'garage.dart';

abstract class AccountDocuments {
  Future<Map<String, dynamic>?> read(String uid, String name);
  Future<void> write(
    String uid,
    String name,
    int revision,
    Map<String, dynamic> data,
  );
}

class FirebaseAccountDocuments implements AccountDocuments {
  FirebaseAccountDocuments(this.database, this.auth);
  final FirebaseFirestore database;
  final FirebaseAuth auth;
  void _check(String uid) {
    if (auth.currentUser?.uid != uid) throw StateError('Account changed');
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid, String name) =>
      database.collection('users').doc(uid).collection('private').doc(name);
  @override
  Future<Map<String, dynamic>?> read(String uid, String name) async {
    _check(uid);
    final snapshot = await _doc(uid, name)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    _check(uid);
    return snapshot.data();
  }

  @override
  Future<void> write(
    String uid,
    String name,
    int revision,
    Map<String, dynamic> data,
  ) async {
    _check(uid);
    // Online transactions prevent delayed writes and stale-device overwrites.
    await database.runTransaction((transaction) async {
      _check(uid);
      final reference = _doc(uid, name);
      final snapshot = await transaction.get(reference);
      if ((snapshot.data()?['revision'] ?? 0) != revision) {
        throw StateError('Data changed on another device; refresh first');
      }
      transaction.set(reference, {...data, 'revision': revision + 1});
    }, timeout: const Duration(seconds: 15));
  }
}

class CloudFavoritesStore implements FavoritesStore {
  CloudFavoritesStore(this.documents, this.uid);
  final AccountDocuments documents;
  final String uid;
  int? _revision;
  @override
  Future<Set<String>> load() async {
    _revision = null;
    final data = await documents.read(uid, 'favorites');
    final ids = data?['ids'] ?? <String>[];
    final revision = data?['revision'] ?? 0;
    if (ids is! List || ids.any((id) => id is! String) || revision is! int) {
      throw const FormatException('Invalid favorites');
    }
    _revision = revision;
    return ids.cast<String>().toSet();
  }

  @override
  Future<void> save(Set<String> ids) async {
    final revision = _revision;
    if (revision == null) throw StateError('Load before saving');
    // A failed response may still follow a committed write. Reload before retry.
    _revision = null;
    await documents.write(uid, 'favorites', revision, {
      'ids': ids.toList()..sort(),
    });
    _revision = revision + 1;
  }
}

class CloudGarageStore implements GarageStore {
  CloudGarageStore(this.documents, this.uid);
  final AccountDocuments documents;
  final String uid;
  int? _revision;
  @override
  Future<GarageData> load() async {
    _revision = null;
    final data = await documents.read(uid, 'garage');
    final revision = data?['revision'] ?? 0;
    if (revision is! int) throw const FormatException('Invalid revision');
    final garage = data == null
        ? GarageData()
        : GarageData.decode(jsonEncode(data['payload']));
    _revision = revision;
    return garage;
  }

  @override
  Future<void> save(GarageData data) async {
    final revision = _revision;
    if (revision == null) throw StateError('Load before saving');
    _revision = null;
    await documents.write(uid, 'garage', revision, {
      'payload': jsonDecode(data.encode()),
    });
    _revision = revision + 1;
  }
}
