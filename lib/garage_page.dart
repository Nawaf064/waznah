import 'currency_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'catalog_data.dart';
import 'garage.dart';
import 'ios_style.dart';

class GaragePage extends StatelessWidget {
  const GaragePage({
    super.key,
    required this.controller,
    required this.onCarSaved,
    required this.onBrowse,
    this.cloudAccount = false,
    this.parts = catalogParts,
  });
  final List<SparePart> parts;
  final bool cloudAccount;
  final GarageController controller;
  final VoidCallback onCarSaved, onBrowse;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const IosNavigationBar(title: 'سيارتي والصيانة'),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final data = controller.data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const IosPageHeading(
              title: 'سيارتي',
              subtitle: 'سيارتك وقطع الصيانة في مكان واحد',
            ),
            const SizedBox(height: 16),
            IosInfoNote(
              cloudAccount
                  ? 'محفوظة في حسابك. يلزم اتصال بالإنترنت للحفظ. حدّث البيانات عند تعديلها من جهاز آخر.'
                  : 'بيانات الضيف محفوظة على هذا الجهاز فقط، ولا تُنقل تلقائيًا إلى الحساب.',
            ),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.error != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (!controller.busy)
                TextButton(
                  onPressed: controller.busy ? null : controller.load,
                  child: const Text('إعادة تحميل البيانات'),
                ),
            ],
            if (controller.ready) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        CupertinoIcons.car_detailed,
                        size: 42,
                        color: waznahPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'سيارتي',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(data.car?.label ?? 'أضف سيارتك لتصفية القطع عليها.'),
                      Wrap(
                        spacing: 8,
                        children: [
                          IosActionButton.filled(
                            onPressed: controller.busy
                                ? null
                                : () async {
                                    final saved =
                                        await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          isDismissible: false,
                                          enableDrag: false,
                                          showDragHandle: true,
                                          constraints: const BoxConstraints(
                                            maxWidth: 600,
                                          ),
                                          builder: (_) =>
                                              CarEditor(controller: controller),
                                        );
                                    if (saved == true) onCarSaved();
                                  },
                            icon: const Icon(CupertinoIcons.pencil),
                            label: Text(
                              data.car == null
                                  ? 'إضافة سيارتي'
                                  : 'تعديل السيارة',
                            ),
                          ),
                          if (data.car != null)
                            TextButton(
                              onPressed: controller.busy
                                  ? null
                                  : () async {
                                      if (await controller.saveCar(null)) {
                                        onCarSaved();
                                      }
                                    },
                              child: const Text('إزالة السيارة'),
                            ),
                        ],
                      ),
                      const Text(
                        'التصفية تعتمد على وصف المتاجر؛ بيانات المحرك الناقصة تحتاج تأكيدًا برقم الهيكل. تغيير السيارة لا يغيّر قائمة الصيانة.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'قائمة الصيانة',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const IosInfoNote(
                'الكمية بعدد العروض: طقم البواجي أو الفحمات يُحسب طقمًا، وليس عدد الحبات. الأسعار لا تشمل الشحن أو أجرة التركيب؛ راجع ملاحظة الضريبة في تفاصيل القطعة.',
              ),
              const SizedBox(height: 12),
              if (data.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('قائمتك فاضية. أضف القطع من تفاصيل السعر.'),
                ),
              for (final entry in data.items.entries) _item(context, entry),
              if (data.items.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مجموع الأسعار المعروفة'),
                        CurrencyText(
                          money(data.totalFor(parts) / 100),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: waznahPrimary,
                          ),
                        ),
                        if (data.unpricedFor(parts) > 0)
                          Text(
                            '${arabicNumber(data.unpricedFor(parts))} من العروض بدون سعر مؤكد، غير محتسبة في المجموع.',
                          ),
                        const Text(
                          'تقدير من الأسعار المنشورة، وليس عرض سعر نهائيًا.',
                        ),
                      ],
                    ),
                  ),
                ),
              IosActionButton(
                onPressed: () {
                  Navigator.pop(context);
                  onBrowse();
                },
                icon: const Icon(CupertinoIcons.search),
                label: const Text('إضافة قطع من الكتالوج'),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _item(BuildContext context, MapEntry<String, int> entry) {
    final matches = parts.where((p) => p.id == entry.key);
    final part = matches.isEmpty ? null : matches.first;
    final enabled = !controller.busy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              part?.name ?? 'قطعة لم تعد متاحة في الكتالوج',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (part != null) EnglishCaption(part.name),
            if (part != null) Text('${part.brand} • ${part.vehicle}'),
            if (part != null &&
                controller.data.car != null &&
                !controller.data.car!.matches(part))
              const Text(
                'هذه القطعة خارج نتائج سيارتك الحالية؛ تأكد من التوافق.',
              ),
            if (part?.fitment?.engine == 'غير محدد في المصدر')
              const Text('توافق المحرك غير مؤكد في المصدر.'),
            CurrencyText(
              part?.lowestPrice == null
                  ? 'السعر يحتاج تأكيدًا'
                  : '${money(part!.lowestPrice)} × ${arabicNumber(entry.value)}',
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'تقليل كمية ${part?.name ?? 'القطعة'}',
                  onPressed: enabled && entry.value > 1
                      ? () => controller.setQuantity(entry.key, entry.value - 1)
                      : null,
                  icon: const Icon(CupertinoIcons.minus_circle),
                ),
                Text(arabicNumber(entry.value)),
                IconButton(
                  tooltip: 'زيادة كمية ${part?.name ?? 'القطعة'}',
                  onPressed: enabled && entry.value < 99
                      ? () => controller.setQuantity(entry.key, entry.value + 1)
                      : null,
                  icon: const Icon(CupertinoIcons.plus_circle),
                ),
                TextButton(
                  onPressed: enabled
                      ? () => controller.setQuantity(entry.key, 0)
                      : null,
                  child: const Text('إزالة من القائمة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CarEditor extends StatefulWidget {
  const CarEditor({super.key, required this.controller});
  final GarageController controller;
  @override
  State<CarEditor> createState() => _CarEditorState();
}

class _CarEditorState extends State<CarEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _brand, _model, _year, _engine;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final car = widget.controller.data.car;
    _brand = TextEditingController(text: car?.brand);
    _model = TextEditingController(text: car?.model);
    _year = TextEditingController(text: car?.year.toString());
    _engine = TextEditingController(text: car?.engine);
  }

  @override
  void dispose() {
    for (final c in [_brand, _model, _year, _engine]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: IosFormSheet(
      title: const Text('بيانات سيارتي'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اكتب بيانات سيارتك. الكتالوج محدود؛ عدم ظهور قطع لا يعني عدم توفرها في السوق.',
              ),
              const SizedBox(height: 12),
              for (final field in [
                (_brand, 'الشركة', 'تويوتا'),
                (_model, 'الموديل', 'كامري'),
                (_year, 'سنة الصنع', '2021'),
                (_engine, 'المحرك', '٦ سلندر أو ١٫٦ CVT'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: field.$1,
                    enabled: !_saving,
                    maxLength: field.$1 == _year ? 4 : 60,
                    keyboardType: field.$1 == _year
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: field.$2,
                      hintText: field.$3,
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'أدخل ${field.$2}';
                      }
                      if (field.$1 == _year) {
                        final year = int.tryParse(normalizeSearch(value));
                        if (year == null ||
                            year < 1900 ||
                            year > DateTime.now().year + 1) {
                          return 'أدخل سنة صنع صحيحة';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        CupertinoButton.filled(
          onPressed: _saving
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final saved = await widget.controller.saveCar(
                    SavedCar(
                      _brand.text.trim(),
                      _model.text.trim(),
                      int.parse(normalizeSearch(_year.text)),
                      _engine.text.trim(),
                    ),
                  );
                  if (!context.mounted) return;
                  if (saved) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _saving = false;
                      _error =
                          widget.controller.error ??
                          'الحفظ مشغول؛ حاول مجددًا.';
                    });
                  }
                },
          child: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ السيارة'),
        ),
      ],
    ),
  );
}
