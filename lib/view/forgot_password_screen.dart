import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/auth_widgets.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';

/// Three steps on one screen:
///   0  enter email or phone  ->  1  enter code + new password  ->  2  done
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  static const int _resendSeconds = 30;

  final _idForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _prefilled = false;
  int _resendIn = 0;
  Timer? _timer;

  /// Set when the server says the code is wrong or expired.
  String? _codeError;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Login can pass what the user already typed:
    // Navigator.pushNamed(context, '/forgot-password', arguments: text)
    if (_prefilled) return;
    _prefilled = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _idController.text = args.trim();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---------- validation ----------

  String? _validateId(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email or phone number';
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    final digits = s.replaceAll(RegExp(r'[\s\-+]'), '');
    final isPhone = RegExp(r'^\d{10,13}$').hasMatch(digits);
    if (!isEmail && !isPhone) return 'Enter a valid email or phone number';
    return null;
  }

  String? _validateCode(String? v) {
    final s = (v ?? '').trim();
    if (s.length != 6) return 'Enter the 6-digit code';
    return _codeError;
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Create a new password';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Use both letters and numbers';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) return 'Confirm your new password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ---------- actions ----------

  void _fail() {
    HapticFeedback.lightImpact();
    _shake.forward(from: 0);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: SwaramColors.card,
          behavior: SnackBarBehavior.floating,
          content:
              Text(message, style: const TextStyle(color: SwaramColors.text)),
        ),
      );
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    if (!resend && !_idForm.currentState!.validate()) {
      _fail();
      return;
    }

    setState(() => _loading = true);

    // TODO: POST /auth/password/forgot  { "identifier": _idController.text.trim() }
    // The server always answers 202, so this step never says whether the
    // account exists.
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _loading = false;
      _step = 1;
    });
    _startResendTimer();
    if (resend) _toast('Code sent again.');
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _codeError = null);
    if (!_resetForm.currentState!.validate()) {
      _fail();
      return;
    }

    setState(() => _loading = true);

    // TODO: POST /auth/password/reset
    //   { "identifier": ..., "code": _codeController.text, "newPassword": ... }
    // If the server says the code is wrong or expired:
    //   setState(() { _loading = false; _codeError = 'That code is wrong or has expired'; });
    //   _resetForm.currentState!.validate();
    //   _fail();
    //   return;
    // Any 6-digit code is accepted until the API is connected.
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _loading = false;
      _step = 2;
    });
  }

  String get _masked {
    final s = _idController.text.trim();
    if (s.contains('@')) {
      final parts = s.split('@');
      final first = parts.first.isEmpty ? '' : parts.first[0];
      return '$first***@${parts.last}';
    }
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length <= 4
        ? s
        : '******${digits.substring(digits.length - 4)}';
  }

  void _back() {
    if (_step == 1) {
      _timer?.cancel();
      setState(() {
        _step = 0;
        _codeError = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ---------- build ----------

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
                if (_step < 2)
                  Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.chevron_left,
                            color: SwaramColors.text, size: 32),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: _buildStepBar()),
                      const SizedBox(width: 12),
                    ],
                  )
                else
                  const SizedBox(height: 48),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _step == 0
                        ? _buildIdStep()
                        : (_step == 1 ? _buildResetStep() : _buildDoneStep()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBar() {
    return Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 5,
              margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
              decoration: BoxDecoration(
                color: i <= _step ? SwaramColors.amber : SwaramColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _shaking(Widget child) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, c) {
        final dx =
            math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: c);
      },
      child: child,
    );
  }

  Widget _buildIdStep() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: PulsingBadge(icon: Icons.lock_reset_rounded)),
          const SizedBox(height: 8),
          const Text(
            'Forgot password?',
            style: TextStyle(
              color: SwaramColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email or phone number and we will send you a reset code.',
            style: TextStyle(
              color: SwaramColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          _shaking(
            Form(
              key: _idForm,
              child: AuthField(
                label: 'Email or phone number',
                hint: 'you@example.com',
                controller: _idController,
                validator: _validateId,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendCode(),
              ),
            ),
          ),
          const SizedBox(height: 22),
          AuthButton(
            label: 'Send reset code',
            loading: _loading,
            onTap: _sendCode,
          ),
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to sign in',
                style: TextStyle(
                  color: SwaramColors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset password',
            style: TextStyle(
              color: SwaramColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the code we sent to $_masked, then choose a new password.',
            style: const TextStyle(
              color: SwaramColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          _shaking(
            Form(
              key: _resetForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthField(
                    label: 'Reset code',
                    hint: '------',
                    controller: _codeController,
                    validator: _validateCode,
                    centered: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _codeError = null,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    label: 'New password',
                    hint: 'At least 8 characters',
                    controller: _passwordController,
                    validator: _validatePassword,
                    obscure: _obscure,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: SwaramColors.muted,
                        size: 22,
                      ),
                    ),
                  ),
                  PasswordStrengthBar(password: _passwordController.text),
                  const SizedBox(height: 16),
                  AuthField(
                    label: 'Confirm new password',
                    hint: 'Enter it again',
                    controller: _confirmController,
                    validator: _validateConfirm,
                    obscure: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _resetPassword(),
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: SwaramColors.muted,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          AuthButton(
            label: 'Reset password',
            loading: _loading,
            onTap: _resetPassword,
          ),
          const SizedBox(height: 14),
          Center(
            child: _resendIn > 0
                ? Text(
                    'Resend code in ${_resendIn}s',
                    style: const TextStyle(
                        color: SwaramColors.muted, fontSize: 14.5),
                  )
                : GestureDetector(
                    onTap: _loading ? null : () => _sendCode(resend: true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Resend code',
                        style: TextStyle(
                          color: SwaramColors.amber,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 40),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v.clamp(0.0, 1.2), child: child),
            child: Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: SwaramColors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: SwaramColors.onAmber, size: 60),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Password updated',
            style: TextStyle(
              color: SwaramColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SwaramColors.muted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),
          AuthButton(
            label: 'Back to sign in',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}