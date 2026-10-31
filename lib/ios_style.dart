import 'bilingual_labels.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const waznahInk = Color(0xFFF3F6FA);
const waznahSurface = Color(0xFF121E2C);
const waznahOnAccent = Color(0xFF0C0E11);
const waznahPrimary = Color(0xFFB8BEC5);
const waznahAccent = Color(0xFFB8BEC5);
const waznahBackground = Color(0xFF0C0E11);

const waznahSteel = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFE7EBEF),
    Color(0xFFB8BEC5),
    Color(0xFF8F99A4),
    Color(0xFFD5DBE1),
  ],
  stops: [0, .4, .7, 1],
);

class SteelFinish extends StatelessWidget {
  const SteelFinish({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: waznahSteel.createShader,
    blendMode: BlendMode.srcIn,
    child: child,
  );
}

class EnglishCaption extends StatelessWidget {
  const EnglishCaption(this.arabic, {super.key});
  final String arabic;
  @override
  Widget build(BuildContext context) => englishName(arabic).isEmpty
      ? const SizedBox.shrink()
      : Text(
          englishName(arabic),
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFB0BDCD),
            height: 1.5,
          ),
        );
}

class BilingualTabIcon extends StatelessWidget {
  const BilingualTabIcon(this.icon, this.english, {super.key});
  final IconData icon;
  final String english;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 23),
        Text(
          english,
          maxLines: 1,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class IosPageHeading extends StatelessWidget {
  const IosPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      EnglishCaption(title),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFFB0BDCD), height: 1.6),
      ),
    ],
  );
}

class IosInfoNote extends StatelessWidget {
  const IosInfoNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF182332),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.info_circle, size: 18, color: waznahPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD5DFEA),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shared Cupertino actions; wrapping labels remain usable at large text sizes.
class IosActionButton extends StatelessWidget {
  const IosActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : filled = false,
       tinted = false;
  const IosActionButton.filled({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : filled = true,
       tinted = false;
  const IosActionButton.tinted({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : filled = false,
       tinted = true;
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final bool filled, tinted;
  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Flexible(child: label),
      ],
    );
    if (filled) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    if (tinted) {
      return CupertinoButton.tinted(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    return CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: content,
    );
  }
}

class IosToolbar extends StatelessWidget implements PreferredSizeWidget {
  const IosToolbar({super.key, required this.title, required this.actions});
  final String title;
  final List<IconButton> actions;
  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final visible = actions
        .where(
          (a) =>
              ['حسابي', 'تسجيل الدخول', 'سيارتي والصيانة'].contains(a.tooltip),
        )
        .toList();
    final more = actions.where((a) => !visible.contains(a)).toList();
    Widget button(IconButton a) => Tooltip(
      message: a.tooltip ?? '',
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        onPressed: a.onPressed,
        child: a.icon,
      ),
    );
    return CupertinoNavigationBar(
      automaticBackgroundVisibility: false,
      backgroundColor: const Color(0xF2121E2C),
      middle: title == 'وزنة'
          ? const SteelFinish(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('وزنة'),
                  SizedBox(width: 8),
                  Icon(CupertinoIcons.wrench, size: 22),
                ],
              ),
            )
          : Text(title),
      leading: more.isEmpty
          ? null
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => showCupertinoModalPopup<void>(
                context: context,
                builder: (sheetContext) => CupertinoActionSheet(
                  title: const Text('خيارات وزنة'),
                  actions: [
                    for (final action in more)
                      if (action.onPressed != null)
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            action.onPressed!();
                          },
                          child: Column(
                            children: [
                              Text(action.tooltip ?? ''),
                              EnglishCaption(action.tooltip ?? ''),
                            ],
                          ),
                        ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('إلغاء'),
                  ),
                ),
              ),
              child: const Icon(
                CupertinoIcons.ellipsis_circle,
                semanticLabel: 'المزيد',
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: visible.map(button).toList(),
      ),
    );
  }
}

class IosNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const IosNavigationBar({super.key, required this.title});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(52);
  @override
  Widget build(BuildContext context) => CupertinoNavigationBar(
    middle: Text(title),
    previousPageTitle: 'رجوع',
    backgroundColor: waznahBackground,
  );
}

class IosSheetHeader extends StatelessWidget {
  const IosSheetHeader({super.key, required this.title, this.onClose});
  final String title;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: waznahInk,
          ),
        ),
      ),
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onClose ?? () => Navigator.pop(context),
        child: Semantics(
          label: 'إغلاق',
          child: const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: Color(0xFFA3B1C2),
            size: 28,
          ),
        ),
      ),
    ],
  );
}

class IosFormSheet extends StatelessWidget {
  const IosFormSheet({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: waznahInk,
                ),
                child: title,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: content,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (final action in actions)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: action,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Presentation only: Firebase still uses the actual device platform.
ThemeData buildIosTheme() => ThemeData(
  useMaterial3: true,
  platform: TargetPlatform.iOS,
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: waznahPrimary,
    onPrimary: waznahOnAccent,
    onSurface: waznahInk,
    primary: waznahPrimary,
    secondary: waznahAccent,
    onSecondary: waznahOnAccent,
    surface: waznahSurface,
  ),
  scaffoldBackgroundColor: waznahBackground,
  fontFamily: 'WaznahArabic',
  visualDensity: VisualDensity.standard,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    },
  ),
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: waznahPrimary,
    primaryContrastingColor: waznahOnAccent,
    scaffoldBackgroundColor: waznahBackground,
    barBackgroundColor: Color(0xF2121E2C),
    brightness: Brightness.dark,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 16,
        color: waznahInk,
      ),
      actionTextStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 16,
        color: waznahPrimary,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: waznahInk,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: waznahInk,
      ),
      navActionTextStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 16,
        color: waznahPrimary,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: 'WaznahArabic',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.6,
        color: Color(0xFFD1DAE5),
      ),
    ),
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'WaznahArabic',
    bodyColor: waznahInk,
    displayColor: waznahInk,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    toolbarHeight: 52,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: waznahBackground,
    foregroundColor: waznahInk,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: waznahInk,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: waznahSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(44, 48),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(44, 48),
      side: const BorderSide(color: Color(0xFF435369)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: waznahPrimary),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: waznahSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: waznahPrimary, width: 1.5),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: waznahBackground,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: waznahBackground,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF35465B),
    thickness: 0.5,
  ),
);

class IosCategoryPicker extends StatelessWidget {
  const IosCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: CupertinoSlidingSegmentedControl<String>(
      groupValue: value,
      thumbColor: waznahAccent,
      backgroundColor: const Color(0xFF121E2C),
      onValueChanged: (selection) {
        if (selection != null) onChanged(selection);
      },
      children: {
        for (final category in ['الكل', 'فلاتر', 'فرامل', 'كهرباء', 'تعليق'])
          category: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: category == value ? waznahOnAccent : waznahInk,
                  ),
                ),
                Text(
                  englishName(category),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 10,
                    color: category == value ? waznahOnAccent : waznahInk,
                  ),
                ),
              ],
            ),
          ),
      },
    ),
  );
}

class IosFilterPicker extends StatelessWidget {
  const IosFilterPicker({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        final selection = await showCupertinoModalPopup<String>(
          context: context,
          builder: (sheetContext) => CupertinoActionSheet(
            title: Column(children: [Text(label), EnglishCaption(label)]),
            actions: [
              for (final option in options)
                CupertinoActionSheetAction(
                  isDefaultAction: option == value,
                  onPressed: () => Navigator.pop(sheetContext, option),
                  child: Text(option),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('إلغاء'),
            ),
          ),
        );
        if (context.mounted && selection != null) onChanged(selection);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: waznahSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0BDCD),
                    ),
                  ),
                  EnglishCaption(label),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, color: waznahInk),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 15),
          ],
        ),
      ),
    ),
  );
}
