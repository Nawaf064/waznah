import 'bilingual_labels.dart';

// بيانات منشورة. راجع sources.md لمعرفة حدود التحقق.
const sourceReviewDate = '2026-09-15';
const sourceReviewLabel = '١٥ سبتمبر ٢٠٢٦';

class PriceOffer {
  const PriceOffer({
    required this.seller,
    required this.price,
    required this.sourceUrl,
    required this.notes,
    this.available,
  });
  final String seller;
  final num? price;
  final String sourceUrl;
  final String notes;
  final bool? available;
}

class VehicleFitment {
  const VehicleFitment(this.model, this.fromYear, this.toYear, this.engine);
  final String model;
  final int fromYear;
  final int toYear;
  final String engine;
}

class SparePart {
  const SparePart({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.vehicle,
    required this.partNumber,
    required this.description,
    required this.offers,
    this.fitment,
  });
  final String id;
  final String name;
  final String category;
  final String brand;
  final String vehicle;
  final String partNumber;
  final String description;
  final List<PriceOffer> offers;
  final VehicleFitment? fitment;
  num? get lowestPrice {
    final prices = offers
        .where((offer) => offer.available != false)
        .map((offer) => offer.price)
        .whereType<num>();
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }
}

class Workshop {
  const Workshop({
    required this.id,
    required this.name,
    required this.district,
    required this.address,
    required this.specialty,
    required this.phone,
    required this.sourceUrl,
    required this.locationSourceUrl,
    required this.mapsQuery,
    this.mapsPlaceId,
    required this.services,
  });
  final String id;
  final String name;
  final String district;
  final String address;
  final String specialty;
  final String phone;
  final String sourceUrl;
  final String locationSourceUrl;
  final String mapsQuery;
  final String? mapsPlaceId;
  Uri get mapsUri => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': mapsQuery,
    'query_place_id': ?mapsPlaceId,
  });
  final List<String> services;
  String get city => 'الرياض';
}

