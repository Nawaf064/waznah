import 'catalog_data.dart';
import 'service_data.dart';

/// One published revision: products, seller offers and labor remain separate.
class CatalogSnapshot {
  CatalogSnapshot({
    required this.revision,
    required this.reviewedAt,
    required List<SparePart> parts,
    required List<Workshop> workshops,
    required List<ServiceListing> services,
  }) : parts = List.unmodifiable(parts),
       workshops = List.unmodifiable(workshops),
       services = List.unmodifiable(services);
  final int revision;
  final String reviewedAt;
  final List<SparePart> parts;
  final List<Workshop> workshops;
  final List<ServiceListing> services;
  static final bundled = CatalogSnapshot(
    revision: 0,
    reviewedAt: '2026-10-17',
    parts: catalogParts,
    workshops: westRiyadhWorkshops,
    services: serviceListings,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'revision': revision,
    'reviewedAt': reviewedAt,
    'partIds': parts.map((p) => p.id).toList(),
    'parts': [
      for (final p in parts)
        {
          'id': p.id,
          'name': p.name,
          'category': p.category,
          'brand': p.brand,
          'vehicle': p.vehicle,
          'partNumber': p.partNumber,
          'description': p.description,
          'fitment': p.fitment == null
              ? null
              : {
                  'model': p.fitment!.model,
                  'fromYear': p.fitment!.fromYear,
                  'toYear': p.fitment!.toYear,
                  'engine': p.fitment!.engine,
                },
        },
    ],
    'offers': [
      for (final p in parts)
        for (final o in p.offers)
          {
            'partId': p.id,
            'seller': o.seller,
            'priceHalalas': o.price == null ? null : (o.price! * 100).round(),
            'sourceUrl': o.sourceUrl,
            'notes': o.notes,
            'available': o.available,
          },
    ],
    'workshops': [
      for (final w in workshops)
        {
          'id': w.id,
          'name': w.name,
          'district': w.district,
          'address': w.address,
          'specialty': w.specialty,
          'phone': w.phone,
          'sourceUrl': w.sourceUrl,
          'locationSourceUrl': w.locationSourceUrl,
          'mapsQuery': w.mapsQuery,
          'mapsPlaceId': w.mapsPlaceId,
          'services': w.services,
        },
    ],
    'services': [
      for (final s in services)
        {
          'name': s.name,
          'notes': s.notes,
          'provider': s.provider,
          'phone': s.phone,
          'source': s.source,
          'priceHalalas': s.price == null ? null : (s.price! * 100).round(),
          'maxPriceHalalas': s.maxPrice == null
              ? null
              : (s.maxPrice! * 100).round(),
          'priceKind': s.price == null
              ? 'quote'
              : s.maxPrice == null
              ? 'starting_at'
              : 'starting_range',
        },
    ],
  };

