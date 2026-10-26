import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:karaoke_app/view/common_widgets/swaram_common.dart';
import 'package:karaoke_app/view/common_widgets/swaram_player.dart';
import 'package:karaoke_app/view/dashboard_screen.dart';
import 'package:karaoke_app/view/library_screen.dart';
import 'package:karaoke_app/view/library_store.dart';
import 'package:karaoke_app/view/login_screen.dart';
import 'package:karaoke_app/view/profile_screen.dart';
import 'package:karaoke_app/view/search_screen.dart';
import 'package:karaoke_app/view/splash_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yourcompany.swaram.audio',
    androidNotificationChannelName: 'Swaram playback',
    androidNotificationOngoing: true,
  );
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await LibraryStore.instance.init();
  await FavoritesStore.instance.init();
  runApp(const SwaramApp());
}

class SwaramApp extends StatelessWidget {
  const SwaramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swaram',
      debugShowCheckedModeBanner: false,
      theme: buildSwaramTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          '/login' => const LoginScreen(),
          '/home' => const DashboardScreen(),
          '/search' => const SearchScreen(),
          '/profile' => const ProfileScreen(),
          '/library' => const LibraryScreen(),
          _ => const SplashScreen(),
        };

        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}