const additionalParts = <SparePart>[
  SparePart(
    id: 'corolla-oil-filter',
    name: 'فلتر زيت كورولا',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'كورولا 2011–2019',
    partNumber: '04152-YZZD6',
    fitment: VehicleFitment('كورولا', 2011, 2019, 'غير محدد في المصدر'),
    description: 'أصلي بحسب المتجر. التوافق من المتجر؛ طابق رقم الهيكل والمحرك قبل الشراء.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 32.29,
        sourceUrl: 'https://medrar.sa/ar/vXmADDl',
        available: true,
        notes: 'السعر المنشور شامل الضريبة. مراجعة المصدر ١٧ أكتوبر ٢٠٢٦؛ الشحن والتركيب منفصلان. السعر والتوفر قابلان للتغير.',
      ),
    ],
  ),
  SparePart(
    id: 'corolla-cross-oil-filter',
    name: 'فلتر زيت كورولا كروس',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'كورولا كروس 2020–2024',
    partNumber: '90915-100099',
    fitment: VehicleFitment('كورولا كروس', 2020, 2024, 'غير محدد في المصدر'),
    description: 'أصلي بحسب المتجر؛ رقم القطعة منقول كما نشره البائع. التوافق من المتجر؛ طابق رقم الهيكل والمحرك قبل الشراء.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 51.77,
        sourceUrl: 'https://medrar.sa/vXPYqXZ',
        available: true,
        notes: 'السعر المنشور شامل الضريبة. مراجعة المصدر ١٧ أكتوبر ٢٠٢٦؛ الشحن والتركيب منفصلان. السعر والتوفر قابلان للتغير.',
      ),
    ],
  ),
  SparePart(
    id: 'yaris-cabin-filter-denso',
    name: 'فلتر مكيف يارس دينسو',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'يارس 2014–2022',
    partNumber: '87139-06080D-2',
    fitment: VehicleFitment('يارس', 2014, 2022, 'غير محدد في المصدر'),
    description: 'دينسو بحسب عنوان المتجر، ومصنف تجاري. التوافق من المتجر؛ طابق رقم الهيكل والمحرك قبل الشراء.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 77.56,
        sourceUrl: 'https://medrar.sa/pAzlawX',
        available: true,
        notes: 'السعر المنشور شامل الضريبة. مراجعة المصدر ١٧ أكتوبر ٢٠٢٦؛ الشحن والتركيب منفصلان. السعر والتوفر قابلان للتغير.',
      ),
    ],
  ),
  SparePart(
    id: 'yaris-cabin-filter-japan',
    name: 'فلتر مكيف يارس ياباني',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'يارس 2023–2024',
    partNumber: '87139-BZ040J',
    fitment: VehicleFitment('يارس', 2023, 2024, 'غير محدد في المصدر'),
    description: 'ياباني بحسب العنوان ومصنف تجاري؛ لا نعتمد شارة الأصالة العامة المتعارضة مع التصنيف. التوافق من المتجر؛ طابق رقم الهيكل والمحرك قبل الشراء.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 77.56,
        sourceUrl: 'https://medrar.sa/ar/vXavxZv',
        available: true,
        notes: 'السعر المنشور شامل الضريبة. مراجعة المصدر ١٧ أكتوبر ٢٠٢٦؛ الشحن والتركيب منفصلان. السعر والتوفر قابلان للتغير.',
      ),
    ],
  ),
  SparePart(
    id: 'camry-air-filter',
    name: 'فلتر هواء كامري',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'كامري ٢٠٠٧–٢٠١٧',
    partNumber: '17801-28030',
    fitment: VehicleFitment('كامري', 2007, 2017, 'غير محدد في المصدر'),
    description: 'فلتر أصلي بحسب مدرار. الموديلات من عنوان المنتج؛ طابق رقم الهيكل والمحرك قبل الشراء.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 164.80,
        sourceUrl: 'https://medrar.sa/mQmZPzq',
        available: true,
        notes: 'شامل الضريبة. مراجعة ١٦ أكتوبر ٢٠٢٦؛ الشحن والتركيب منفصلان والسعر قابل للتغير.',
      ),
    ],
  ),
  SparePart(
    id: 'prado-cabin-filter',
    name: 'فلتر مكيف برادو',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'برادو ٢٠١٠–٢٠١٥',
    partNumber: '87139-30040-5',
    fitment: VehicleFitment('برادو', 2010, 2015, 'غير محدد في المصدر'),
    description: 'فلتر أصلي بحسب مدرار. رقم الموديل كما نشره المتجر؛ يلزم تأكيد التوافق برقم الهيكل.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 219.78,
        sourceUrl: 'https://medrar.sa/YzGNpRR',
        available: true,
        notes: 'شامل الضريبة. مراجعة ١٦ أكتوبر ٢٠٢٦؛ لا يشمل سعرنا الشحن أو التركيب.',
      ),
    ],
  ),
  SparePart(
    id: 'altima-spark-plug',
    name: 'بوجي ألتيما إيريديوم — حبة',
    category: 'كهرباء',
    brand: 'نيسان',
    vehicle: 'ألتيما ٢٠١٣–٢٠١٨ • ٢٫٥ لتر QR25DE',
    partNumber: '224013TA1B',
    fitment: VehicleFitment('ألتيما', 2013, 2018, '2.5 QR25DE'),
    description: 'بوجي أصلي بحسب الحل الأمثل. السعر للحبة؛ عدد البواجي وأجرة التركيب منفصلان. طابق الرقم والمحرك.',
    offers: [
      PriceOffer(
        seller: 'الحل الأمثل',
        price: 80,
        sourceUrl: 'https://alhal-almathil.com/ar-sa/products/بواجي-التيما',
        notes: 'سعر منشور في نتيجة البحث، مراجعة ١٦ أكتوبر ٢٠٢٦. تعذر فتح الصفحة مباشرة؛ أكد السعر والضريبة والتوفر لدى المتجر.',
      ),
    ],
  ),
];

