import 'package:flutter/material.dart';
import 'login.dart';
import 'form.dart';
import 'segnalazioni.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Castellazzo dei Stampi',
      home: FutureBuilder<bool>(
        future: ApiService.loadToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _SplashScreen();
          }
          return snapshot.data! ? const MenuScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/menu': (_) => const MenuScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'android/app/src/main/res/drawable/logo.png',
          width: 160,
        ),
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> _reportTypes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReportTypes();
  }

  Future<void> _loadReportTypes() async {
    final result = await ApiService.getReportTypes();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _reportTypes =
            List<Map<String, dynamic>>.from(result['data'] as List);
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message'] as String?;
        _loading = false;
      });
    }
  }

  IconData _iconFromType(String? iconName, String? slug) {
    const iconMap = <String, IconData>{
      // nomi icona diretti dall'API
      'build': Icons.build_circle,
      'build_circle': Icons.build_circle,
      'security': Icons.security,
      'shield': Icons.shield,
      'lightbulb': Icons.lightbulb,
      'light': Icons.lightbulb,
      'electrical_services': Icons.electrical_services,
      'water': Icons.water_drop,
      'water_drop': Icons.water_drop,
      'fire': Icons.local_fire_department,
      'road': Icons.add_road,
      'eco': Icons.eco,
      'park': Icons.park,
      'volume_up': Icons.volume_up,
      'trash': Icons.delete_forever,
      'delete': Icons.delete_forever,
      'pets': Icons.pets,
      'signpost': Icons.signpost,
      'apartment': Icons.apartment,
      'air': Icons.air,
      'warning': Icons.warning_amber_rounded,
      'camera': Icons.camera_alt,
      'car': Icons.directions_car,
      'bus': Icons.directions_bus,
      'parking': Icons.local_parking,
      'person': Icons.person_off,
      'front_hand': Icons.front_hand,
      // slug dal database (trattini → underscore)
      'guasto_tecnico': Icons.build_circle,
      'sicurezza': Icons.security,
      'illuminazione': Icons.lightbulb,
      'pubblica_illuminazione': Icons.lightbulb,
      'strade': Icons.add_road,
      'strade_marciapiedi': Icons.add_road,
      'verde': Icons.park,
      'verde_pubblico': Icons.park,
      'rifiuti': Icons.delete_forever,
      'rumore': Icons.volume_up,
      'acqua': Icons.water_drop,
      'incendio': Icons.local_fire_department,
      'animali': Icons.pets,
      'segnaletica': Icons.signpost,
      'edifici': Icons.apartment,
      'inquinamento': Icons.air,
      'vandalismo': Icons.front_hand,
      'parcheggio': Icons.local_parking,
      'trasporti': Icons.directions_bus,
    };
    return iconMap[iconName] ??
        iconMap[slug?.replaceAll('-', '_')] ??
        Icons.report_problem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'android/app/src/main/res/drawable/logo.png',
          ),
        ),
        title: const Text(
          'NUOVA SEGNALAZIONE',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Esci',
            icon: const Icon(Icons.logout, color: Color(0xFF666666)),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ApiService.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SegnalazioniScreen()),
        ),
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt, color: Color(0xFF666666), size: 20),
              SizedBox(width: 8),
              Text(
                'Le mie segnalazioni',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7BA566)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadReportTypes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA566),
                foregroundColor: Colors.white,
              ),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }
    if (_reportTypes.isEmpty) {
      return const Center(
        child: Text(
          'Nessun tipo di segnalazione disponibile.',
          style: TextStyle(color: Color(0xFF666666), fontFamily: 'Inter'),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _reportTypes.length,
      itemBuilder: (context, index) {
        final type = _reportTypes[index];
        return _ReportTypeCard(
          name: type['name'] as String? ?? '',
          icon: _iconFromType(
            type['icon'] as String?,
            type['slug'] as String?,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormScreen(reportType: type),
            ),
          ),
        );
      },
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF7BA566), size: 28),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
