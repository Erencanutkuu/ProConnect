import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'constants.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  runApp(const ProConnectApp());
}

bool get _isDesktop {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.macOS ||
         defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux;
}

class ProConnectApp extends StatelessWidget {
  const ProConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'ProConnect',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: ApiService.isLoggedIn ? const MainShell() : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainShell());
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                partnerId: args['partnerId'] as int,
                partnerAd: args['partnerAd'] as String,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );

    // Masaüstü/web'de telefon çerçevesi ile göster
    if (_isDesktop) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1a1a2e),
          body: Center(
            child: Container(
              width: 390,
              height: 844,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.grey.shade800, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: app,
              ),
            ),
          ),
        ),
      );
    }

    return app;
  }
}

/// Bottom Navigation Shell
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _okunmamis = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      const MessagesScreen(),
      ProfileScreen(key: _profileKey),
    ];
    _badgeGuncelle();
  }

  Future<void> _badgeGuncelle() async {
    if (!ApiService.isLoggedIn) return;
    try {
      final sayi = await ApiService.okunmamisSayisi();
      if (mounted) setState(() { _okunmamis = sayi; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() { _currentIndex = i; });
          if (i == 0) _homeKey.currentState?.refresh();
          if (i == 1) _badgeGuncelle();
          if (i == 2) _profileKey.currentState?.refresh();
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _okunmamis > 0,
              label: Text('$_okunmamis', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Mesajlar',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