const catalogParts = <SparePart>[
  SparePart(
    id: 'oil-filter',
    fitment: VehicleFitment('كامري', 2018, 2024, '٦ سلندر'),
    name: 'فلتر زيت',
    category: 'فلاتر',
    brand: 'تويوتا',
    vehicle: 'كامري ٦ سلندر ٢٠١٨–٢٠٢٤',
    partNumber: '04152-310903',
    description: 'فلتر أصلي بحسب مدرار، مخصص في صفحة المتجر لكامري ٦ سلندر. رقم المنتج منقول كما نشره المتجر؛ طابقه برقم الهيكل.',
    offers: [
      PriceOffer(
        seller: 'مدرار',
        price: 50.31,
        sourceUrl: 'https://medrar.sa/DGRYROV',
        notes: 'شامل الضريبة بحسب المتجر. الشحن والتركيب غير محتسبين هنا.',
        available: true,
      ),
    ],
  ),
  SparePart(
    id: 'brake-pads',
    fitment: VehicleFitment('إلنترا', 2021, 2025, 'غير محدد في المصدر'),
    name: 'فحمات فرامل أمامية',
    category: 'فرامل',
    brand: 'هيونداي',
    vehicle: 'إلنترا ٢٠٢١–٢٠٢٥',
    partNumber: '58101-AA000',
    description: 'طقم أمامي أصلي بحسب رعد أوتو. التوافق من وصف المتجر ويحتاج مطابقة رقم الهيكل.',
    offers: [
      PriceOffer(
        seller: 'رعد أوتو',
        price: 525,
        sourceUrl: 'https://raadauto.com/طقم-فحمات-أمامية-النترا-2021-2025-أصلي/p1884813683',
        notes: 'سعر منشور؛ شمول الضريبة والتوفر يحتاجان تأكيدًا من المتجر. لا يشمل هذا العرض أجرة تركيب.',
      ),
    ],
  ),
  SparePart(
    id: 'battery',
    name: 'بطارية INFINITY AGM ٧٠ أمبير',
    category: 'كهرباء',
    brand: 'حسب المقاس',
    vehicle: 'التوافق مع السيارة يحتاج تأكيدًا',
    partNumber: 'U I INF 000003',
    description: 'بطارية INFINITY بتقنية AGM، سعة ٧٠ أمبير بحسب MRKBATX. لم نثبت توافقها مع ألتيما أو أي موديل بعينه؛ طابق المقاس والأقطاب والمواصفات.',
    offers: [
      PriceOffer(
        seller: 'MRKBATX',
        price: 890,
        sourceUrl:
            'https://portal.mrkbatx.com/product/btry-70-mbyr-infinity-agm/',
        notes: 'شامل ضريبة القيمة المضافة بحسب المتجر. التوفر يختلف حسب الفرع.',
        available: true,
      ),
    ],
  ),
  SparePart(
    id: 'air-filter',
    fitment: VehicleFitment('سوناتا', 2020, 2023, 'غير محدد في المصدر'),
    name: 'فلتر هواء المحرك',
    category: 'فلاتر',
    brand: 'هيونداي',
    vehicle: 'سوناتا ٢٠٢٠–٢٠٢٣',
    partNumber: '28113-L1000',
    description: 'فلتر أصلي بحسب المتجرين، بنفس رقم القطعة. الموديلات هنا ضمن نطاق التوافق المشترك في وصفيهما؛ تحقق برقم الهيكل.',
    offers: [
      PriceOffer(
        seller: 'صناع النهضة',
        price: 85,
        sourceUrl: 'https://sunnaalnahda.com/ar/28113l1000-فلتر-هواء-سوناتا-2020-2025-اصلي/p182588137',
        notes: 'سعر مخفّض منشور شامل الضريبة. أكد التوفر والشحن لدى المتجر.',
      ),
      PriceOffer(
        seller: 'قناع الفرسان',
        price: 95,
        sourceUrl: 'https://qinaalfursan.com/products/فلتر-هواء-سوناتا-2020-2023-28113-L1000',
        notes: 'شامل الضريبة؛ كان غير متوفر بالمخزون في صفحة المصدر.',
        available: false,
      ),
    ],
  ),
  SparePart(
    id: 'spark-plugs',
    fitment: VehicleFitment('كورولا', 2020, 2025, 'غير محدد في المصدر'),
    name: 'طقم بواجي ٤ حبات',
    category: 'كهرباء',
    brand: 'تويوتا',
    vehicle: 'كورولا ٢٠٢٠–٢٠٢٥',
    partNumber: '90919-01297',
    description: 'السعر لطقم من ٤ حبات بحسب صفحة FNZ، وليس للحبة الواحدة. طابق رقم القطعة ونوع المحرك.',
    offers: [
      PriceOffer(
        seller: 'FNZ',
        price: 390,
        sourceUrl: 'https://fnz.sa/ar/طقم-بواجى-4-حبه-كورولا-2020-الى-2025-90919-01297/p1002580831',
        notes:
            'سعر منشور للطقم؛ شمول الضريبة والتوفر يحتاجان تأكيدًا من المتجر.',
      ),
    ],
  ),
  SparePart(
    id: 'shock-absorber',
    fitment: VehicleFitment('صني مكسيكي', 2020, 2022, '١٫٦ CVT'),
    name: 'مساعد أمامي يمين',
    category: 'تعليق',
    brand: 'نيسان',
    vehicle: 'صني مكسيكي ٢٠٢٠–٢٠٢٢ • ١٫٦ CVT',
    partNumber: 'E43025EF0D',
    description: 'مساعد جهة الراكب أصلي بحسب منصة تريو سبير. نطاق الموديلات مأخوذ من جدول التوافق. السعر محجوب مؤقتًا بسبب اختلاف قيمته بين نتائج المصدر.',
    offers: [
      PriceOffer(
        seller: 'تريو سبير',
        price: null,
        sourceUrl:
            'https://triospare.com/مساعد-امامي-يمين-نيسان-صني-e43025ef0d/',
        notes: 'ظهرت قيمتان ٧١٤ و٨٢١٫١٠ ريال في المصدر ونتيجته. لم يتضح سبب الفرق أو شمول الضريبة؛ راجع المنصة لتأكيد السعر والبائع.',
      ),
    ],
  ),
  ...additionalParts,
];

