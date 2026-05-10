import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

// ─────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const UVDSApp());
}

// ─────────────────────────────────────────
// THEME PROVIDER (Dark mode)
// ─────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

// ─────────────────────────────────────────
// COULEURS UVDS
// ─────────────────────────────────────────
class UVDSColors {
  static const primary = Color(0xFF1E7A3C);
  static const primaryDark = Color(0xFF145228);
  static const greenLeaf = Color(0xFF4CAF50);
  static const accent = Color(0xFF2E8B57);
  static const light = Color(0xFFF7FAF7);
  static const darkBg = Color(0xFF121212);
  static const darkCard = Color(0xFF1E1E1E);
  static const darkSurface = Color(0xFF2C2C2C);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6B7C6B);
  static const border = Color(0xFFDEEADE);
}

// ─────────────────────────────────────────
// FIREBASE INSTANCES
// ─────────────────────────────────────────
final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;
final _picker = ImagePicker();

// Helper upload image
Future<String?> uploadImage(File file, String path) async {
  try {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  } catch (_) {
    return null;
  }
}

// ═════════════════════════════════════════
// APP ROOT — Dark Mode + Auth Gate
// ═════════════════════════════════════════
class UVDSApp extends StatefulWidget {
  const UVDSApp({super.key});
  @override
  State<UVDSApp> createState() => _UVDSAppState();
}

class _UVDSAppState extends State<UVDSApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  ThemeData _buildTheme(bool dark) {
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: UVDSColors.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: dark ? UVDSColors.darkBg : UVDSColors.light,
      cardColor: dark ? UVDSColors.darkCard : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? UVDSColors.darkCard : UVDSColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UVDSColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? UVDSColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UVDSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UVDSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UVDSColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UVDS',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(false),
      darkTheme: _buildTheme(true),
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const SplashScreen();
          if (snapshot.hasData) return const MainShell();
          return const LoginScreen();
        },
      ),
    );
  }
}

// ═════════════════════════════════════════
// SPLASH
// ═════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UVDSColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_uvds.png',
                  width: 180,
                  height: 180,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.balance, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'ENSEMBLE POUR UN AVENIR MEILLEUR',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Unité  •  Volonté  •  Développement  •  Solidarité',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white.withValues(alpha: 0.6),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════
// LOGIN
// ═════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true, _loading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      _snack('Champs obligatoires');
      return;
    }
    final conn = await Connectivity().checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      _snack('Pas de connexion');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _snack(_err(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: UVDSColors.primaryDark),
  );
  String _err(String c) {
    switch (c) {
      case 'user-not-found':
        return 'Aucun compte.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      default:
        return 'Erreur de connexion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_uvds.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.balance,
                        size: 60,
                        color: UVDSColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bienvenue sur UVDS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Connecte-toi pour continuer',
                      style: TextStyle(
                        fontSize: 14,
                        color: UVDSColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'ton@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mot de passe',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Pas de compte ? ",
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                        color: UVDSColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════
// REGISTER
// ═════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Entre ton nom.');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _snack('Mot de passe min 6 car.');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': 'membre',
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await cred.user!.updateDisplayName(_nameCtrl.text.trim());
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Erreur');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nom complet',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ton nom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'ton@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mot de passe',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Minimum 6 caractères',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Créer mon compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════
// MAIN SHELL
// ═════════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    HomeScreen(),
    PostsScreen(),
    ProjectsScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: UVDSColors.primary),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article, color: UVDSColors.primary),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: UVDSColors.primary),
            label: 'Projets',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat, color: UVDSColors.primary),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: UVDSColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
