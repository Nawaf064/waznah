import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'catalog_data.dart';
import 'favorites_storage_stub.dart'
    if (dart.library.io) 'favorites_storage_io.dart'
    if (dart.library.js_interop) 'favorites_storage_web.dart'
    as storage;

class SavedCar {
  const SavedCar(this.brand, this.model, this.year, this.engine);
  final String brand, model, engine;
  final int year;
  String get label => '$brand $model • ${arabicNumber(year)} • $engine';
  Map<String, Object> toJson() => {
    'brand': brand,
    'model': model,
    'year': year,
    'engine': engine,
  };
  factory SavedCar.fromJson(Map<String, dynamic> json) {
    final car = SavedCar(
      json['brand'] as String,
      json['model'] as String,
      json['year'] as int,
      json['engine'] as String,
    );
    if ([car.brand, car.model, car.engine].any((s) => s.trim().isEmpty) ||
        car.year < 1900 ||
        car.year > 2100) {
      throw const FormatException('Invalid car');
    }
    return car;
  }
  bool matches(SparePart part) {
    final fit = part.fitment;
    if (fit == null) return false;
    return normalizeSearch(brand) == normalizeSearch(part.brand) &&
        normalizeSearch(model) == normalizeSearch(fit.model) &&
        year >= fit.fromYear &&
        year <= fit.toYear &&
        (fit.engine == 'غير محدد في المصدر' ||
            normalizeSearch(engine) == normalizeSearch(fit.engine));
  }
}

class GarageData {
  GarageData({this.car, Map<String, int> items = const {}})
    : items = Map.unmodifiable(items);
  final SavedCar? car;
  final Map<String, int> items;
  String encode() =>
      jsonEncode({'version': 1, 'car': car?.toJson(), 'items': items});
  factory GarageData.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported garage version');
    }
    final items = Map<String, int>.from(json['items'] as Map);
    if (items.values.any((q) => q < 1 || q > 99)) {
      throw const FormatException('Invalid quantity');
    }
    return GarageData(
      car: json['car'] == null
          ? null
          : SavedCar.fromJson(Map<String, dynamic>.from(json['car'] as Map)),
      items: items,
    );
  }
  int get knownTotalHalalas => totalFor(catalogParts);
  int totalFor(List<SparePart> parts) {
    var total = 0;
    for (final part in parts) {
      final price = part.lowestPrice;
      if (price != null) total += (price * 100).round() * (items[part.id] ?? 0);
    }
    return total;
  }

  int get unpricedCount => unpricedFor(catalogParts);
  int unpricedFor(List<SparePart> parts) => items.entries
      .where(
        (entry) =>
            !parts.any((p) => p.id == entry.key && p.lowestPrice != null),
      )
      .fold(0, (sum, e) => sum + e.value);
}

abstract class GarageStore {
  Future<GarageData> load();
  Future<void> save(GarageData data);
}

class LocalGarageStore implements GarageStore {
  const LocalGarageStore();
  @override
  Future<GarageData> load() async {
    final raw = await storage.readFavorites(name: 'waznah_garage');
    return raw == null ? GarageData() : GarageData.decode(raw);
  }

  @override
  Future<void> save(GarageData data) =>
      storage.writeFavorites(data.encode(), name: 'waznah_garage');
}

class GarageController extends ChangeNotifier {
  GarageController(this.store);
  final GarageStore store;
  GarageData data = GarageData();
  bool ready = false, busy = false;
  String? error;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    ready = false;
    error = null;
    _notify();
    try {
      data = await store.load();
      ready = true;
    } catch (_) {
      error = 'تعذّر تحميل سيارتك وقائمة الصيانة. أعد المحاولة.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> _save(GarageData next) async {
    if (!ready || busy) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await store.save(next);
      data = next;
      return true;
    } catch (_) {
      error = 'تعذّر تأكيد حفظ التغيير. تأكد من الاتصال وأعد تحميل البيانات قبل المحاولة.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> saveCar(SavedCar? car) =>
      _save(GarageData(car: car, items: data.items));
  Future<bool> setQuantity(String id, int quantity) {
    if (quantity < 0 || quantity > 99) return Future.value(false);
    final next = {...data.items};
    if (quantity == 0) {
      next.remove(id);
    } else {
      next[id] = quantity;
    }
    return _save(GarageData(car: data.car, items: next));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