const westRiyadhWorkshops = <Workshop>[
  Workshop(
    id: 'asema-electronic',
    name: 'مركز العاصمة الإلكتروني',
    district: 'العوالي • صناعية العاصمة',
    address: 'الرياض، حي العوالي، صناعية العاصمة، طريق المدينة المنورة',
    specialty: 'ميكانيكا وكهرباء وفحص كمبيوتر وسمكرة',
    phone: '0500798224',
    sourceUrl: 'https://asemaelec.com/اتصل-بنا/',
    locationSourceUrl: 'https://maps.app.goo.gl/ZUR67L1nLheYD3tGA',
    mapsQuery: '24.5724073,46.6023295',
    services: [
      'صيانة ميكانيكا',
      'إصلاح كهرباء السيارات',
      'فحص كمبيوتر',
      'سمكرة وبوية',
    ],
  ),
  Workshop(
    id: 'abdulaziz-alsubaie',
    name: 'مركز عبدالعزيز السبيعي لتعديل وصيانة السيارات',
    district: 'طويق • صناعية السفارات',
    address: 'صناعية السفارات، طريق مكة المكرمة، طويق، الرياض 13791',
    specialty: 'تعديل وصيانة السيارات',
    phone: '0552848810',
    sourceUrl: 'https://linktr.ee/alsubaie',
    locationSourceUrl: 'https://goo.gl/maps/hE9AfPWTJZwLcMMg9',
    mapsQuery: 'مركز عبدالعزيز السبيعي لتعديل وصيانة السيارات طويق الرياض',
    mapsPlaceId: 'ChIJEZWN634jLz4RHfi5LSVY9Ew',
    services: ['تعديل السيارات', 'صيانة السيارات'],
  ),
];

String arabicNumber(Object value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .replaceAllMapped(
        RegExp(r'[0-9]'),
        (match) => digits[int.parse(match[0]!)],
      )
      .replaceAll('.', '٫');
}

String money(num? value) {
  if (value == null) return 'السعر يحتاج تأكيدًا';
  final amount = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return '${arabicNumber(amount)} ريال';
}

String normalizeSearch(String value) => value
    .trim()
    .toLowerCase()
    .replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString(),
    )
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0640]'), '');

bool matchesSearch(String text, String query) {
  text = [
    text,
    for (final entry in englishNames.entries)
      if (text.contains(entry.key)) entry.value,
  ].join(' ');
  final normalized = normalizeSearch(text);
  return normalizeSearch(query)
      .split(' ')
      .every((word) => normalized.contains(word));
}

List<SparePart> filterParts({
  List<SparePart> source = catalogParts,
  String query = '',
  String category = 'الكل',
  String brand = 'كل السيارات',
  bool highestFirst = false,
  String model = 'كل الموديلات',
  int? year,
  String engine = 'كل المحركات',
}) {
  final result = source
      .where(
        (part) =>
            (category == 'الكل' || part.category == category) &&
            (brand == 'كل السيارات' || part.brand == brand) &&
            (model == 'كل الموديلات' || part.fitment?.model == model) &&
            (year == null ||
                (part.fitment != null &&
                    year >= part.fitment!.fromYear &&
                    year <= part.fitment!.toYear)) &&
            (engine == 'كل المحركات' || part.fitment?.engine == engine) &&
            matchesSearch(
              [
                part.name,
                part.brand,
                part.vehicle,
                part.category,
                part.partNumber,
                if (part.fitment != null)
                  for (
                    var y = part.fitment!.fromYear;
                    y <= part.fitment!.toYear;
                    y++
                  )
                    '$y',
              ].join(' '),
              query,
            ),
      )
      .toList();
  result.sort((a, b) {
    final aPrice = a.lowestPrice;
    final bPrice = b.lowestPrice;
    if (aPrice == null) return bPrice == null ? 0 : 1;
    if (bPrice == null) return -1;
    return highestFirst ? bPrice.compareTo(aPrice) : aPrice.compareTo(bPrice);
  });
  return result;
}
