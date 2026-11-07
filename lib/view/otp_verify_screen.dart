import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/provider/auth_provider.dart';
import 'package:karaoke_app/service/provider_helper_class.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:provider/provider.dart';
import 'package:smart_auth/smart_auth.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String name;
  final String phone;

  const OtpVerifyScreen({
    super.key,
    required this.name,
    required this.phone,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen>
    with TickerProviderStateMixin {
  static const int _length = 6;
  static const int _resendSeconds = 30;

  final _focus = FocusNode();

  bool _error = false;
  int _seconds = _resendSeconds;
  Timer? _timer;

  late final AuthProvider _auth;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  void _onPinChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _auth.pinCodeController.addListener(_onPinChanged);
    _focus.addListener(() => setState(() {}));
    _startTimer();
    _listenForSms();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (defaultTargetPlatform == TargetPlatform.android) {
      SmartAuth.instance.removeUserConsentApiListener();
    }
    _auth.pinCodeController.removeListener(_onPinChanged);
    _auth.pinCodeController.clear();
    _focus.dispose();
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SMS autofill (Android). iOS is handled by AutofillHints.oneTimeCode.
  // ---------------------------------------------------------------------------
  Future<void> _listenForSms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (!mounted) return;
      if (res.hasData) {
        final match = RegExp(r'\d{6}').firstMatch(res.requireData.sms);
        if (match != null) _applyCode(match.group(0)!);
      }
    } catch (_) {
      // Play Services unavailable / user denied — manual entry still works.
    }
  }

  void _applyCode(String code) {
    _auth.pinCodeController.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _onChanged(code); // programmatic changes don't trigger onChanged
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onChanged(String value) {
    if (_error) setState(() => _error = false);
    if (value.length == _length) _verify();
  }

  void _verify() {
    if (_auth.loaderState == LoaderState.loading) return;
    final code = _auth.pinCodeController.text;
    if (code.length != _length) {
      _fail();
      return;
    }
    FocusScope.of(context).unfocus();

    _auth.verifyOtp(
      onSuccess: () {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      },
      // onError: (message) => _fail(),
    );
  }

  void _fail() {
    HapticFeedback.lightImpact();
    setState(() => _error = true);
    _shake.forward(from: 0);
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    _auth.pinCodeController.clear();
    setState(() => _error = false);
    _startTimer();
    _focus.requestFocus();

    // Restart SMS listener for the new OTP.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await SmartAuth.instance.removeUserConsentApiListener();
    }
    _listenForSms();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: SwaramColors.card,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'A new OTP has been sent.',
            style: TextStyle(color: SwaramColors.text),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isLoading = authProvider.loaderState == LoaderState.loading;
          final text = authProvider.pinCodeController.text;
          final activeIndex = math.min(text.length, _length - 1);
          return SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _focus.requestFocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlide(
                      controller: _enter,
                      begin: 0.0,
                      end: 0.4,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: SwaramColors.text,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.05,
                      end: 0.45,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: SwaramColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: SwaramColors.border),
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          color: SwaramColors.amber,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.15,
                      end: 0.5,
                      child: const Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: SwaramColors.text,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.2,
                      end: 0.55,
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Hi ${widget.name}, enter the 6-digit code sent to ',
                          style: const TextStyle(
                            color: SwaramColors.muted,
                            fontSize: 15,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: '+91 ${widget.phone}',
                              style: const TextStyle(
                                color: SwaramColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.3,
                      end: 0.65,
                      child: AnimatedBuilder(
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
                        child: AutofillGroup(
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(_length, (i) {
                                  final char = i < text.length ? text[i] : '';
                                  final isActive = _focus.hasFocus &&
                                      i == activeIndex &&
                                      !isLoading;
                                  final borderColor = _error
                                      ? SwaramColors.pink
                                      : isActive
                                          ? SwaramColors.amber
                                          : SwaramColors.border;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 48,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: SwaramColors.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: borderColor,
                                        width: isActive || _error ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      char,
                                      style: const TextStyle(
                                        color: SwaramColors.text,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              // Invisible field that captures typing / iOS autofill.
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    controller: authProvider.pinCodeController,
                                    focusNode: _focus,
                                    autofocus: true,
                                    enabled: !isLoading,
                                    keyboardType: TextInputType.number,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode
                                    ],
                                    enableInteractiveSelection: false,
                                    showCursor: false,
                                    onChanged: _onChanged,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(_length),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _error
                          ? const Padding(
                              padding: EdgeInsets.only(top: 12, left: 4),
                              child: Text(
                                'Enter the complete 6-digit code',
                                style: TextStyle(
                                  color: SwaramColors.pink,
                                  fontSize: 12.5,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 28),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.5,
                      end: 0.85,
                      child: PressScale(
                        onTap: isLoading ? null : _verify,
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
                                    'Verify',
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
                    const SizedBox(height: 24),
                    FadeSlide(
                      controller: _enter,
                      begin: 0.6,
                      end: 0.95,
                      child: Center(
                        child: _seconds > 0
                            ? Text(
                                'Resend OTP in 0:${_seconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: SwaramColors.muted,
                                  fontSize: 15,
                                ),
                              )
                            : GestureDetector(
                                onTap: _resend,
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Didn\'t get the code?  ',
                                    style: TextStyle(
                                      color: SwaramColors.muted,
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Resend',
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
          );
        },
      ),
    );
  }
}