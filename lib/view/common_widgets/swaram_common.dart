// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:karaoke_app/view/mini_player_bar.dart';

// class SwaramColors {
//   static const bg = Color(0xFF130C22);
//   static const card = Color(0xFF1E1536);
//   static const cardHigh = Color(0xFF2A1F4A);
//   static const border = Color(0xFF3A2C63);
//   static const amber = Color(0xFFFFB547);
//   static const pink = Color(0xFFFF5C93);
//   static const pinkSoft = Color(0xFFFF8FB5);
//   static const teal = Color(0xFF5EEAD4);
//   static const text = Color(0xFFF5F0FF);
//   static const textSoft = Color(0xFFD9D0F5);
//   static const muted = Color(0xFFB8AED6);
//   static const onAmber = Color(0xFF2A1A00);
// }

// ThemeData buildSwaramTheme() {
//   return ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: SwaramColors.bg,
//     colorScheme: const ColorScheme.dark(
//       primary: SwaramColors.amber,
//       secondary: SwaramColors.pink,
//       surface: SwaramColors.card,
//     ),
//     splashFactory: NoSplash.splashFactory,
//     highlightColor: Colors.transparent,
//   );
// }

// /// Fades and slides a child in while [controller] is between [begin] and [end].
// class FadeSlide extends StatelessWidget {
//   final Animation<double> controller;
//   final double begin;
//   final double end;
//   final double dy;
//   final Widget child;

//   const FadeSlide({
//     super.key,
//     required this.controller,
//     required this.begin,
//     required this.end,
//     required this.child,
//     this.dy = 0.18,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final curved = CurvedAnimation(
//       parent: controller,
//       curve: Interval(begin, end, curve: Curves.easeOutCubic),
//     );
//     return FadeTransition(
//       opacity: curved,
//       child: SlideTransition(
//         position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
//             .animate(curved),
//         child: child,
//       ),
//     );
//   }
// }

// /// Shrinks slightly while pressed. Calls [onTap] on release.
// class PressScale extends StatefulWidget {
//   final Widget child;
//   final VoidCallback? onTap;

//   const PressScale({super.key, required this.child, this.onTap});

//   @override
//   State<PressScale> createState() => _PressScaleState();
// }

// class _PressScaleState extends State<PressScale> {
//   bool _down = false;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTapDown: (_) => setState(() => _down = true),
//       onTapUp: (_) {
//         setState(() => _down = false);
//         widget.onTap?.call();
//       },
//       onTapCancel: () => setState(() => _down = false),
//       child: AnimatedScale(
//         scale: _down ? 0.97 : 1.0,
//         duration: const Duration(milliseconds: 90),
//         child: widget.child,
//       ),
//     );
//   }
// }

// /// Animated equalizer bars.
// class SwaramEqualizer extends StatefulWidget {
//   final int count;
//   final double minHeight;
//   final double maxHeight;
//   final double barWidth;
//   final double gap;
//   final Color Function(int index) colorOf;
//   final Duration period;

//   const SwaramEqualizer({
//     super.key,
//     required this.colorOf,
//     this.count = 9,
//     this.minHeight = 12,
//     this.maxHeight = 60,
//     this.barWidth = 12,
//     this.gap = 10,
//     this.period = const Duration(milliseconds: 1600),
//   });

//   @override
//   State<SwaramEqualizer> createState() => _SwaramEqualizerState();
// }

// class _SwaramEqualizerState extends State<SwaramEqualizer>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _c =
//       AnimationController(vsync: this, duration: widget.period)..repeat();

//   @override
//   void dispose() {
//     _c.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _c,
//       builder: (context, _) {
//         return SizedBox(
//           height: widget.maxHeight,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: List.generate(widget.count, (i) {
//               final phase = _c.value * 2 * math.pi + i * 0.9;
//               final f = 0.5 + 0.5 * math.sin(phase + math.sin(i * 1.7));
//               final h = widget.minHeight +
//                   (widget.maxHeight - widget.minHeight) * f;
//               return Padding(
//                 padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
//                 child: Container(
//                   width: widget.barWidth,
//                   height: h,
//                   decoration: BoxDecoration(
//                     color: widget.colorOf(i),
//                     borderRadius: BorderRadius.circular(widget.barWidth / 2),
//                   ),
//                 ),
//               );
//             }),
//           ),
//         );
//       },
//     );
//   }
// }

// enum SwaramTab { home, search, library, profile }

// class SwaramBottomNav extends StatelessWidget {
//   final SwaramTab current;
//   final VoidCallback? onHome;
//   final VoidCallback? onSearch;
//   final VoidCallback? onUpload;
//   final VoidCallback? onLibrary;
//   final VoidCallback? onProfile;

