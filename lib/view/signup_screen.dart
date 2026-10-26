import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/auth_widgets.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _termsError = false;
  bool _loading = false;
  bool _autoValidate = false;

  /// Errors sent back by the server, keyed by field name
  /// (for example 'email': 'This email is already registered').
  final Map<String, String> _serverErrors = {};

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---------- validation ----------

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your name';
    if (s.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateUsername(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Choose a username';
    if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(s)) {
      return '3 to 20 letters, numbers, dots or underscores';
    }
    return _serverErrors['username'];
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email';
    }
    return _serverErrors['email'];
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return _serverErrors['phone']; // phone is optional
    final digits = s.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^\d{10,13}$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return _serverErrors['phone'];
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Create a password';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Use both letters and numbers';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) return 'Confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _clearServerError(String field) => _serverErrors.remove(field);

  // ---------- actions ----------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _serverErrors.clear();

    final valid = _formKey.currentState!.validate();
    setState(() {
      _autoValidate = true;
      _termsError = !_agreed;
    });
    if (!valid || !_agreed) {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
      return;
    }

    setState(() => _loading = true);

    // TODO: replace with your API call (POST /auth/register).
    //
    // try {
    //   await AuthRepository().register(
    //     name: _nameController.text.trim(),
    //     username: _usernameController.text.trim(),
    //     email: _emailController.text.trim(),
    //     phone: _phoneController.text.trim().isEmpty
    //         ? null
    //         : _phoneController.text.trim(),
    //     password: _passwordController.text,
    //   );
    // } on ApiException catch (e) {
    //   // 409 ALREADY_EXISTS names the clashing field in details.fields
    //   final fields = (e.details['fields'] as Map<String, dynamic>?) ?? {};
    //   setState(() {
    //     fields.forEach((k, v) => _serverErrors[k] = '$v');
    //     _loading = false;
    //   });
    //   _formKey.currentState!.validate();
    //   _shake.forward(from: 0);
    //   return;
    // }
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Widget _stagger(double begin, Widget child) {
    return FadeSlide(
      controller: _enter,
      begin: begin,
      end: math.min(begin + 0.3, 1.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left,
                        color: SwaramColors.text, size: 32),
                  ),
                ),
                const SizedBox(height: 4),
                _stagger(
                  0.0,
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      color: SwaramColors.text,
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _stagger(
                  0.05,
                  const Text(
                    'Share karaoke, earn points and sing along.',
                    style: TextStyle(
                      color: SwaramColors.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (context, child) {
                    final dx = math.sin(_shake.value * math.pi * 6) *
                        10 *
                        (1 - _shake.value);
                    return Transform.translate(
                        offset: Offset(dx, 0), child: child);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: _formKey,
                        autovalidateMode: _autoValidate
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stagger(
                              0.15,
                              AuthField(
                                label: 'Full name',
                                hint: 'Arjun Nair',
                                controller: _nameController,
                                validator: _validateName,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _stagger(
                              0.2,
                              AuthField(
                                label: 'Username',
                                hint: 'arjun_n',
                                controller: _usernameController,
                                validator: _validateUsername,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _clearServerError('username'),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9_.]')),
                                  LengthLimitingTextInputFormatter(20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _stagger(
                              0.25,
                              AuthField(
                                label: 'Email',
                                hint: 'you@example.com',
                                controller: _emailController,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                onChanged: (_) => _clearServerError('email'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _stagger(
                              0.3,
                              AuthField(
                                label: 'Phone number (optional)',
                                hint: '+91 98765 43210',
                                controller: _phoneController,
                                validator: _validatePhone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                onChanged: (_) => _clearServerError('phone'),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+\- ]')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _stagger(
                              0.35,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AuthField(
                                    label: 'Password',
                                    hint: 'At least 8 characters',
                                    controller: _passwordController,
                                    validator: _validatePassword,
                                    obscure: _obscure,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => setState(() {}),
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: SwaramColors.muted,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  PasswordStrengthBar(
                                      password: _passwordController.text),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _stagger(
                              0.4,
                              AuthField(
                                label: 'Confirm password',
                                hint: 'Enter it again',
                                controller: _confirmController,
                                validator: _validateConfirm,
                                obscure: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                suffix: IconButton(
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: SwaramColors.muted,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _stagger(0.5, _buildTerms()),
                      const SizedBox(height: 22),
                      _stagger(
                        0.58,
                        AuthButton(
                          label: 'Create account',
                          loading: _loading,
                          onTap: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _stagger(
                  0.7,
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Already have an account?  ',
                          style: TextStyle(
                            color: SwaramColors.muted,
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: SwaramColors.amber,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _agreed = !_agreed;
            if (_agreed) _termsError = false;
          }),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _agreed ? SwaramColors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _agreed
                        ? SwaramColors.amber
                        : (_termsError
                            ? SwaramColors.pink
                            : SwaramColors.border),
                    width: 1.5,
                  ),
                ),
                child: _agreed
                    ? const Icon(Icons.check_rounded,
                        color: SwaramColors.onAmber, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              // TODO: open your Terms and Privacy pages from these two words.
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: SwaramColors.muted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: SwaramColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: SwaramColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_termsError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 36),
            child: Text(
              'Please accept to continue',
              style: TextStyle(color: SwaramColors.pink, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}