class ServiceListing {
  const ServiceListing(
    this.name,
    this.notes, {
    this.price,
    this.maxPrice,
    this.source,
    this.provider = 'بروف لخدمات السيارات • الرياض والخرج',
    this.phone,
  });
  final String name;
  final String notes;
  final num? price;
  final num? maxPrice;
  final String provider;
  final String? phone;
  final String? source;
}

const serviceListings = [
  ServiceListing(
    'تغيير زيت المكينة والفلتر',
    'أجرة العمل فقط، بشرط شراء الزيت من بروف. لا تشمل الضريبة أو قيمة الزيت والفلتر. السعر النهائي حسب السيارة ونوع الزيت.',
    price: 10,
    phone: '0534271300',
    source: 'https://www.baa.sa/product/eo-change/',
  ),
  ServiceListing(
    'تبديل فحمات الفرامل',
    'عرض خدمة للجهة الواحدة؛ يضيف المصدر ٥٠ ريال للسيارات الأوروبية. لا يشمل خرط الهوبات. شمول قيمة الفحمات والضريبة ومعنى الجهة يحتاج تأكيدًا من المركز؛ لا نعتبره أجرة يد صافية.',
    price: 35,
    phone: '0534271300',
    source: 'https://www.baa.sa/product/brake_pads/',
  ),
  ServiceListing(
    'تغيير زيت القير',
    'اطلب تحديد أجرة العمل وقيمة الزيت والفلتر كلًا على حدة، وطريقة التغيير المناسبة لسيارتك.',
  ),
  ServiceListing(
    'تغيير البواجي',
    'نطاق أسعار البداية المنشورة لأجرة العمل فقط: الصغيرة ١٢٠، المتوسطة ١٥٠، ٦ سلندر ١٨٠، و٨ سلندر ٢٢٠ ريال. لا يمثل حدًا أعلى للفاتورة؛ قيمة البواجي منفصلة وشمول الضريبة يحتاج تأكيدًا. لا يُنسب السعر لورش غرب الرياض.',
    price: 120,
    maxPrice: 220,
    provider: 'موقع خدمات سيارات الرياض • carservicesriyadh.com',
    source: 'https://carservicesriyadh.com/تغيير-بواجي/',
  ),
  ServiceListing(
    'تركيب المساعدات',
    'حدّد أمامي أو خلفي، جهة واحدة أو زوجًا، وهل تشمل الأجرة أي أعمال إضافية.',
  ),
  ServiceListing(
    'فحص كمبيوتر',
    'حدّد هل المطلوب قراءة الأكواد فقط أو تشخيص سبب العطل، وهل رسوم الإصلاح منفصلة.',
  ),
];
