import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternal(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Let the user copy the destination if the device has no suitable app.
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تعذّر فتح الرابط'),
      content: SelectableText(
        uri.scheme == 'tel' ? uri.path : uri.toString(),
        textDirection: TextDirection.ltr,
      ),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await Clipboard.setData(
                ClipboardData(
                  text: uri.scheme == 'tel' ? uri.path : uri.toString(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            } catch (_) {
              // The selectable destination remains available for manual copying.
            }
          },
          child: const Text('نسخ'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}
