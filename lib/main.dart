import 'currency_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/services.dart';

import 'catalog_data.dart';
import 'favorites_store.dart';
import 'external_link.dart';
import 'garage.dart';
import 'garage_page.dart';
import 'service_prices_page.dart';
import 'account_gate.dart';
import 'ios_style.dart';
import 'catalog_snapshot.dart';
import 'startup_intro.dart';

void main() => runApp(const MyApp(cloudAccounts: true, showIntro: true));

const ink = waznahInk;
const brandColor = waznahPrimary;
const canvas = waznahBackground;

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.favoritesStore = const LocalFavoritesStore(),
    this.garageStore = const LocalGarageStore(),
    this.cloudAccounts = false,
    this.showIntro = false,
  });
  final bool cloudAccounts;
  final bool showIntro;
  final FavoritesStore favoritesStore;
  final GarageStore garageStore;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'وزنة | قطع الغيار والورش',
    debugShowCheckedModeBanner: false,
    theme: buildIosTheme(),
    // يشمل الاتجاه العربي الصفحة والنوافذ التي تظهر فوقها.
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: showIntro
          ? WaznahIntro(
              deferDestination: true,
              firstFrameReady:
                  WidgetsBinding.instance.waitUntilFirstFrameRasterized,
              child: child!,
            )
          : child!,
    ),
    home: cloudAccounts
        ? const AccountGate()
        : WaznahHome(favoritesStore: favoritesStore, garageStore: garageStore),
  );
}

class WaznahHome extends StatefulWidget {
  const WaznahHome({
    super.key,
    this.favoritesStore = const LocalFavoritesStore(),
    this.garageStore = const LocalGarageStore(),
    this.onAccount,
    this.cloudAccount = false,
    this.catalog,
    this.onRefreshCatalog,
    this.catalogBusy = false,
    this.catalogFailed = false,
    this.catalogNotPublished = false,
  });
  final CatalogSnapshot? catalog;
  final VoidCallback? onRefreshCatalog;
  final bool catalogBusy, catalogFailed;
  final bool catalogNotPublished;
  final VoidCallback? onAccount;
  final bool cloudAccount;
  final FavoritesStore favoritesStore;
  final GarageStore garageStore;
  @override
  State<WaznahHome> createState() => _WaznahHomeState();
}

