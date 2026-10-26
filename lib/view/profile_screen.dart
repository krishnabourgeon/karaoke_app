import 'package:flutter/material.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'upload_screen.dart';

enum HistoryKind { upload, download }

class HistoryItem {
  final String title;
  final HistoryKind kind;
  final String when;
  final int points;

  const HistoryItem({
    required this.title,
    required this.kind,
    required this.when,
    required this.points,
  });

  bool get isUpload => kind == HistoryKind.upload;
}

const List<HistoryItem> kSampleHistory = [
  HistoryItem(
      title: 'Temple Bells at Dusk',
      kind: HistoryKind.upload,
      when: 'Today',
      points: 20),
  HistoryItem(
      title: 'Chai & Radio',
      kind: HistoryKind.download,
      when: 'Yesterday',
      points: 5),
  HistoryItem(
      title: 'Neon Highway',
      kind: HistoryKind.download,
      when: '19 Oct',
      points: 5),
  HistoryItem(
      title: 'Kayal Moonlight',
      kind: HistoryKind.upload,
      when: '17 Oct',
      points: 20),
  HistoryItem(
      title: 'Marina Sunrise',
      kind: HistoryKind.download,
      when: '15 Oct',
      points: 5),
];

class ProfileScreen extends StatefulWidget {
  final String name;
  final String username;
  final int points;
  final int earned;
  final int spent;
  final int uploadedCount;
  final int downloadedCount;
  final List<HistoryItem> history;

  const ProfileScreen({
    super.key,
    this.name = 'Arjun Nair',
    this.username = '@arjun_n',
    this.points = 85,
    this.earned = 160,
    this.spent = 75,
    this.uploadedCount = 8,
    this.downloadedCount = 15,
    this.history = kSampleHistory,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  static const _tabs = ['Points', 'Downloads', 'Uploads'];

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  List<HistoryItem> get _items {
    switch (_tab) {
      case 1:
        return widget.history.where((h) => !h.isUpload).toList();
      case 2:
        return widget.history.where((h) => h.isUpload).toList();
      default:
        return widget.history;
    }
  }

  void _back() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SwaramColors.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.chevron_left,
                        color: SwaramColors.text, size: 30),
                  ),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: SwaramColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [SwaramColors.pinkSoft, SwaramColors.pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Color(0xFF2A0A18),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SwaramColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: SwaramColors.muted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PointsCard(
                points: widget.points,
                earned: widget.earned,
                spent: widget.spent,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: widget.uploadedCount,
                      label: 'Karaoke uploaded',
                      sub: '20 pts each',
                      subColor: SwaramColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      value: widget.downloadedCount,
                      label: 'Karaoke downloaded',
                      sub: '5 pts each',
                      subColor: SwaramColors.pinkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: SwaramColors.card,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? SwaramColors.amber
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: selected
                                  ? SwaramColors.onAmber
                                  : SwaramColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey(_tab),
                  children: [
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Nothing here yet.',
                          style: TextStyle(color: SwaramColors.muted),
                        ),
                      ),
                    for (var i = 0; i < _items.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 300 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - v)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HistoryTile(item: _items[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SwaramBottomNav(
        current: SwaramTab.profile,
        onHome: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (r) => false),
        // onSearch: () => Navigator.of(context)
        //     .pushNamedAndRemoveUntil('/home', (r) => false),
        onSearch: () => Navigator.of(context).pushReplacementNamed('/search'),
        onUpload: () => Navigator.of(context).push(UploadScreen.route()),
        onLibrary: () => Navigator.of(context).pushReplacementNamed('/library'),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;
  final int earned;
  final int spent;

  const _PointsCard({
    required this.points,
    required this.earned,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: SwaramColors.cardHigh,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: -20,
              child: SwaramEqualizer(
                count: 6,
                minHeight: 20,
                maxHeight: 90,
                barWidth: 12,
                gap: 6,
                colorOf: (_) => const Color(0xFF4A3A7E),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Points available',
                  style: TextStyle(
                    color: SwaramColors.textSoft,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: points.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '${v.round()}',
                        style: const TextStyle(
                          color: SwaramColors.amber,
                          fontSize: 60,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'pts',
                      style: TextStyle(
                        color: SwaramColors.textSoft,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.arrow_upward,
                      text: '+$earned earned',
                      color: SwaramColors.teal,
                    ),
                    _Pill(
                      icon: Icons.arrow_downward,
                      text: '\u2212$spent spent',
                      color: SwaramColors.pinkSoft,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SwaramColors.bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final String sub;
  final Color subColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.sub,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: const TextStyle(
                color: SwaramColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: SwaramColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: subColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isUpload ? SwaramColors.teal : SwaramColors.pinkSoft;
    final amount = item.isUpload ? '+${item.points}' : '\u2212${item.points}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SwaramColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              item.isUpload ? Icons.arrow_upward : Icons.arrow_downward,
              color: SwaramColors.onAmber,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SwaramColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.isUpload ? 'Uploaded' : 'Downloaded'} · ${item.when}',
                  style: const TextStyle(
                    color: SwaramColors.muted,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}