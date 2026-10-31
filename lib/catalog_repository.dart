import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'catalog_snapshot.dart';

class CatalogNotPublished implements Exception {
  const CatalogNotPublished();
}

Future<CatalogSnapshot> readPublishedCatalog() async {
  final doc = await FirebaseFirestore.instance
      .doc('catalog/published')
      .get(const GetOptions(source: Source.server))
      .timeout(const Duration(seconds: 15));
  if (!doc.exists) throw const CatalogNotPublished();
  return CatalogSnapshot.fromJson(doc.data()!);
}

class CatalogController extends ChangeNotifier {
  CatalogController(this.read, {this.loadCache, this.saveCache});
  final Future<CatalogSnapshot> Function() read;
  final Future<CatalogSnapshot?> Function()? loadCache;
  final Future<void> Function(CatalogSnapshot)? saveCache;
  bool _cacheLoaded = false;
  CatalogSnapshot data = CatalogSnapshot.bundled;
  bool busy = false, failed = false, _disposed = false;
  bool notPublished = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      if (!_cacheLoaded) {
        _cacheLoaded = true;
        try {
          final cached = await loadCache?.call();
          if (_disposed) return;
          if (cached != null && cached.revision > data.revision) {
            data = cached;
            _notify();
          }
        } catch (_) {
          // A damaged/unavailable local cache must not block a server refresh.
        }
      }
      if (_disposed) return;
      final next = await read();
      if (_disposed) return;
      if (next.revision < data.revision) throw StateError('Older catalog');
      data = next;
      failed = false;
      notPublished = false;
      try {
        await saveCache?.call(next);
      } catch (_) {
        // The verified server result remains usable even if local storage fails.
      }
    } on CatalogNotPublished {
      notPublished = true;
      failed = false;
    } catch (_) {
      // Keep the last complete revision; never partially replace prices.
      failed = true;
      notPublished = false;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
