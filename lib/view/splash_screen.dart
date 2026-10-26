import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _goLogin() => Navigator.of(context).pushNamed('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final vinylSize = math.min(constraints.maxWidth - 48, 300.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlide(
                    controller: _enter,
                    begin: 0.0,
                    end: 0.3,
                    dy: -0.3,
                    child: const _LogoRow(),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _enter,
                          curve: const Interval(0.05, 0.55,
                              curve: Curves.easeOutBack),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _enter,
                          curve: const Interval(0.05, 0.4),
                        ),
                        child: _Vinyl(
                          size: vinylSize,
                          spin: _spin,
                          pulse: _pulse,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: FadeSlide(
                      controller: _enter,
                      begin: 0.3,
                      end: 0.55,
                      child: SwaramEqualizer(
                        count: 9,
                        minHeight: 14,
                        maxHeight: 44,
                        barWidth: 12,
                        gap: 10,
                        colorOf: (i) => i.isEven
                            ? SwaramColors.amber
                            : SwaramColors.pink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.4,
                    end: 0.65,
                    child: const Text(
                      'Every karaoke.\nEvery language.',
                      style: TextStyle(
                        color: SwaramColors.text,
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.48,
                    end: 0.72,
                    child: const Text(
                      'Swaram is a shared library of karaoke tracks. Share yours to earn points, spend points to take the ones you love.',
                      style: TextStyle(
                        color: SwaramColors.textSoft,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FadeSlide(
                          controller: _enter,
                          begin: 0.55,
                          end: 0.8,
                          child: const _FeatureCard(
                            icon: Icons.search,
                            color: SwaramColors.amber,
                            label: 'Browse any\nlanguage',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FadeSlide(
                          controller: _enter,
                          begin: 0.62,
                          end: 0.87,
                          child: const _FeatureCard(
                            icon: Icons.file_upload_outlined,
                            color: SwaramColors.pink,
                            label: 'Upload to earn\npoints',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FadeSlide(
                          controller: _enter,
                          begin: 0.69,
                          end: 0.94,
                          child: const _FeatureCard(
                            icon: Icons.file_download_outlined,
                            color: SwaramColors.teal,
                            label: 'Download with\npoints',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FadeSlide(
                    controller: _enter,
                    begin: 0.75,
                    end: 1.0,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final glow =
                            0.5 + 0.5 * math.sin(_pulse.value * 2 * math.pi);
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: SwaramColors.amber
                                    .withAlpha((40 + 60 * glow).round()),
                                blurRadius: 14 + 14 * glow,
                                spreadRadius: 1 + 2 * glow,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: PressScale(
                        onTap: _goLogin,
                        child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: SwaramColors.amber,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Text(
                            'Get started',
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
                  FadeSlide(
                    controller: _enter,
                    begin: 0.82,
                    end: 1.0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _goLogin,
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already singing with us?  ',
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
            );
          },
        ),
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  const _LogoRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: SwaramColors.amber,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.music_note,
              color: SwaramColors.onAmber, size: 26),
        ),
        const SizedBox(width: 14),
        const Text(
          'Swaram',
          style: TextStyle(
            color: SwaramColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SwaramColors.text,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vinyl extends StatelessWidget {
  final double size;
  final Animation<double> spin;
  final Animation<double> pulse;

  const _Vinyl({
    required this.size,
    required this.spin,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingsPainter(pulse.value),
            ),
          ),
          RotationTransition(
            turns: spin,
            child: CustomPaint(
              size: Size.square(size),
              painter: _DiscPainter(),
            ),
          ),
          Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: const BoxDecoration(
              color: SwaramColors.amber,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note,
              color: SwaramColors.onAmber,
              size: size * 0.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width;

    canvas.drawCircle(
      c,
      s / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = SwaramColors.pink,
    );
    canvas.drawCircle(
      c,
      s * 0.43,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SwaramColors.pink.withAlpha(70),
    );

    for (var k = 0; k < 2; k++) {
      final phase = (t + k * 0.5) % 1.0;
      canvas.drawCircle(
        c,
        s * (0.36 + 0.13 * phase),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SwaramColors.pink.withAlpha(((1 - phase) * 120).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.t != t;
}

class _DiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.345;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0616));

    for (final f in [0.92, 0.76, 0.6, 0.46]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = SwaramColors.border,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi / 4,
      true,
      Paint()..color = Colors.white.withAlpha(16),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}