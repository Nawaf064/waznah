import 'package:flutter_test/flutter_test.dart';
import 'package:waznah/catalog_data.dart';
import 'package:waznah/bilingual_labels.dart';
import 'package:waznah/service_data.dart';

void main() {
  test('Bundled products and services have English display names', () {
    for (final part in catalogParts) {
      expect(englishName(part.name), isNotEmpty, reason: part.name);
    }
    for (final service in serviceListings) {
      expect(englishName(service.name), isNotEmpty, reason: service.name);
    }
  });
  test('English and Arabic searches find the same Corolla oil filter', () {
    final english = filterParts(query: 'Corolla Oil Filter')
        .map((p) => p.id)
        .toSet();
    final arabic = filterParts(query: 'كورولا فلتر زيت')
        .map((p) => p.id)
        .toSet();
    expect(english, arabic);
    expect(english, contains('corolla-oil-filter'));
  });
}
