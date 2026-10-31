import 'dart:io';

import 'package:waznah/catalog_data.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  check(money(50.31) == '٥٠٫٣١ ريال', 'Preserve halalas');
  check(money(null) == 'السعر يحتاج تأكيدًا', 'Missing price is not zero');
  check(filterParts().last.lowestPrice == null, 'Missing prices sort last');
  check(
    filterParts(highestFirst: true).last.lowestPrice == null,
    'Missing prices sort last in both directions',
  );
  check(
    filterParts(query: '28113-L1000').single.id == 'air-filter',
    'Search by exact part number',
  );
  check(
    filterParts(query: 'فلتر', brand: 'تويوتا').map((p) => p.id).join(',') ==
        'oil-filter,camry-air-filter,prado-cabin-filter',
    'Combined brand and search',
  );
  check(
    filterParts(query: 'النترا').single.id == 'brake-pads',
    'Arabic normalization',
  );
  const fixture = SparePart(
    id: 'fixture',
    name: '',
    category: '',
    brand: '',
    vehicle: '',
    partNumber: '',
    description: '',
    offers: [
      PriceOffer(
        seller: '',
        price: 1,
        sourceUrl: '',
        notes: '',
        available: false,
      ),
      PriceOffer(seller: '', price: 10, sourceUrl: '', notes: ''),
    ],
  );
  check(fixture.lowestPrice == 10, 'Exclude sold-out offers from lead price');
  check(
    catalogParts.every(
      (p) => p.offers.every(
        (offer) => Uri.parse(offer.sourceUrl).scheme == 'https',
      ),
    ),
    'Sources for all prices',
  );
  check(
    westRiyadhWorkshops.every(
      (w) =>
          w.address.contains('صناعية') &&
          w.city == 'الرياض' &&
          Uri.parse(w.sourceUrl).scheme == 'https',
    ),
    'Workshop addresses and sources',
  );
  stdout.writeln('PASS: 10 catalog checks');
}
