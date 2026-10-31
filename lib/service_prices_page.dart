import 'currency_text.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ios_style.dart';

import 'catalog_data.dart';
import 'external_link.dart';

import 'service_data.dart';
export 'service_data.dart';

class ServicePricesPage extends StatefulWidget {
  const ServicePricesPage({
    super.key,
    this.embedded = false,
    this.services = serviceListings,
    this.workshops = westRiyadhWorkshops,
  });
  final List<ServiceListing> services;
  final List<Workshop> workshops;
  final bool embedded;
  @override
  State<ServicePricesPage> createState() => _ServicePricesPageState();
}

class _ServicePricesPageState extends State<ServicePricesPage> {
  final _search = TextEditingController();
  bool _pricedOnly = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.services
        .where(
          (s) =>
              (!_pricedOnly || s.price != null) &&
              matchesSearch(s.name, _search.text),
        )
        .toList();
    return Scaffold(
      appBar: widget.embedded
          ? null
          : const IosNavigationBar(title: 'الخدمات وشغل اليد'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const IosPageHeading(
                title: 'شغل اليد',
                subtitle: 'اعرف وش يشمل السعر',
              ),
              const SizedBox(height: 8),
              const IosInfoNote(
                'أسعار بداية منشورة وليست تسعيرة لسيارتك. أسعار بروف تخص مزودها في الرياض والخرج؛ لم نتحقق من فرع له في غرب الرياض. أسعار ورش غرب الرياض تُطلب مباشرة.',
              ),
              const SizedBox(height: 8),
              const Text(
                'آخر مراجعة للمصادر: ١٦ أكتوبر ٢٠٢٦. أكد السعر والتوفر قبل الزيارة.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'ابحث عن خدمة',
                  fillColor: const Color(0xFF121E2C),
                  prefixIcon: const Icon(CupertinoIcons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          icon: const Icon(CupertinoIcons.xmark_circle_fill),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('الأسعار المنشورة فقط'),
                value: _pricedOnly,
                onChanged: (v) => setState(() => _pricedOnly = v),
              ),
              if (results.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('ما لقينا خدمة تطابق بحثك.'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _search.clear();
                    _pricedOnly = false;
                  }),
                  child: const Text('عرض كل الخدمات'),
                ),
              ],
              for (final service in results)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        EnglishCaption(service.name),
                        const SizedBox(height: 8),
                        CurrencyText(
                          service.price == null
                              ? 'اطلب تسعيرة'
                              : service.maxPrice != null
                              ? 'من ${money(service.price)} إلى ${money(service.maxPrice)} — أسعار بداية'
                              : 'يبدأ من ${money(service.price)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (service.source != null)
                          Text('المصدر: ${service.provider}'),
                        if (service.source == null)
                          const Text(
                            'لا توجد تسعيرة موثّقة مضافة لهذه الخدمة بعد.',
                          ),
                        const SizedBox(height: 8),
                        CurrencyText(
                          service.notes,
                          style: const TextStyle(
                            height: 1.6,
                            color: Color(0xFFB0BDCD),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (service.source != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              IosActionButton(
                                onPressed: () => openExternal(
                                  context,
                                  Uri.parse(service.source!),
                                ),
                                icon: const Icon(
                                  CupertinoIcons.arrow_up_right_square,
                                ),
                                label: const Text('مصدر السعر وشروطه'),
                              ),
                              if (service.phone != null)
                                IosActionButton(
                                  onPressed: () => openExternal(
                                    context,
                                    Uri(scheme: 'tel', path: service.phone),
                                  ),
                                  icon: const Icon(CupertinoIcons.phone),
                                  label: const Text('اتصل لتأكيد السعر'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'استفسر من ورش غرب الرياض',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'تأكد أولًا من توفر الخدمة لسيارتك، واطلب فصل أجرة العمل والقطع والضريبة. لا توجد أسعار منشورة مضافة لهاتين الورشتين.',
              ),
              for (final workshop in widget.workshops)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workshop.name),
                        Text(workshop.district),
                        Wrap(
                          spacing: 8,
                          children: [
                            IosActionButton(
                              onPressed: () => openExternal(
                                context,
                                Uri(scheme: 'tel', path: workshop.phone),
                              ),
                              icon: const Icon(CupertinoIcons.phone),
                              label: const Text('استفسر عن الخدمة'),
                            ),
                            IosActionButton(
                              onPressed: () =>
                                  openExternal(context, workshop.mapsUri),
                              icon: const Icon(CupertinoIcons.location),
                              label: const Text('الموقع'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
