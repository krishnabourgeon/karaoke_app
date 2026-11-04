import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/provider/auth_provider.dart';
import 'package:karaoke_app/service/provider_helper_class.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:provider/provider.dart';
import 'otp_verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // final _nameController = TextEditingController();
  // final _phoneController = TextEditingController();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final AnimationController _micPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    // _nameController.dispose();
    // _phoneController.dispose();
    _enter.dispose();
    _shake.dispose();
    _micPulse.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your name';
    if (s.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^\d{10}$').hasMatch(s)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  void _onSendOtp(AuthProvider authProvider) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
      return;
    }
    authProvider.sendOtp(
      onSuccess: () {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerifyScreen(
              name: authProvider.nameController.text.trim(),
              phone: authProvider.phoneController.text.trim(),
            ),
          ),
        );
      },
      // onFailure: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.message))),
    );
  }

  // Future<void> _sendOtp() async {
  //   FocusScope.of(context).unfocus();
  //   if (!_formKey.currentState!.validate()) {
  //     HapticFeedback.lightImpact();
  //     _shake.forward(from: 0);
  //     return;
  //   }
  //   setState(() => _loading = true);

  //   // context.read<AuthProvider>().sendOtp(
  //   //   phone: _phoneController.text.trim(),
      
  //   // )
  //   await Future.delayed(const Duration(milliseconds: 1000));

  //   if (!mounted) return;
  //   setState(() => _loading = false);
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (_) => OtpVerifyScreen(
  //         name: _nameController.text.trim(),
  //         phone: _phoneController.text.trim(),
  //       ),
  //     ),
  //   );
  // }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _decoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: SwaramColors.muted.withAlpha(150)),
      filled: true,
      fillColor: SwaramColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: prefix,
      border: _border(SwaramColors.border),
      enabledBorder: _border(SwaramColors.border),
      focusedBorder: _border(SwaramColors.amber, 1.5),
      errorBorder: _border(SwaramColors.pink),
      focusedErrorBorder: _border(SwaramColors.pink, 1.5),
      errorStyle: const TextStyle(color: SwaramColors.pink, fontSize: 12.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isLoading = authProvider.loaderState == LoaderState.loading;

          return SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlide(
                      controller: _enter,
                      begin: 0.0,
                      end: 0.4,
                      dy: -0.15,
                      child: _buildBanner(),
                    ),
                    const SizedBox(height: 26),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.2,
                      end: 0.5,
                      child: const Text(
                        'Welcome',
                        style: TextStyle(
                          color: SwaramColors.text,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.25,
                      end: 0.55,
                      child: const Text(
                        'Enter your name and phone number. We\'ll send you an OTP to verify.',
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
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlide(
                              controller: _enter,
                              begin: 0.35,
                              end: 0.65,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Name'),
                                  TextFormField(
                                    controller: authProvider.nameController,
                                    validator: _validateName,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.name,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    cursorColor: SwaramColors.amber,
                                    style: const TextStyle(
                                      color: SwaramColors.text,
                                      fontSize: 16,
                                    ),
                                    decoration: _decoration('Your name'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeSlide(
                              controller: _enter,
                              begin: 0.42,
                              end: 0.72,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Phone number'),
                                  TextFormField(
                                    controller: authProvider.phoneController,
                                    validator: _validatePhone,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!isLoading) _onSendOtp(authProvider);
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    cursorColor: SwaramColors.amber,
                                    style: const TextStyle(
                                      color: SwaramColors.text,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: _decoration(
                                      '98765 43210',
                                      prefix: const Padding(
                                        padding: EdgeInsets.only(left: 20, right: 10),
                                        child: Center(
                                          widthFactor: 1,
                                          child: Text(
                                            '+91',
                                            style: TextStyle(
                                              color: SwaramColors.textSoft,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.55,
                      end: 0.85,
                      child: PressScale(
                        onTap: isLoading ? null : () => _onSendOtp(authProvider),
                        child: Container(
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: SwaramColors.amber,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isLoading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: SwaramColors.onAmber,
                                    ),
                                  )
                                : const Text(
                                    'Send OTP',
                                    key: ValueKey('label'),
                                    style: TextStyle(
                                      color: SwaramColors.onAmber,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // FadeSlide(
                    //   controller: _enter,
                    //   begin: 0.68,
                    //   end: 0.95,
                    //   child: PressScale(
                    //     onTap: () {},
                    //     // _comingSoon('Phone OTP sign in is not set up yet.'),
                    //     child: Container(
                    //       height: 58,
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(30),
                    //         border: Border.all(color: SwaramColors.border),
                    //       ),
                    //       child: const Row(
                    //         mainAxisAlignment: MainAxisAlignment.center,
                    //         children: [
                    //           Icon(Icons.smartphone,
                    //               color: SwaramColors.text, size: 22),
                    //           SizedBox(width: 12),
                    //           Text(
                    //             'Continue with phone OTP',
                    //             style: TextStyle(
                    //               color: SwaramColors.text,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w700,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 28),
                    // FadeSlide(
                    //   controller: _enter,
                    //   begin: 0.78,
                    //   end: 1.0,
                    //   child: Center(
                    //     child: GestureDetector(
                    //       onTap: () {},
                    //          // _comingSoon('Account creation is not set up yet.'),
                    //       child: const Text.rich(
                    //         TextSpan(
                    //           text: 'New to Swaram?  ',
                    //           style: TextStyle(
                    //             color: SwaramColors.muted,
                    //             fontSize: 15,
                    //           ),
                    //           children: [
                    //             TextSpan(
                    //               text: 'Create an account',
                    //               style: TextStyle(
                    //                 color: SwaramColors.amber,
                    //                 fontWeight: FontWeight.w800,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 200,
        width: double.infinity,
        color: SwaramColors.card,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SwaramEqualizer(
                count: 11,
                minHeight: 20,
                maxHeight: 110,
                barWidth: 14,
                gap: 8,
                colorOf: (i) => i.isEven
                    ? const Color(0xFF3B2A63)
                    : const Color(0xFF2D2050),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _enter,
                    curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
                  ),
                ),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _micPulse,
                        builder: (context, _) {
                          final t = _micPulse.value;
                          final d = 82 + 54 * t;
                          return Container(
                            width: d,
                            height: d,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: SwaramColors.amber
                                    .withAlpha(((1 - t) * 140).round()),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          color: SwaramColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_none_rounded,
                          color: SwaramColors.onAmber,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: SwaramColors.textSoft,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}