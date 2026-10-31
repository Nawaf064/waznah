import 'package:flutter/material.dart';

import 'main.dart' show WaznahHome, brandColor;
import 'ios_style.dart';

/// Account entry stays unavailable until an authentication service is connected.
/// Browsing as a guest never creates or authenticates an account.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SteelFinish(
                  child: Icon(Icons.build_rounded, size: 64, color: brandColor),
                ),
                const SizedBox(height: 16),
                const SteelFinish(
                  child: Text(
                    'وزنة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: waznahPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('قرار أوضح، لسيارتك', textAlign: TextAlign.center),
                const SizedBox(height: 40),
                const Text(
                  'أهلًا بك',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          color: brandColor,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'الحسابات غير متاحة بعد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'نعمل على تجهيز تسجيل الدخول. تقدر الآن تستكشف القطع والورش كضيف. المفضلة تُحفظ خلال الجلسة فقط.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const FilledButton(
                  onPressed: null,
                  child: Text('تسجيل الدخول — قريبًا'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    } else {
                      navigator.pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const WaznahHome(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('تصفح كضيف'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