//   const SwaramBottomNav({
//     super.key,
//     required this.current,
//     this.onHome,
//     this.onSearch,
//     this.onUpload,
//     this.onLibrary,
//     this.onProfile,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bottomInset = MediaQuery.of(context).padding.bottom;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const MiniPlayerBar(),
//         Container(
//           height: 74 + bottomInset,
//           padding: EdgeInsets.only(bottom: bottomInset),
//           decoration: const BoxDecoration(
//             color: SwaramColors.card,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Stack(
//             clipBehavior: Clip.none,
//             alignment: Alignment.topCenter,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _NavItem(
//                       icon: Icons.home_outlined,
//                       label: 'Home',
//                       active: current == SwaramTab.home,
//                       onTap: onHome,
//                     ),
//                   ),
//                   Expanded(
//                     child: _NavItem(
//                       icon: Icons.search,
//                       label: 'Search',
//                       active: current == SwaramTab.search,
//                       onTap: onSearch,
//                     ),
//                   ),
//                   const Expanded(child: SizedBox()),
//                   Expanded(
//                     child: _NavItem(
//                       icon: Icons.notes,
//                       label: 'Library',
//                       active: current == SwaramTab.library,
//                       onTap: onLibrary,
//                     ),
//                   ),
//                   Expanded(
//                     child: _NavItem(
//                       icon: Icons.person_outline,
//                       label: 'Profile',
//                       active: current == SwaramTab.profile,
//                       onTap: onProfile,
//                     ),
//                   ),
//                 ],
//               ),
//               Positioned(
//                 top: -26,
//                 child: PressScale(
//                   onTap: onUpload,
//                   child: Container(
//                     width: 64,
//                     height: 64,
//                     decoration: BoxDecoration(
//                       color: SwaramColors.amber,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: SwaramColors.bg, width: 5),
//                     ),
//                     child: const Icon(
//                       Icons.add,
//                       color: SwaramColors.onAmber,
//                       size: 32,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool active;
//   final VoidCallback? onTap;

//   const _NavItem({
//     required this.icon,
//     required this.label,
//     required this.active,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = active ? SwaramColors.amber : SwaramColors.muted;
//     return GestureDetector(
//       behavior: HitTestBehavior.opaque,
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 26),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//               fontWeight: active ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karaoke_app/view/common_widgets/record_launcher.dart';

class SwaramColors {
  static const bg = Color(0xFF130C22);
  static const card = Color(0xFF1E1536);
  static const cardHigh = Color(0xFF2A1F4A);
  static const border = Color(0xFF3A2C63);
  static const amber = Color(0xFFFFB547);
  static const pink = Color(0xFFFF5C93);
  static const pinkSoft = Color(0xFFFF8FB5);
  static const teal = Color(0xFF5EEAD4);
  static const text = Color(0xFFF5F0FF);
  static const textSoft = Color(0xFFD9D0F5);
  static const muted = Color(0xFFB8AED6);
  static const onAmber = Color(0xFF2A1A00);
}

ThemeData buildSwaramTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SwaramColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: SwaramColors.amber,
      secondary: SwaramColors.pink,
      surface: SwaramColors.card,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

/// Fades and slides a child in while [controller] is between [begin] and [end].
class FadeSlide extends StatelessWidget {
  final Animation<double> controller;
  final double begin;
  final double end;
  final double dy;
  final Widget child;