class _WaznahHomeState extends State<WaznahHome> {
  @override
  void didUpdateWidget(covariant WaznahHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog?.revision != widget.catalog?.revision) {
      _brand = 'كل السيارات';
      _model = 'كل الموديلات';
      _year = null;
      _engine = 'كل المحركات';
      _district = 'كل الصناعيات';
    }
  }

  CatalogSnapshot get _catalog => widget.catalog ?? CatalogSnapshot.bundled;
  List<SparePart> get catalogParts => _catalog.parts;
  List<Workshop> get westRiyadhWorkshops => _catalog.workshops;
  late final GarageController _garage;
  bool _useCar = true;
  void _garageChanged() {
    if (mounted) setState(() {});
  }

  void _openGarage() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GaragePage(
        parts: _catalog.parts,
        controller: _garage,
        cloudAccount: widget.cloudAccount,
        onCarSaved: () {
          if (!mounted) return;
          _resetFilters();
          setState(() => _useCar = true);
        },
        onBrowse: () => setState(() => _tab = 0),
      ),
    ),
  );
  final _search = TextEditingController();
  final _workshopSearch = TextEditingController();
  final Set<String> _favorites = {};
  bool _favoritesReady = false;
  bool _savingFavorite = false;
  bool _storageError = false;
  String _model = 'كل الموديلات';
  int? _year;
  String _engine = 'كل المحركات';

  @override
  void initState() {
    super.initState();
    _garage = GarageController(widget.garageStore)..addListener(_garageChanged);
    _garage.load();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_savingFavorite) return;
    setState(() {
      _favoritesReady = false;
      _storageError = false;
    });
    try {
      final saved = await widget.favoritesStore.load();
      if (!mounted) return;
      setState(() {
        _favorites
          ..clear()
          ..addAll(saved);
        _favoritesReady = true;
        _storageError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _storageError = true);
    }
  }

  int _tab = 0;
  String _category = 'الكل';
  String _brand = 'كل السيارات';
  String _district = 'كل الصناعيات';
  bool _highestFirst = false;

  @override
  void dispose() {
    _search.dispose();
    _garage.removeListener(_garageChanged);
    _garage.dispose();
    _workshopSearch.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(SparePart part) async {
    if (!_favoritesReady || _savingFavorite) return;
    final next = {..._favorites};
    if (!next.add(part.id)) next.remove(part.id);
    setState(() => _savingFavorite = true);
    try {
      await widget.favoritesStore.save(next);
      if (mounted) {
        setState(() {
          _favorites
            ..clear()
            ..addAll(next);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذّر تأكيد الحفظ. تأكد من الاتصال وحدّث البيانات.',
            ),
            action: SnackBarAction(label: 'تحديث', onPressed: _loadFavorites),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingFavorite = false);
    }
  }

  void _resetFilters() => setState(() {
    _search.clear();
    _category = 'الكل';
    _brand = 'كل السيارات';
    _model = 'كل الموديلات';
    _year = null;
    _engine = 'كل المحركات';
    _highestFirst = false;
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: IosToolbar(
        title: 'وزنة',
        actions: [
          IconButton(
            tooltip: 'معاينة شاشة البداية',
            icon: const Icon(CupertinoIcons.play_circle),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => WaznahIntro(
                onCompleted: () => Navigator.of(dialogContext).pop(),
                child: Center(
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إغلاق المعاينة'),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onRefreshCatalog != null)
            IconButton(
              tooltip: 'تحديث القطع والأسعار',
              onPressed: widget.catalogBusy ? null : widget.onRefreshCatalog,
              icon: const Icon(CupertinoIcons.arrow_down_circle),
            ),
          if (widget.onAccount != null)
            IconButton(
              tooltip: widget.cloudAccount ? 'حسابي' : 'تسجيل الدخول',
              onPressed: _savingFavorite || _garage.busy
                  ? null
                  : widget.onAccount,
              icon: const Icon(CupertinoIcons.person_crop_circle),
            ),
          if (widget.cloudAccount)
            IconButton(
              tooltip: 'تحديث بيانات الحساب',
              onPressed: _savingFavorite || _garage.busy || !_favoritesReady
                  ? null
                  : () {
                      _loadFavorites();
                      _garage.load();
                    },
              icon: const Icon(CupertinoIcons.arrow_clockwise),
            ),
          IconButton(
            tooltip: 'سيارتي والصيانة',
            onPressed: _openGarage,
            icon: const Icon(CupertinoIcons.car_detailed),
          ),
          IconButton(
            tooltip: 'عن وزنة',
            icon: const Icon(CupertinoIcons.info),
            onPressed: () => showCupertinoDialog<void>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('عن وزنة | About Waznah'),
                content: const Text(
                  'وزنة تطبيق يساعد مالكي المركبات على اتخاذ قرارات صيانة أكثر وعيًا، من خلال جمع معلومات قطع الغيار وأسعارها وتكاليف خدمات الصيانة في تجربة واحدة سهلة الاستخدام.\n\nيتيح التطبيق البحث عن القطع ومقارنة الأسعار المتاحة، واستكشاف ورش غرب الرياض، وحفظ بيانات السيارة والقطع المفضلة وتنظيم قائمة الصيانة وتقدير تكلفتها.\n\nطُوّر وزنة بوصفه مشروعًا أكاديميًا يربط مفاهيم تحليل الأنظمة وتصميم واجهات الاستخدام وقواعد البيانات باحتياج عملي في مجال خدمات المركبات.\n\nتعتمد الأسعار ومعلومات الورش على مصادر منشورة وقد تتغير؛ لذا يُرجى تأكيد السعر وتوافق القطعة مع مقدم الخدمة. التطبيق أداة للمعلومات والمقارنة، ولا ينفّذ عمليات شراء أو حجز.',
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_storageError)
            MaterialBanner(
              content: const Text(
                'تعذّر تحميل المفضلة. أعد المحاولة قبل حفظ قطع جديدة.',
              ),
              actions: [
                TextButton(
                  onPressed: _loadFavorites,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          if (!_favoritesReady && !_storageError)
            const LinearProgressIndicator(),
          Expanded(
            child: Row(
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: _tab,
                    onDestinationSelected: (value) => setState(() {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _tab = value;
                    }),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: canvas,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon: Icon(Icons.grid_view_rounded),
                        label: Column(
                          children: [
                            Text('قطع الغيار'),
                            EnglishCaption('قطع الغيار'),
                          ],
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(CupertinoIcons.car_detailed),
                        selectedIcon: Icon(Icons.garage_rounded),
                        label: Column(
                          children: [Text('الورش'), EnglishCaption('الورش')],
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(CupertinoIcons.heart),
                        selectedIcon: Icon(CupertinoIcons.heart_fill),
                        label: Column(
                          children: [
                            Text('المفضلة'),
                            EnglishCaption('المفضلة'),
                          ],
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.build_outlined),
                        label: Column(
                          children: [
                            Text('شغل اليد'),
                            EnglishCaption('شغل اليد'),
                          ],
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: _tab == 3
                      ? ServicePricesPage(
                          embedded: true,
                          services: _catalog.services,
                          workshops: _catalog.workshops,
                        )
                      : Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1160),
                            child: SingleChildScrollView(
                              key: PageStorageKey(_tab),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                wide ? 32 : 18,
                                12,
                                wide ? 32 : 18,
                                32,
                              ),
                              child: switch (_tab) {
                                0 => _partsPage(),
                                1 => _workshopsPage(),
                                _ => _favoritesPage(),
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : CupertinoTabBar(
              currentIndex: _tab,
              activeColor: brandColor,
              inactiveColor: const Color(0xFFD1DAE5),
              backgroundColor: const Color(0xF5121E2C),
              height:
                  84 +
                  (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                        0,
                        28,
                      ) *
                      5,
              onTap: (value) => setState(() {
                FocusManager.instance.primaryFocus?.unfocus();
                _tab = value;
              }),
              items: const [
                BottomNavigationBarItem(
                  icon: BilingualTabIcon(
                    CupertinoIcons.square_grid_2x2,
                    'Parts',
                  ),
                  activeIcon: BilingualTabIcon(
                    CupertinoIcons.square_grid_2x2_fill,
                    'Parts',
                  ),
                  label: 'قطع الغيار',
                ),
                BottomNavigationBarItem(
                  icon: BilingualTabIcon(CupertinoIcons.location, 'Workshops'),
                  activeIcon: BilingualTabIcon(
                    CupertinoIcons.location_fill,
                    'Workshops',
                  ),
                  label: 'الورش',
                ),
                BottomNavigationBarItem(
                  icon: BilingualTabIcon(CupertinoIcons.heart, 'Favorites'),
                  activeIcon: BilingualTabIcon(
                    CupertinoIcons.heart_fill,
                    'Favorites',
                  ),
                  label: 'المفضلة',
                ),
                BottomNavigationBarItem(
                  icon: BilingualTabIcon(CupertinoIcons.wrench, 'Labor'),
                  activeIcon: BilingualTabIcon(
                    CupertinoIcons.wrench_fill,
                    'Labor',
                  ),
                  label: 'شغل اليد',
                ),
              ],
            ),
    );
  }

  Widget _partsPage() {
    final parts =
        filterParts(
              source: _catalog.parts,
              query: _search.text,
              category: _category,
              brand: _brand,
              highestFirst: _highestFirst,
              model: _model,
              year: _year,
              engine: _engine,
            )
            .where(
              (part) =>
                  !_useCar ||
                  _garage.data.car == null ||
                  _garage.data.car!.matches(part),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'قطع الغيار',
          subtitle: 'أسعار منشورة وورش في غرب الرياض',
        ),
        if (widget.onRefreshCatalog != null &&
            (widget.catalogBusy ||
                widget.catalogNotPublished ||
                widget.catalogFailed))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.catalogBusy
                  ? 'جارٍ تحديث الكتالوج…'
                  : widget.catalogNotPublished
                  ? 'لا توجد قائمة أسعار منشورة للتحديث حاليًا؛ نعرض النسخة المتاحة لديك.'
                  : widget.catalogFailed
                  ? 'تعذّر تحديث الكتالوج؛ نعرض آخر نسخة متاحة. أعد المحاولة من زر تحديث القطع والأسعار.'
                  : 'تاريخ نسخة الكتالوج: ${_catalog.reviewedAt}؛ قد تختلف تواريخ مراجعة العروض.',
            ),
          ),
        const SizedBox(height: 12),
        if (_garage.data.car != null) ...[
          Text(
            _garage.data.car!.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('تصفية حسب سيارتي'),
            subtitle: const Text(
              'حسب وصف المتاجر؛ توافق المحرك غير المذكور يحتاج تأكيدًا.',
            ),
            value: _useCar,
            onChanged: (value) => setState(() => _useCar = value),
          ),
        ] else
          IosActionButton(
            onPressed: _openGarage,
            icon: const Icon(Icons.directions_car_outlined),
            label: const Text('أضف سيارتك وجهّز قائمة الصيانة'),
          ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'مثال: فلتر زيت، كامري…',
            labelText: 'ابحث عن قطعة',
            prefixIcon: const Icon(CupertinoIcons.search),
            fillColor: const Color(0xFF121E2C),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: () => setState(() => _search.clear()),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        IosCategoryPicker(
          value: _category,
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _dropdown(
              value: _brand,
              label: 'شركة السيارة',
              options: [
                'كل السيارات',
                ...catalogParts
                    .where((part) => part.fitment != null)
                    .map((part) => part.brand)
                    .toSet(),
              ],
              onChanged: (value) => setState(() {
                _brand = value;
                _model = 'كل الموديلات';
                _year = null;
                _engine = 'كل المحركات';
              }),
            ),
            if (_brand != 'كل السيارات')
              _dropdown(
                value: _model,
                label: 'الموديل',
                options: [
                  'كل الموديلات',
                  ...catalogParts
                      .where((p) => p.brand == _brand && p.fitment != null)
                      .map((p) => p.fitment!.model)
                      .toSet(),
                ],
                onChanged: (value) => setState(() {
                  _model = value;
                  _year = null;
                  _engine = 'كل المحركات';
                }),
              ),
            if (_model != 'كل الموديلات')
              _dropdown(
                value: _year == null ? 'كل السنوات' : arabicNumber(_year!),
                label: 'سنة الصنع',
                options: ['كل السنوات', ..._availableYears.map(arabicNumber)],
                onChanged: (value) => setState(
                  () => _year = value == 'كل السنوات'
                      ? null
                      : _availableYears.firstWhere(
                          (year) => arabicNumber(year) == value,
                        ),
                ),
              ),
            if (_model != 'كل الموديلات')
              _dropdown(
                value: _engine,
                label: 'المحرك',
                options: ['كل المحركات', ..._availableEngines],
                onChanged: (value) => setState(() => _engine = value),
              ),
            _dropdown(
              value: _highestFirst ? 'الأعلى سعرًا' : 'الأقل سعرًا',
              label: 'ترتيب الأسعار',
              options: ['الأقل سعرًا', 'الأعلى سعرًا'],
              onChanged: (value) =>
                  setState(() => _highestFirst = value == 'الأعلى سعرًا'),
            ),
            Text(
              '${arabicNumber(parts.length)} نتائج',
              style: const TextStyle(
                color: brandColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_search.text.isNotEmpty ||
                _category != 'الكل' ||
                _brand != 'كل السيارات')
              TextButton(
                onPressed: _resetFilters,
                child: const Text('مسح الفلاتر'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_model != 'كل الموديلات')
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'طابق رقم القطعة ورقم الهيكل؛ وصف المتجر ليس ضمان توافق.',
              style: TextStyle(fontSize: 13, color: ink, height: 1.6),
            ),
          ),
        const Text(
          'الأسعار ليست مباشرة؛ أكد السعر والتوفر قبل الشراء.',
          style: TextStyle(fontSize: 12, color: Color(0xFFB0BDCD)),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IosActionButton(
            onPressed: _showCatalogInformation,
            icon: const Icon(CupertinoIcons.info_circle, size: 18),
            label: const Text('عن الأسعار والمصادر'),
          ),
        ),
        const SizedBox(height: 8),
        if (parts.isEmpty)
          EmptyState(
            icon: Icons.search_off,
            title: 'ما لقينا قطعة بهالمواصفات',
            message: 'جرّب اسمًا ثانيًا أو أزل بعض الفلاتر.',
            action: 'عرض كل القطع',
            onAction: () {
              _resetFilters();
              setState(() => _useCar = false);
            },
          )
        else
          _partGrid(parts),
        const SizedBox(height: 24),
        const Text(
          'التوافق من وصف المتجر؛ طابق رقم القطعة ورقم الهيكل، وأكد السعر والتوفر قبل الشراء.',
          style: TextStyle(color: Color(0xFFB0BDCD), fontSize: 12, height: 1.8),
        ),
      ],
    );
  }

  void _showCatalogInformation() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('عن الأسعار والمصادر'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                'الكتالوج: ${arabicNumber(catalogParts.length)} قطع، وعدد الورش ${arabicNumber(westRiyadhWorkshops.length)}. المقارنة متاحة عند وجود أكثر من عرض لنفس القطعة.',
              ),
              const SizedBox(height: 12),
              Text(
                'تاريخ نسخة الكتالوج: ${_catalog.reviewedAt}؛ قد تختلف تواريخ مراجعة العروض.',
              ),
              const SizedBox(height: 12),
              const Text(
                'الأسعار والمواقع من مصادر منشورة وليست تحديثًا مباشرًا. راجع المصدر في تفاصيل العرض، وأكد السعر والتوفر مع المتجر أو الورشة. طابق رقم القطعة ورقم الهيكل قبل الشراء.',
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) => IosFilterPicker(
    value: value,
    label: label,
    options: options,
    onChanged: onChanged,
  );

  Widget _partGrid(List<SparePart> parts) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 920
          ? 3
          : constraints.maxWidth >= 580
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final part in parts)
            SizedBox(
              width: width,
              child: PartCard(
                part: part,
                favorite: _favorites.contains(part.id),
                onFavorite: _favoritesReady && !_savingFavorite
                    ? () => _toggleFavorite(part)
                    : null,
                onOpen: () => _showPart(part),
              ),
            ),
        ],
      );
    },
  );

  List<int> get _availableYears => {
    for (final part in catalogParts)
      if (part.brand == _brand && part.fitment?.model == _model)
        for (int y = part.fitment!.fromYear; y <= part.fitment!.toYear; y++) y,
  }.toList()..sort((a, b) => b.compareTo(a));

  List<String> get _availableEngines => {
    for (final part in catalogParts)
      if (part.brand == _brand && part.fitment?.model == _model)
        part.fitment!.engine,
  }.toList();

  Widget _favoritesPage() {
    final parts = catalogParts
        .where((part) => _favorites.contains(part.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'قطع تستاهل ترجع لها',
          subtitle: widget.cloudAccount
              ? 'محفوظة في حسابك. حدّث البيانات لجلب تعديلات الأجهزة الأخرى.'
              : 'محفوظة على هذا الجهاز، حتى بعد إغلاق التطبيق.',
        ),
        const SizedBox(height: 24),
        if (!_favoritesReady)
          Text(
            _storageError
                ? 'المفضلة غير متاحة حتى يكتمل تحميلها.'
                : 'جارٍ تحميل المفضلة…',
          )
        else if (parts.isEmpty)
          EmptyState(
            icon: CupertinoIcons.heart,
            title: 'مفضلتك تنتظر أول قطعة',
            message: 'اضغط القلب بجانب أي قطعة عشان تلقاها هنا.',
            action: 'تصفّح قطع الغيار',
            onAction: () => setState(() => _tab = 0),
          )
        else ...[
          const DataNotice(),
          const SizedBox(height: 20),
          _partGrid(parts),
        ],
      ],
    );
  }

  Widget _workshopsPage() {
    final workshops = westRiyadhWorkshops
        .where(
          (workshop) =>
              (_district == 'كل الصناعيات' || workshop.district == _district) &&
              matchesSearch(
                [
                  workshop.name,
                  workshop.specialty,
                  workshop.address,
                  ...workshop.services,
                ].join(' '),
                _workshopSearch.text,
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'ورش غرب الرياض',
          subtitle: 'ورش فعلية في العوالي وطويق، مع مصدر العنوان ورقم التواصل.',
        ),
        const SizedBox(height: 20),
        const DataNotice(),
        const SizedBox(height: 20),
        TextFormField(
          controller: _workshopSearch,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'ابحث عن ورشة أو خدمة',
            hintText: 'مثال: كهرباء أو فحص كمبيوتر',
            prefixIcon: const Icon(CupertinoIcons.search),
            fillColor: const Color(0xFF121E2C),
            suffixIcon: _workshopSearch.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح بحث الورش',
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    onPressed: () => setState(_workshopSearch.clear),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _dropdown(
            value: _district,
            label: 'الصناعية',
            options: [
              'كل الصناعيات',
              ...westRiyadhWorkshops.map((w) => w.district).toSet(),
            ],
            onChanged: (value) => setState(() => _district = value),
          ),
        ),
        const SizedBox(height: 20),
        if (workshops.isEmpty)
          EmptyState(
            icon: CupertinoIcons.car_detailed,
            title: 'ما لقينا ورشة مطابقة',
            message: 'غيّر البحث أو اختر كل الصناعيات.',
            action: 'عرض كل الورش',
            onAction: () => setState(() {
              _workshopSearch.clear();
              _district = 'كل الصناعيات';
            }),
          )
        else
          for (final workshop in workshops)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CategoryIcon(category: 'ورش'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workshop.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                workshop.specialty,
                                style: const TextStyle(height: 1.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Pill(
                      label: workshop.district,
                      icon: CupertinoIcons.location,
                    ),
                    const SizedBox(height: 12),
                    Text(workshop.address, style: const TextStyle(height: 1.8)),
                    const SizedBox(height: 12),
                    const Text(
                      'أجرة الشغل: اطلب تسعيرة من الورشة',
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IosActionButton.tinted(
                      onPressed: () => _showWorkshop(workshop),
                      icon: const Icon(CupertinoIcons.chevron_forward),
                      label: const Text('تفاصيل الورشة والموقع'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _showPart(SparePart part) async {
    final offers = [...part.offers]
      ..sort((a, b) {
        if (a.available == false && b.available != false) return 1;
        if (b.available == false && a.available != false) return -1;
        if (a.price == null) return b.price == null ? 0 : 1;
        if (b.price == null) return -1;
        return a.price!.compareTo(b.price!);
      });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (context) => StatefulBuilder(
        builder: (context, updateSheet) => SheetBody(
          children: [
            IosSheetHeader(title: part.name),
            EnglishCaption(part.name),
            const SizedBox(height: 12),
            Text(
              '${part.brand} • ${part.vehicle}',
              style: const TextStyle(color: brandColor),
            ),
            const SizedBox(height: 12),
            Text(part.description, style: const TextStyle(height: 1.8)),
            const SizedBox(height: 8),
            SelectableText('رقم القطعة: ${part.partNumber}'),
            const SizedBox(height: 16),
            const DataNotice(),
            const SizedBox(height: 24),
            SectionTitle(
              title: offers.length > 1 ? 'قارن عروض المتاجر' : 'السعر ومصدره',
              subtitle: 'أسعار منشورة وليست تحديثًا مباشرًا. راجع ملاحظة الضريبة والتوفر لكل متجر.',
            ),
            const SizedBox(height: 12),
            for (final offer in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.seller,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: CurrencyText(
                              money(offer.price),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: brandColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CurrencyText(offer.notes),
                      const SizedBox(height: 8),
                      Text(
                        offer.available == false
                            ? 'غير متوفر عند المراجعة'
                            : offer.available == true
                            ? 'كان متاحًا عند المراجعة؛ أكد التوفر'
                            : 'التوفر غير مؤكد',
                      ),
                      const SizedBox(height: 8),
                      SourceReference(url: offer.sourceUrl),
                      if (offers.length > 1 &&
                          offer.price != null &&
                          offer.available != false &&
                          offer.price == part.lowestPrice) ...[
                        const SizedBox(height: 8),
                        const Pill(
                          label: 'الأقل ضمن الأسعار المنشورة',
                          icon: CupertinoIcons.checkmark_circle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _garage,
              builder: (context, _) {
                final inList = _garage.data.items.containsKey(part.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_garage.error != null) Text(_garage.error!),
                    IosActionButton.tinted(
                      onPressed: !_garage.ready || _garage.busy
                          ? null
                          : () async {
                              if (inList) {
                                Navigator.pop(context);
                                _openGarage();
                                return;
                              }
                              final saved = await _garage.setQuantity(
                                part.id,
                                1,
                              );
                              if (saved && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('أضيفت إلى قائمة الصيانة'),
                                  ),
                                );
                              }
                            },
                      icon: Icon(
                        inList
                            ? CupertinoIcons.list_bullet
                            : CupertinoIcons.add_circled,
                      ),
                      label: Text(
                        inList ? 'عرض قائمة الصيانة' : 'أضف لقائمة الصيانة',
                      ),
                    ),
                    if (!_garage.ready && !_garage.busy)
                      TextButton(
                        onPressed: _garage.load,
                        child: const Text('إعادة تحميل قائمة الصيانة'),
                      ),
                  ],
                );
              },
            ),
            IosActionButton.filled(
              onPressed: !_favoritesReady || _savingFavorite
                  ? null
                  : () async {
                      final action = _toggleFavorite(part);
                      updateSheet(() {});
                      await action;
                      if (context.mounted) updateSheet(() {});
                    },
              icon: Icon(
                _favorites.contains(part.id)
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
              ),
              label: Text(
                _favorites.contains(part.id)
                    ? 'إزالة من المفضلة'
                    : 'حفظ في المفضلة',
              ),
            ),
            IosActionButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _tab = 1);
              },
              icon: const Icon(CupertinoIcons.car_detailed),
              label: const Text('استكشف الورش واطلب تسعيرة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWorkshop(Workshop workshop) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (context) => SheetBody(
      children: [
        IosSheetHeader(title: workshop.name),
        Text(workshop.specialty),
        const SizedBox(height: 20),
        const SectionTitle(
          title: 'الموقع والتواصل',
          subtitle: 'أكد العنوان والموعد مع الورشة قبل الزيارة.',
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(workshop.address, style: const TextStyle(height: 1.8)),
              const SizedBox(height: 12),
              SelectableText(workshop.phone, textDirection: TextDirection.ltr),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IosActionButton.filled(
                    onPressed: () => openExternal(
                      context,
                      Uri(scheme: 'tel', path: workshop.phone),
                    ),
                    icon: const Icon(CupertinoIcons.phone),
                    label: const Text('اتصل بالورشة'),
                  ),
                  IosActionButton.tinted(
                    onPressed: () => openExternal(context, workshop.mapsUri),
                    icon: const Icon(CupertinoIcons.map),
                    label: const Text('فتح الخرائط'),
                  ),
                ],
              ),
              SourceReference(
                url: workshop.mapsUri.toString(),
                label: 'نسخ رابط الموقع',
                showOpenButton: false,
              ),
              SourceReference(
                url: workshop.sourceUrl,
                label: 'نسخ مصدر بيانات الورشة',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'الخدمات وأجرة الشغل',
          subtitle: 'لا تتوفر لدينا قائمة أسعار موثقة لهذه الورشة. اطلب تسعيرة حسب سيارتك والعطل.',
        ),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final service in workshop.services)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(service),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'التقييمات',
          subtitle: 'غير متوفرة لدينا من مصدر موثق؛ لم نضع تقييمًا تقديريًا.',
        ),
        const SizedBox(height: 20),
        const Text('مراجعة المصادر: $sourceReviewLabel'),
        const SizedBox(height: 20),
        CupertinoButton.filled(
          onPressed: () => Navigator.pop(context),
          child: const Text('رجوع للورش'),
        ),
      ],
    ),
  );
}

class PartCard extends StatelessWidget {
  const PartCard({
    super.key,
    required this.part,
    required this.favorite,
    required this.onFavorite,
    required this.onOpen,
  });
  final SparePart part;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategoryIcon(category: part.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.category,
                    style: const TextStyle(color: brandColor, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    part.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  EnglishCaption(part.name),
                ],
              ),
            ),
            IconButton(
              tooltip: favorite
                  ? 'إزالة ${part.name} من المفضلة'
                  : 'حفظ ${part.name} في المفضلة',
              isSelected: favorite,
              onPressed: onFavorite,
              icon: const Icon(CupertinoIcons.heart),
              selectedIcon: const Icon(
                CupertinoIcons.heart_fill,
                color: brandColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${part.brand} • ${part.vehicle}',
          style: const TextStyle(color: Color(0xFFB0BDCD), fontSize: 13),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Color(0xFF35465B)),
        ),
        const Text('السعر المنشور', style: TextStyle(fontSize: 12)),
        CurrencyText(
          money(part.lowestPrice),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: brandColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          part.offers.length == 1
              ? 'مصدر واحد — السعر غير مقارن'
              : '${arabicNumber(part.offers.length)} مصادر أسعار',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.tinted(
            onPressed: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Text(
              part.offers.length > 1 ? 'قارن الأسعار' : 'تفاصيل السعر',
            ),
          ),
        ),
      ],
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: waznahSurface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category});
  final String category;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF202A35),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(
      switch (category) {
        'فلاتر' => Icons.filter_alt_outlined,
        'فرامل' => Icons.disc_full_outlined,
        'كهرباء' => Icons.bolt_rounded,
        'تعليق' => Icons.settings_outlined,
        _ => CupertinoIcons.car_detailed,
      },
      color: brandColor,
      size: 30,
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF182332),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: brandColor, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: const TextStyle(color: ink, fontSize: 12)),
        ),
      ],
    ),
  );
}

class DataNotice extends StatelessWidget {
  const DataNotice({super.key});
  @override
  Widget build(BuildContext context) => const IosInfoNote(
    'أسعار ومواقع من مصادر منشورة وليست تحديثًا مباشرًا. تختلف تواريخ مراجعة العروض؛ راجع المصدر وأكد السعر والتوفر مع المتجر أو الورشة.',
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      IosPageHeading(title: title, subtitle: subtitle);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Surface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, color: brandColor, size: 50),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 20),
            CupertinoButton.filled(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.82,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class SourceReference extends StatelessWidget {
  const SourceReference({
    super.key,
    required this.url,
    this.label = 'نسخ رابط المصدر',
    this.showOpenButton = true,
  });
  final String url;
  final String label;
  final bool showOpenButton;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOpenButton)
          IosActionButton(
            onPressed: () => openExternal(context, Uri.parse(url)),
            icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
            label: const Text('فتح المصدر'),
          ),
        Text(
          Uri.parse(url).host,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: brandColor, fontSize: 12),
        ),
        IosActionButton(
          icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
          label: Text(label),
          onPressed: () async {
            try {
              await Clipboard.setData(
                ClipboardData(text: Uri.parse(url).toString()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ الرابط؛ الصقه في المتصفح لفتح المصدر.'),
                ),
              );
            } catch (_) {
              if (!context.mounted) return;
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('رابط المصدر'),
                  content: SelectableText(
                    url,
                    textDirection: TextDirection.ltr,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}
