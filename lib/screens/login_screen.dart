import 'package:flutter/material.dart';
import '../utils/theme.dart';

import '../services/odoo_service.dart';
import '../services/storage_service.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _dbController = TextEditingController(text: 'odoo'); // Default
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  final OdooService _odooService = OdooService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final creds = await _storageService.getCredentials();
    if (creds['url'] != null) _serverController.text = creds['url']!;
    if (creds['user'] != null) _userController.text = creds['user']!;
    if (creds['password'] != null) {
      _passwordController.text = creds['password']!;
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final url = _serverController.text.trim();
      final user = _userController.text.trim();
      final password = _passwordController.text.trim();

      _odooService.setBaseUrl(url);
      
      final result = await _odooService.login(user, password);
      
      final int employeeId = result['employee_id'];
      final List<dynamic> bimProjects = result['bim_projects'] ?? [];
      
      if (_rememberMe) {
        await _storageService.saveCredentials(url, 'odoo', user, password, employeeId);
      } else {
        await _storageService.clearCredentials();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(
            odooService: _odooService, 
            employeeId: employeeId,
            bimProjects: bimProjects,
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.asset(
                  'assets/icon.png',
                  height: 80,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _serverController,
                hint: 'Dirección del servidor',
                icon: Icons.public,
              ),
              // Database field removed from UI, uses default 'odoo'
              const SizedBox(height: 16),
              _buildTextField(
                controller: _userController,
                hint: 'Usuario BIM',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              Row(
                children: [
                   Theme(
                     data: ThemeData(unselectedWidgetColor: Colors.white),
                     child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      checkColor: AppTheme.primaryPurple,
                      activeColor: Colors.white,
                    ),
                   ),
                  const Text("Recordar contraseña", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ENTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF424242)),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
