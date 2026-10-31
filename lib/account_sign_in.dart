import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'ios_style.dart';

String accountError(String code) => switch (code) {
  'invalid-email' => 'اكتب بريدًا إلكترونيًا صحيحًا.',
  'weak-password' => 'كلمة المرور ضعيفة. استخدم ٨ أحرف أو أكثر.',
  'email-already-in-use' => 'هذا البريد مسجل؛ جرّب تسجيل الدخول.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'تعذّر الدخول. تأكد من البريد وكلمة المرور.',
  'network-request-failed' => 'تعذّر الاتصال. تأكد من الإنترنت وحاول مجددًا.',
  'too-many-requests' => 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.',
  'user-disabled' => 'هذا الحساب موقوف. تواصل مع إدارة التطبيق.',
  _ => 'تعذّرت العملية. حاول مجددًا بعد قليل.',
};

class AccountSignIn extends StatefulWidget {
  const AccountSignIn({
    super.key,
    required this.onGuest,
    required this.signIn,
    required this.register,
    required this.resetPassword,
  });
  final VoidCallback onGuest;
  final Future<void> Function(String email, String password) signIn, register;
  final Future<void> Function(String email) resetPassword;
  @override
  State<AccountSignIn> createState() => _AccountSignInState();
}

class _AccountSignInState extends State<AccountSignIn> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool _register = false, _busy = false, _hide = true;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _emailError(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
      ? null
      : 'اكتب بريدًا إلكترونيًا صحيحًا';
  Future<void> _submit({bool reset = false}) async {
    if (_busy) return;
    if (reset
        ? _emailError(_email.text) != null
        : !_form.currentState!.validate()) {
      if (reset) setState(() => _message = 'اكتب بريدك الإلكتروني أولًا.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (reset) {
        await widget.resetPassword(_email.text.trim());
        if (mounted) {
          setState(
            () => _message = 'إذا كان البريد مرتبطًا بحساب، ستصلك رسالة لاستعادة كلمة المرور.',
          );
        }
      } else {
        await (_register ? widget.register : widget.signIn)(
          _email.text.trim(),
          _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _message = reset && error.code == 'user-not-found'
              ? 'إذا كان البريد مرتبطًا بحساب، ستصلك رسالة لاستعادة كلمة المرور.'
              : accountError(error.code),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذّرت العملية. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: waznahSurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const SteelFinish(
                          child: Icon(
                            CupertinoIcons.wrench,
                            size: 42,
                            color: waznahPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SteelFinish(
                      child: Text(
                        'وزنة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _register ? 'إنشاء حساب' : 'تسجيل الدخول',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'احفظ سيارتك ومفضلتك وقائمة الصيانة في حسابك. بيانات الضيف تبقى منفصلة على هذا الجهاز.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: _emailError,
                      decoration: const InputDecoration(
                        hintText: 'البريد الإلكتروني',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _hide,
                      enableSuggestions: false,
                      autocorrect: false,
                      textDirection: TextDirection.ltr,
                      validator: (v) => (v ?? '').isEmpty
                          ? 'اكتب كلمة المرور'
                          : _register && v!.length < 8
                          ? 'استخدم ٨ أحرف أو أكثر'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        suffixIcon: IconButton(
                          tooltip: _hide
                              ? 'إظهار كلمة المرور'
                              : 'إخفاء كلمة المرور',
                          onPressed: _busy
                              ? null
                              : () => setState(() => _hide = !_hide),
                          icon: Icon(
                            _hide
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                          ),
                        ),
                      ),
                    ),
                    if (_register) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmation,
                        enabled: !_busy,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (v) => v == _password.text
                            ? null
                            : 'كلمتا المرور غير متطابقتين',
                        decoration: const InputDecoration(
                          hintText: 'تأكيد كلمة المرور',
                        ),
                      ),
                    ],
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_message!),
                        ),
                      ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _busy ? null : () => _submit(),
                      child: Text(
                        _busy
                            ? 'جارٍ التنفيذ…'
                            : _register
                            ? 'إنشاء الحساب'
                            : 'دخول',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _message = null;
                              _password.clear();
                              _confirmation.clear();
                            }),
                      child: Text(
                        _register
                            ? 'عندي حساب — تسجيل الدخول'
                            : 'ما عندك حساب؟ أنشئ حسابًا',
                      ),
                    ),
                    if (!_register)
                      TextButton(
                        onPressed: _busy ? null : () => _submit(reset: true),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    CupertinoButton(
                      onPressed: _busy ? null : widget.onGuest,
                      child: const Text('تصفح كضيف'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
