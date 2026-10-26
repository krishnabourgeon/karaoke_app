import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';

OutlineInputBorder _authBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Label above a text field, in the Swaram style.
/// Used by the sign up and forgot password screens.
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  /// Big centred text, used for the reset code.
  final bool centered;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: SwaramColors.textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscure,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          maxLength: maxLength,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          cursorColor: SwaramColors.amber,
          style: TextStyle(
            color: SwaramColors.text,
            fontSize: centered ? 24 : 16,
            fontWeight: centered ? FontWeight.w800 : FontWeight.w400,
            letterSpacing: centered ? 10 : 0,
          ),
          buildCounter: (context,
                  {required currentLength, required isFocused, maxLength}) =>
              null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: SwaramColors.muted.withAlpha(150),
              fontSize: 16,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: SwaramColors.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            suffixIcon: suffix,
            border: _authBorder(SwaramColors.border),
            enabledBorder: _authBorder(SwaramColors.border),
            focusedBorder: _authBorder(SwaramColors.amber, 1.5),
            errorBorder: _authBorder(SwaramColors.pink),
            focusedErrorBorder: _authBorder(SwaramColors.pink, 1.5),
            errorStyle:
                const TextStyle(color: SwaramColors.pink, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

/// Full-width amber button with a loading spinner.
class AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: loading ? null : onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SwaramColors.amber,
          borderRadius: BorderRadius.circular(30),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: SwaramColors.onAmber,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    color: SwaramColors.onAmber,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Four bars and a word that show how strong a password is.
class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar({super.key, required this.password});

  int get _score {
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      s++;
    }
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _score;
    const colors = [
      SwaramColors.border,
      SwaramColors.pink,
      SwaramColors.amber,
      SwaramColors.teal,
      SwaramColors.teal,
    ];
    const labels = ['Too short', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = colors[score];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i < score ? color : SwaramColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 64,
            child: Text(
              labels[score],
              textAlign: TextAlign.right,
              style: TextStyle(
                color: score == 0 ? SwaramColors.muted : color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber circle with an icon and a ring that pulses outward.
class PulsingBadge extends StatefulWidget {
  final IconData icon;
  final double size;
  const PulsingBadge({super.key, required this.icon, this.size = 72});

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.7,
      height: s * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final d = s + s * 0.7 * t;
              return Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SwaramColors.amber.withAlpha(((1 - t) * 140).round()),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          Container(
            width: s,
            height: s,
            decoration: const BoxDecoration(
              color: SwaramColors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: SwaramColors.onAmber, size: s * 0.5),
          ),
        ],
      ),
    );
  }
}