  factory CatalogSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['revision'] is! int ||
        json['revision'] < 1) {
      throw const FormatException('Invalid catalog revision');
    }
    final reviewed = _text(json, 'reviewedAt');
    final date = DateTime.tryParse(reviewed);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(reviewed) ||
        date == null ||
        date.toIso8601String().substring(0, 10) != reviewed) {
      throw const FormatException('Invalid review date');
    }
    final rawParts = _rows(json, 'parts');
    final ids = <String>{};
    for (final p in rawParts) {
      if (!ids.add(_id(p))) throw const FormatException('Duplicate part');
    }
    final index = json['partIds'];
    if (index is! List ||
        index.length != ids.length ||
        index.toSet().length != ids.length ||
        !index.every(ids.contains)) {
      throw const FormatException('Part index does not match catalog');
    }
    final offers = <String, List<PriceOffer>>{};
    for (final o in _rows(json, 'offers')) {
      final id = _text(o, 'partId');
      if (!ids.contains(id) ||
          (o['available'] != null && o['available'] is! bool)) {
        throw const FormatException('Invalid offer reference or availability');
      }
      (offers[id] ??= []).add(
        PriceOffer(
          seller: _text(o, 'seller'),
          price: _price(o, 'priceHalalas'),
          sourceUrl: _url(o, 'sourceUrl'),
          notes: _text(o, 'notes'),
          available: o['available'] as bool?,
        ),
      );
    }
    final parts = [
      for (final p in rawParts)
        SparePart(
          id: _id(p),
          name: _text(p, 'name'),
          category: _text(p, 'category'),
          brand: _text(p, 'brand'),
          vehicle: _text(p, 'vehicle'),
          partNumber: _text(p, 'partNumber'),
          description: _text(p, 'description'),
          fitment: _fitment(p['fitment']),
          offers: List<PriceOffer>.unmodifiable(offers[_id(p)] ?? []),
        ),
    ];
    final workshopIds = <String>{};
    final workshops = <Workshop>[];
    for (final w in _rows(json, 'workshops')) {
      if (!workshopIds.add(_id(w))) {
        throw const FormatException('Duplicate workshop');
      }
      final services = w['services'];
      if (services is! List ||
          services.any((s) => s is! String || s.trim().isEmpty)) {
        throw const FormatException('Invalid workshop services');
      }
      workshops.add(
        Workshop(
          id: _id(w),
          name: _text(w, 'name'),
          district: _text(w, 'district'),
          address: _text(w, 'address'),
          specialty: _text(w, 'specialty'),
          phone: _text(w, 'phone'),
          sourceUrl: _url(w, 'sourceUrl'),
          locationSourceUrl: _url(w, 'locationSourceUrl'),
          mapsQuery: _text(w, 'mapsQuery'),
          mapsPlaceId: _optionalText(w, 'mapsPlaceId'),
          services: List<String>.unmodifiable(services.cast<String>()),
        ),
      );
    }
    final services = <ServiceListing>[];
    for (final s in _rows(json, 'services')) {
      final price = _price(s, 'priceHalalas'),
          max = _price(s, 'maxPriceHalalas');
      final kind = price == null
          ? 'quote'
          : max == null
          ? 'starting_at'
          : 'starting_range';
      if (s['priceKind'] != kind ||
          (max != null && (price == null || max < price))) {
        throw const FormatException('Invalid service range');
      }
      final source = s['source'] == null ? null : _url(s, 'source');
      if (price != null && source == null) {
        throw const FormatException('Price needs source');
      }
      services.add(
        ServiceListing(
          _text(s, 'name'),
          _text(s, 'notes'),
          price: price,
          maxPrice: max,
          provider: _text(s, 'provider'),
          phone: _optionalText(s, 'phone'),
          source: source,
        ),
      );
    }
    return CatalogSnapshot(
      revision: json['revision'] as int,
      reviewedAt: reviewed,
      parts: parts,
      workshops: workshops,
      services: services,
    );
  }
}

List<Map<String, dynamic>> _rows(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.length > 1000) {
    throw FormatException('Invalid $key');
  }
  return value.map((v) => Map<String, dynamic>.from(v as Map)).toList();
}

String _text(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! String || v.trim().isEmpty || v.length > 4000) {
    throw FormatException('Invalid $key');
  }
  return v;
}

String? _optionalText(Map<String, dynamic> m, String key) =>
    m[key] == null ? null : _text(m, key);
String _id(Map<String, dynamic> m) {
  final v = _text(m, 'id');
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,79}$').hasMatch(v)) {
    throw const FormatException('Invalid ID');
  }
  return v;
}

String _url(Map<String, dynamic> m, String key) {
  final v = _text(m, key), uri = Uri.tryParse(_text(m, key));
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw FormatException('Invalid URL: $key');
  }
  return v;
}

num? _price(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v == null) return null;
  if (v is! int || v < 0 || v > 100000000) {
    throw FormatException('Invalid $key');
  }
  return v / 100;
}

VehicleFitment? _fitment(dynamic value) {
  if (value == null) return null;
  final m = Map<String, dynamic>.from(value as Map);
  final from = m['fromYear'], to = m['toYear'];
  if (from is! int || to is! int || from < 1900 || to > 2100 || from > to) {
    throw const FormatException('Invalid model years');
  }
  return VehicleFitment(_text(m, 'model'), from, to, _text(m, 'engine'));
}