  const FadeSlide({
    super.key,
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
    this.dy = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

/// Shrinks slightly while pressed. Calls [onTap] on release.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressScale({super.key, required this.child, this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// Animated equalizer bars.
class SwaramEqualizer extends StatefulWidget {
  final int count;
  final double minHeight;
  final double maxHeight;
  final double barWidth;
  final double gap;
  final Color Function(int index) colorOf;
  final Duration period;

  const SwaramEqualizer({
    super.key,
    required this.colorOf,
    this.count = 9,
    this.minHeight = 12,
    this.maxHeight = 60,
    this.barWidth = 12,
    this.gap = 10,
    this.period = const Duration(milliseconds: 1600),
  });

  @override
  State<SwaramEqualizer> createState() => _SwaramEqualizerState();
}

class _SwaramEqualizerState extends State<SwaramEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          height: widget.maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.count, (i) {
              final phase = _c.value * 2 * math.pi + i * 0.9;
              final f = 0.5 + 0.5 * math.sin(phase + math.sin(i * 1.7));
              final h = widget.minHeight +
                  (widget.maxHeight - widget.minHeight) * f;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
                child: Container(
                  width: widget.barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: widget.colorOf(i),
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

enum SwaramTab { home, search, library, profile }

/// Bottom navigation with a centre + button.
/// Tapping + dims the screen and pops out two buttons: Upload and Record.
///
///  - Upload calls [onUpload], or opens the '/upload' route.
///  - Record calls [onRecord], or opens the '/record' route.
class SwaramBottomNav extends StatefulWidget {
  final SwaramTab current;
  final VoidCallback? onHome;
  final VoidCallback? onSearch;
  final VoidCallback? onUpload;
  final VoidCallback? onRecord;
  final VoidCallback? onLibrary;
  final VoidCallback? onProfile;

  const SwaramBottomNav({
    super.key,
    required this.current,
    this.onHome,
    this.onSearch,
    this.onUpload,
    this.onRecord,
    this.onLibrary,
    this.onProfile,
  });

  @override
  State<SwaramBottomNav> createState() => _SwaramBottomNavState();
}

class _SwaramBottomNavState extends State<SwaramBottomNav>
    with SingleTickerProviderStateMixin {
  final GlobalKey _plusKey = GlobalKey();

  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scrim =
      CurvedAnimation(parent: _menu, curve: Curves.easeOut);

  // The two buttons pop out one after the other, with a small overshoot.
  late final Animation<double> _first = CurvedAnimation(
    parent: _menu,
    curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _second = CurvedAnimation(
    parent: _menu,
    curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );

  OverlayEntry? _entry;

  @override
  void dispose() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _menu.dispose();
    super.dispose();
  }

  void _toggle() => _entry == null ? _open() : _close();

  void _open() {
    final box = _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));

    HapticFeedback.selectionClick();
    _entry = OverlayEntry(builder: (_) => _buildMenu(center));
    // The root overlay sits above everything, including the nav bar.
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _menu.forward();
  }

  /// Plays the closing animation, then removes the menu.
  Future<void> _close() async {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    await _menu.reverse();
    entry.remove();
    entry.dispose();
  }

  Future<void> _choose(VoidCallback action) async {
    // Remove the menu first so it never stays on top of the next screen.
    await _close();
    if (mounted) action();
  }

  void _defaultRoute(String name) => Navigator.of(context).pushNamed(name);

  Widget _buildMenu(Offset c) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _menu,
        builder: (context, _) {
          final s = _scrim.value;
          return Stack(
            children: [
              // Dark background. Tap it to close.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: ColoredBox(
                    color: Colors.black.withAlpha((175 * s).round()),
                  ),
                ),
              ),
              _action(
                center: c,
                t: _first.value,
                target: const Offset(-84, -108),
                icon: Icons.file_upload_outlined,
                label: 'Upload',
                color: SwaramColors.pink,
                onTap: () => _choose(
                  widget.onUpload ?? () => _defaultRoute('/upload'),
                ),
              ),
              _action(
                center: c,
                t: _second.value,
                target: const Offset(84, -108),
                icon: Icons.mic_rounded,
                label: 'Record',
                color: SwaramColors.teal,
                onTap: () => _choose(
                  widget.onRecord ?? () => openRecordPicker(context),
                ),
              ),
              // The + button again, on top of the dark background,
              // turning into an X.
              Positioned(
                left: c.dx - 32,
                top: c.dy - 32,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: SwaramColors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: SwaramColors.bg, width: 5),
                    ),
                    child: Transform.rotate(
                      angle: s * math.pi / 4,
                      child: const Icon(Icons.add,
                          color: SwaramColors.onAmber, size: 32),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _action({
    required Offset center,
    required double t,
    required Offset target,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final pos = center + target * t;
    return Positioned(
      left: pos.dx - 40,
      top: pos.dy - 36,
      width: 80,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (0.4 + 0.6 * t).clamp(0.0, 1.25),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(90),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: SwaramColors.onAmber, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: SwaramColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 74 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  active: widget.current == SwaramTab.home,
                  onTap: widget.onHome,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  active: widget.current == SwaramTab.search,
                  onTap: widget.onSearch,
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: _NavItem(
                  icon: Icons.notes,
                  label: 'Library',
                  active: widget.current == SwaramTab.library,
                  onTap: widget.onLibrary,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  active: widget.current == SwaramTab.profile,
                  onTap: widget.onProfile,
                ),
              ),
            ],
          ),
          Positioned(
            top: -26,
            child: PressScale(
              onTap: _toggle,
              child: Container(
                key: _plusKey,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SwaramColors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: SwaramColors.bg, width: 5),
                ),
                child: const Icon(
                  Icons.add,
                  color: SwaramColors.onAmber,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? SwaramColors.amber : SwaramColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}