import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../utils/theme.dart';
import '../services/storage_service.dart';
import '../services/odoo_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final storage = StorageService();
      final hasCreds = await storage.hasCredentials();
      
      if (hasCreds) {
        final creds = await storage.getCredentials();
        final url = creds['url'];
        final user = creds['user'];
        final password = creds['password'];

        if (url != null && user != null && password != null) {
          final odooService = OdooService();
          odooService.setBaseUrl(url);
          
          // Silently login to fetch up-to-date projects
          final result = await odooService.login(user, password);
          final int employeeId = result['employee_id'];
          final List<dynamic> bimProjects = result['bim_projects'] ?? [];

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen(
                odooService: odooService,
                employeeId: employeeId,
                bimProjects: bimProjects,
              )),
            );
            return;
          }
        }
      }
    } catch (e) {
      // If auto-login fails, stay on Welcome screen
      print("Auto-login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryPurple,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_filled, size: 100, color: Colors.white),
           const SizedBox(height: 32),
            Text(
              'Bim Asistencia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gestiona tus horas de trabajo eficientemente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryPurple,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('COMENZAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
