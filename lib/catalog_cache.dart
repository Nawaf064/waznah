import 'dart:convert';

import 'catalog_snapshot.dart';
import 'favorites_storage_stub.dart'
    if (dart.library.io) 'favorites_storage_io.dart'
    if (dart.library.js_interop) 'favorites_storage_web.dart'
    as storage;

/// Only catalog data is cached here, never account or authentication data.
/// A separate key per identity prevents guests and other accounts using it.
class CatalogCache {
  CatalogCache(String uid)
    : name = 'waznah_catalog_${base64Url.encode(utf8.encode(uid))}';

  final String name;

  Future<CatalogSnapshot?> load() async {
    final raw = await storage.readFavorites(name: name);
    if (raw == null) return null;
    if (utf8.encode(raw).length > 750 * 1024) {
      throw const FormatException('Catalog cache too large');
    }
    return CatalogSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(CatalogSnapshot data) =>
      storage.writeFavorites(jsonEncode(data.toJson()), name: name);
}
