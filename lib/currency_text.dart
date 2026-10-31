import 'package:flutter/material.dart';

/// Keeps spoken currency names while rendering the official SAMA mark.
class CurrencyText extends StatelessWidget {
  const CurrencyText(this.data, {super.key, this.style, this.textAlign});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final size = MediaQuery.textScalerOf(context)
        .scale(effective.fontSize ?? 14);
    final pieces = data.split('ريال');
    return Semantics(
      label: data,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < pieces.length; i++) ...[
                if (i > 0)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Image.asset(
                      'assets/currency/saudi-riyal.png',
                      height: size,
                      width: size * 3000 / 3353,
                      cacheHeight:
                          (size * MediaQuery.devicePixelRatioOf(context))
                              .ceil(),
                      color: effective.color,
                      excludeFromSemantics: true,
                    ),
                  ),
                TextSpan(text: pieces[i]),
              ],
            ],
          ),
          style: style,
          textAlign: textAlign,
        ),
      ),
    );
  }
}
