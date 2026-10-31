import 'dart:convert';

import 'favorites_storage_stub.dart'
    if (dart.library.io) 'favorites_storage_io.dart'
    if (dart.library.js_interop) 'favorites_storage_web.dart'
    as storage;

abstract class FavoritesStore {
  Future<Set<String>> load();
  Future<void> save(Set<String> ids);
}

class LocalFavoritesStore implements FavoritesStore {
  const LocalFavoritesStore();
  @override
  Future<Set<String>> load() async {
    final raw = await storage.readFavorites();
    if (raw == null) return {};
    final data = jsonDecode(raw);
    if (data is! List || data.any((id) => id is! String)) {
      throw const FormatException('Invalid favorites data');
    }
    return data.cast<String>().toSet();
  }

  @override
  Future<void> save(Set<String> ids) =>
      storage.writeFavorites(jsonEncode(ids.toList()..sort()));
}