// HOME SCREEN
// ═════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('UVDS'),
        actions: [
          // 🌙 Dark mode toggle
          AnimatedBuilder(
            animation: themeNotifier,
            builder: (_, __) => IconButton(
              icon: Icon(
                themeNotifier.isDark ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: themeNotifier.toggle,
            ),
          ),
          // 🔍 Recherche
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          // 🔔 Notifications
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('uid', isEqualTo: _auth.currentUser?.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (_, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bannière
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [UVDSColors.primary, Color(0xFF2E8B57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, ${user?.displayName ?? 'Membre'} 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ensemble pour un avenir meilleur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('users').snapshots(),
                      builder: (_, snap) => _StatChip(
                        icon: Icons.people,
                        label: '${snap.data?.docs.length ?? 0} membres',
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('projects').snapshots(),
                      builder: (_, snap) => _StatChip(
                        icon: Icons.folder,
                        label: '${snap.data?.docs.length ?? 0} projets',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 📊 Stats rapides
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Posts',
                  icon: Icons.article,
                  stream: _firestore.collection('posts').snapshots(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStat(
                  label: 'Messages',
                  icon: Icons.chat,
                  stream: _firestore.collection('chat').snapshots(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Boutons navigation rapide
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.people,
                  label: 'Membres',
                  color: UVDSColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.map,
                  label: 'Carte projets',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectsMapScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.bar_chart,
                  label: 'Statistiques',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Admin panel (si admin)
          FutureBuilder<DocumentSnapshot>(
            future: _firestore
                .collection('users')
                .doc(_auth.currentUser?.uid)
                .get(),
            builder: (_, snap) {
              final role =
                  (snap.data?.data() as Map<String, dynamic>?)?['role'] ?? '';
              if (role != 'admin') return const SizedBox();
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.orange),
                      SizedBox(width: 12),
                      Text(
                        'Panel Administrateur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Text(
            'Dernières publications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .orderBy('time', descending: true)
                .limit(3)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty)
                return const Center(
                  child: Text(
                    'Aucune publication.',
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                );
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _ActivityCard(
                    icon: Icons.article,
                    color: UVDSColors.primary,
                    title: data['user'] ?? 'Membre',
                    subtitle: data['text'] ?? '',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}

class _QuickStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  const _QuickStat({
    required this.label,
    required this.icon,
    required this.stream,
  });
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (_, snap) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: UVDSColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${snap.data?.docs.length ?? 0}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: UVDSColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle.length > 60 ? '${subtitle.substring(0, 60)}...' : subtitle,
        style: const TextStyle(fontSize: 12, color: UVDSColors.textGrey),
      ),
    ),
  );
}

// ═════════════════════════════════════════
// 🔍 SEARCH SCREEN
// ═════════════════════════════════════════
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'Membres';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['Membres', 'Posts', 'Projets']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _filter == f
                                ? UVDSColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : UVDSColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(
                    _filter == 'Membres'
                        ? 'users'
                        : _filter == 'Posts'
                        ? 'posts'
                        : 'projects',
                  )
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchIn = _filter == 'Membres'
                      ? '${data['name'] ?? ''} ${data['email'] ?? ''}'
                      : _filter == 'Posts'
                      ? '${data['text'] ?? ''} ${data['user'] ?? ''}'
                      : '${data['title'] ?? ''} ${data['desc'] ?? ''}';
                  return _query.isEmpty ||
                      searchIn.toLowerCase().contains(_query);
                }).toList();

                if (docs.isEmpty)
                  return const Center(
                    child: Text(
                      'Aucun résultat',
                      style: TextStyle(color: UVDSColors.textGrey),
                    ),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    if (_filter == 'Membres') {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            (data['name'] ?? 'M')[0].toUpperCase(),
                            style: const TextStyle(
                              color: UVDSColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Text(
                          data['role'] ?? '',
                          style: const TextStyle(
                            color: UVDSColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    } else if (_filter == 'Posts') {
                      return ListTile(
                        leading: const Icon(
                          Icons.article,
                          color: UVDSColors.primary,
                        ),
                        title: Text(data['user'] ?? ''),
                        subtitle: Text(
                          data['text'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    } else {
                      return ListTile(
                        leading: const Icon(
                          Icons.folder,
                          color: UVDSColors.primary,
                        ),
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(
                          data['desc'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          data['status'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
// POSTS SCREEN — avec images + share
// ═════════════════════════════════════════
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});
  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _textCtrl = TextEditingController();
  File? _selectedImage;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showAddPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouvelle publication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Quoi de neuf ?'),
              ),
              const SizedBox(height: 12),
              if (_selectedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.photo_library,
                      color: UVDSColors.primary,
                    ),
                    label: const Text(
                      'Photo',
                      style: TextStyle(color: UVDSColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: UVDSColors.primary),
                    ),
                    onPressed: () async {
                      await _pickImage();
                      setModal(() {});
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _uploading
                        ? null
                        : () async {
                            if (_textCtrl.text.trim().isEmpty &&
                                _selectedImage == null)
                              return;
                            setModal(() => _uploading = true);
                            String? imageUrl;
                            if (_selectedImage != null) {
                              imageUrl = await uploadImage(
                                _selectedImage!,
                                'posts/${DateTime.now().millisecondsSinceEpoch}.jpg',
                              );
                            }
                            await _firestore.collection('posts').add({
                              'text': _textCtrl.text.trim(),
                              'user':
                                  _auth.currentUser?.displayName ?? 'Membre',
                              'uid': _auth.currentUser?.uid,
                              'time': FieldValue.serverTimestamp(),
                              'likes': [],
                              'imageUrl': imageUrl ?? '',
                            });
                            _textCtrl.clear();
                            setState(() => _selectedImage = null);
                            setModal(() => _uploading = false);
                            if (mounted) Navigator.pop(context);
                          },
                    child: _uploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Publier'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: UVDSColors.primary,
        onPressed: _showAddPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: UVDSColors.textGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucune publication',
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                ],
              ),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) => _PostCard(doc: docs[i]),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _PostCard({required this.doc});

  Future<void> _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    likes.contains(user.uid) ? likes.remove(user.uid) : likes.add(user.uid);
    await _firestore.collection('posts').doc(doc.id).update({'likes': likes});
    if (!likes.contains(user.uid) && data['uid'] != user.uid) {
      await _firestore.collection('notifications').add({
        'uid': data['uid'],
        'message': '${user.displayName ?? 'Quelqu\'un'} a aimé ton post ❤️',
        'read': false,
        'time': FieldValue.serverTimestamp(),
      });
    }
  }

  // 📱 Partager le post
  void _sharePost(Map<String, dynamic> data) {
    final text = '${data['text'] ?? ''}\n\n— Partagé depuis UVDS 🌿';
    Share.share(text);
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '...';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour(s)';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = likes.contains(_auth.currentUser?.uid);
    final author = data['user'] ?? 'Membre';
    final imageUrl = data['imageUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    author[0].toUpperCase(),
                    style: const TextStyle(
                      color: UVDSColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _timeAgo(data['time'] as Timestamp?),
                      style: const TextStyle(
                        fontSize: 12,
                        color: UVDSColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if ((data['text'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(data['text']),
            ),
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : UVDSColors.textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${likes.length}',
                        style: const TextStyle(color: UVDSColors.textGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(
                        postId: doc.id,
                        postAuthorUid: data['uid'] ?? '',
                      ),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('posts')
                        .doc(doc.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (_, snap) => Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: UVDSColors.textGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${snap.data?.docs.length ?? 0}',
                          style: const TextStyle(color: UVDSColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 📱 Bouton partager
                GestureDetector(
                  onTap: () => _sharePost(data),
                  child: const Icon(
                    Icons.share_outlined,
                    color: UVDSColors.textGrey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
// COMMENTS SCREEN
// ═════════════════════════════════════════
class CommentsScreen extends StatefulWidget {
  final String postId, postAuthorUid;
  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postAuthorUid,
  });
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _ctrl = TextEditingController();

  Future<void> _add() async {
    if (_ctrl.text.trim().isEmpty) return;
    final user = _auth.currentUser;
    final text = _ctrl.text.trim();
    _ctrl.clear();
    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'text': text,
          'author': user?.displayName ?? 'Membre',
          'uid': user?.uid,
          'time': FieldValue.serverTimestamp(),
        });
    if (widget.postAuthorUid != user?.uid) {
      await _firestore.collection('notifications').add({
        'uid': widget.postAuthorUid,
        'message':
            '${user?.displayName ?? 'Quelqu\'un'} a commenté ton post 💬',
        'read': false,
        'time': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('time')
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty)
                  return const Center(
                    child: Text(
                      'Aucun commentaire. Sois le premier ! 💬',
                      style: TextStyle(color: UVDSColors.textGrey),
                    ),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: UVDSColors.primary.withValues(alpha: 
                              0.2,
                            ),
                            child: Text(
                              (d['author'] ?? 'M')[0].toUpperCase(),
                              style: const TextStyle(
                                color: UVDSColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['author'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(d['text'] ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Commenter...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: UVDSColors.light,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: UVDSColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
// PROJECTS SCREEN
// ═════════════════════════════════════════
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'En cours';
  double? _lat, _lng;

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouveau projet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Titre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: ['En cours', 'Planifié', 'Terminé']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setModal(() => _status = v!),
              ),
              const SizedBox(height: 12),
              // Géolocalisation
              OutlinedButton.icon(
                icon: Icon(
                  _lat != null ? Icons.location_on : Icons.location_off,
                  color: UVDSColors.primary,
                ),
                label: Text(
                  _lat != null
                      ? 'Position ajoutée ✅'
                      : 'Ajouter ma position 🌍',
                  style: const TextStyle(color: UVDSColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: UVDSColors.primary),
                ),
                onPressed: () async {
                  await _getLocation();
                  setModal(() {});
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_titleCtrl.text.trim().isEmpty) return;
                    await _firestore.collection('projects').add({
                      'title': _titleCtrl.text.trim(),
                      'desc': _descCtrl.text.trim(),
                      'status': _status,
                      'createdBy': _auth.currentUser?.displayName ?? 'Membre',
                      'uid': _auth.currentUser?.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                      'lat': _lat,
                      'lng': _lng,
                    });
                    _titleCtrl.clear();
                    _descCtrl.clear();
                    setState(() {
                      _lat = null;
                      _lng = null;
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Créer le projet'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'En cours':
        return UVDSColors.primary;
      case 'Planifié':
        return Colors.blue;
      case 'Terminé':
        return Colors.grey;
      default:
        return UVDSColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets ONG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsMapScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: UVDSColors.primary,
        onPressed: _showAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('projects')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: UVDSColors.textGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucun projet',
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                ],
              ),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'En cours';
              final color = _statusColor(status);
              final hasLocation = data['lat'] != null && data['lng'] != null;
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder, color: color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['desc'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: UVDSColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Par ${data['createdBy'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: UVDSColors.textGrey,
                                  ),
                                ),
                                if (hasLocation) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  const Text(
                                    'GPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════
// 🌍 CARTE DES PROJETS
// ═════════════════════════════════════════
class ProjectsMapScreen extends StatefulWidget {
  const ProjectsMapScreen({super.key});

  @override
  State<ProjectsMapScreen> createState() => _ProjectsMapScreenState();
}

class _ProjectsMapScreenState extends State<ProjectsMapScreen> {
  // ignore: unused_field
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final snap = await _firestore.collection('projects').get();

    final markers = <Marker>{};

    for (final doc in snap.docs) {
      final data = doc.data();

      if (data['lat'] != null && data['lng'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'].toDouble(), data['lng'].toDouble()),
            infoWindow: InfoWindow(
              title: data['title'] ?? 'Projet',
              snippet: data['status'] ?? '',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte des projets 🌍')),
      body: _markers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_off, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucun projet géolocalisé.',
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ajoute une position lors de la création.',
                    style: TextStyle(color: UVDSColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _markers.first.position,
                zoom: 8,
              ),
              markers: _markers,
              onMapCreated: (ctrl) {
                _mapCtrl = ctrl;
              },
            ),
    );
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _firestore.collection('chat').add({
      'text': text,
      'author': _auth.currentUser?.displayName ?? 'Membre',
      'authorId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group, size: 20),
            SizedBox(width: 8),
            Text('Chat UVDS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VideoCallScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty)
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: UVDSColors.textGrey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucun message',
                          style: TextStyle(color: UVDSColors.textGrey),
                        ),
                      ],
                    ),
                  );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients)
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _ChatBubble(
                      data: data,
                      isMe: data['authorId'] == myUid,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Écrire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: UVDSColors.light,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: UVDSColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  const _ChatBubble({required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null
        ? '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';
    final author = data['author'] ?? 'Membre';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
              child: Text(
                author[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: UVDSColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    author,
                    style: const TextStyle(
                      fontSize: 11,
                      color: UVDSColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? UVDSColors.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  data['text'] ?? '',
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: UVDSColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════
// 📞 VIDEO CALL SCREEN (Agora.io setup)
// ═════════════════════════════════════════
class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Appel vidéo'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: UVDSColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.video_camera_front,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Appels vidéo UVDS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour activer les appels vidéo en temps réel, tu dois :\n\n'
                '1. Créer un compte sur agora.io\n'
                '2. Ajouter agora_rtc_engine dans pubspec.yaml\n'
                '3. Configurer ton App ID Agora\n\n'
                'La fonctionnalité est prête à être branchée !',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Voir la doc Agora'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════
// 📊 STATS SCREEN — Graphiques fl_chart
// ═════════════════════════════════════════
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques 📊')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Membres par rôle (PieChart)
          const Text(
            'Membres par rôle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              final admins = docs
                  .where((d) => (d.data() as Map)['role'] == 'admin')
                  .length;
              final membres = docs.length - admins;
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: membres.toDouble(),
                              title: 'Membres\n$membres',
                              color: UVDSColors.primary,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: admins.toDouble(),
                              title: 'Admins\n$admins',
                              color: Colors.orange,
                              radius: 70,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          sectionsSpace: 4,
                          centerSpaceRadius: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Projets par statut (BarChart)
          const Text(
            'Projets par statut',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('projects').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              final enCours = docs
                  .where((d) => (d.data() as Map)['status'] == 'En cours')
                  .length
                  .toDouble();
              final planifie = docs
                  .where((d) => (d.data() as Map)['status'] == 'Planifié')
                  .length
                  .toDouble();
              final termine = docs
                  .where((d) => (d.data() as Map)['status'] == 'Terminé')
                  .length
                  .toDouble();
              return Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (enCours + planifie + termine + 1).clamp(
                      5,
                      double.infinity,
                    ),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const labels = ['En cours', 'Planifié', 'Terminé'];
                            return Text(
                              labels[v.toInt()],
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: enCours,
                            color: UVDSColors.primary,
                            width: 32,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: planifie,
                            color: Colors.blue,
                            width: 32,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: termine,
                            color: Colors.grey,
                            width: 32,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Totaux globaux
          const Text(
            'Résumé global',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Membres',
                  icon: Icons.people,
                  color: UVDSColors.primary,
                  stream: _firestore.collection('users').snapshots(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Posts',
                  icon: Icons.article,
                  color: Colors.blue,
                  stream: _firestore.collection('posts').snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Projets',
                  icon: Icons.folder,
                  color: Colors.purple,
                  stream: _firestore.collection('projects').snapshots(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Messages',
                  icon: Icons.chat,
                  color: Colors.teal,
                  stream: _firestore.collection('chat').snapshots(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (_, snap) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '${snap.data?.docs.length ?? 0}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: UVDSColors.textGrey),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════════════════════════════
// PROFILE SCREEN
// ═════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final url = await uploadImage(
      File(picked.path),
      'profiles/${_auth.currentUser!.uid}.jpg',
    );
    if (url != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'photoUrl': url,
      });
      await _auth.currentUser!.updatePhotoURL(url);
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? _firestore.collection('users').doc(user.uid).snapshots()
            : null,
        builder: (_, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? user?.displayName ?? 'Membre';
          final email = data?['email'] ?? user?.email ?? '';
          final role = data?['role'] ?? 'membre';
          final photoUrl = data?['photoUrl'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(
                                fontSize: 40,
                                color: UVDSColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _uploading ? null : _changePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: UVDSColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: UVDSColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: UVDSColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _PersonalStat(
                      label: 'Posts',
                      stream: _firestore
                          .collection('posts')
                          .where('uid', isEqualTo: user?.uid)
                          .snapshots(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PersonalStat(
                      label: 'Projets',
                      stream: _firestore
                          .collection('projects')
                          .where('uid', isEqualTo: user?.uid)
                          .snapshots(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ProfileTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Rôle',
                value: role,
              ),
              const SizedBox(height: 16),
              // Dark mode toggle
              AnimatedBuilder(
                animation: themeNotifier,
                builder: (_, __) => SwitchListTile(
                  title: const Text('Mode sombre 🌙'),
                  value: themeNotifier.isDark,
                  onChanged: (_) => themeNotifier.toggle(),
                  activeColor: UVDSColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _auth.signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PersonalStat extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  const _PersonalStat({required this.label, required this.stream});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (_, snap) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            '${snap.data?.docs.length ?? 0}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UVDSColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: UVDSColors.textGrey, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: UVDSColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: UVDSColors.textGrey),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ═════════════════════════════════════════
// MEMBRES SCREEN
// ═════════════════════════════════════════
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membres UVDS 👥')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Membre';
              final role = data['role'] ?? 'membre';
              final photoUrl = data['photoUrl'] ?? '';
              final isAdmin = role == 'admin';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: UVDSColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(data['email'] ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? Colors.orange.shade50
                          : UVDSColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isAdmin ? Colors.orange : UVDSColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═════════════════════════════════════════
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final notifs = await _firestore
                  .collection('notifications')
                  .where('uid', isEqualTo: uid)
                  .where('read', isEqualTo: false)
                  .get();
              for (final doc in notifs.docs) {
                await doc.reference.update({'read': true});
              }
            },
            child: const Text(
              'Tout lire',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('uid', isEqualTo: uid)
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: UVDSColors.textGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    style: TextStyle(color: UVDSColors.textGrey),
                  ),
                ],
              ),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final isNew = !(data['read'] ?? true);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isNew
                      ? UVDSColors.primary.withValues(alpha: 0.07)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNew
                        ? UVDSColors.primary.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: isNew ? UVDSColors.primary : UVDSColors.textGrey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data['message'] ?? '',
                        style: TextStyle(
                          fontWeight: isNew
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isNew)
                      GestureDetector(
                        onTap: () => docs[i].reference.update({'read': true}),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: UVDSColors.primary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════
// ADMIN SCREEN
// ═════════════════════════════════════════
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin 🛡'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Membres',
                  icon: Icons.people,
                  color: UVDSColors.primary,
                  stream: _firestore.collection('users').snapshots(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Posts',
                  icon: Icons.article,
                  color: Colors.blue,
                  stream: _firestore.collection('posts').snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Projets',
                  icon: Icons.folder,
                  color: Colors.purple,
                  stream: _firestore.collection('projects').snapshots(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Chat',
                  icon: Icons.chat,
                  color: Colors.teal,
                  stream: _firestore.collection('chat').snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Gérer les membres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              return Column(
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] ?? 'membre';
                  final isAdmin = role == 'admin';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: UVDSColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          (data['name'] ?? 'M')[0].toUpperCase(),
                          style: const TextStyle(
                            color: UVDSColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        data['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'admin')
                            await _firestore
                                .collection('users')
                                .doc(doc.id)
                                .update({'role': 'admin'});
                          if (v == 'membre')
                            await _firestore
                                .collection('users')
                                .doc(doc.id)
                                .update({'role': 'membre'});
                          if (v == 'delete')
                            await _firestore
                                .collection('users')
                                .doc(doc.id)
                                .delete();
                        },
                        itemBuilder: (_) => [
                          if (!isAdmin)
                            const PopupMenuItem(
                              value: 'admin',
                              child: Text('🛡 Passer Admin'),
                            ),
                          if (isAdmin)
                            const PopupMenuItem(
                              value: 'membre',
                              child: Text('👤 Passer Membre'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              '🗑 Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.orange.shade50
                                : UVDSColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isAdmin
                                  ? Colors.orange
                                  : UVDSColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Modération des posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox();
              return Column(
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(
                        data['user'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        data['text'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _firestore.collection('posts').doc(doc.id).delete(),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
