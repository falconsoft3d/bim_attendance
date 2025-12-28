import 'package:flutter/material.dart';
import '../services/odoo_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'attendance_list_screen.dart';
class HomeScreen extends StatefulWidget {
  final OdooService odooService;
  final int employeeId;
  final List<dynamic> bimProjects;

  const HomeScreen({
    super.key, 
    required this.odooService, 
    required this.employeeId,
    this.bimProjects = const [],
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  bool? _isCheckedIn;
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    if (widget.bimProjects.isNotEmpty) {
      _selectedProjectId = widget.bimProjects.first['id'];
    }
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final status = await widget.odooService.checkAttendanceStatus(widget.employeeId);
      if (mounted) {
        setState(() {
          _isCheckedIn = status;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _registerAttendance(bool isCheckIn) async {
    if (isCheckIn && _selectedProjectId == null && widget.bimProjects.isNotEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un proyecto'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final rawNow = DateTime.now().toUtc().toIso8601String();
      final now = rawNow.substring(0, 19).replaceAll('T', ' ');
      
      await widget.odooService.registerAttendance(
        employeeId: widget.employeeId,
        checkIn: isCheckIn ? now : null,
        checkOut: isCheckIn ? null : now,
        projectId: isCheckIn ? _selectedProjectId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Éxito: ${isCheckIn ? "Bienvenido!" : "Hasta luego!"}'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
        _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Bim Asistencia', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(odooService: widget.odooService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceListScreen(
                    odooService: widget.odooService, 
                    employeeId: widget.employeeId
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoading || _isCheckingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Image.asset(
                        'assets/icon.png',
                        height: 100,
                      ),
                    ),
                    const Spacer(),
                    
                    // Main Content
                    if (_isCheckedIn == true) ...[
                      const Text(
                        "Estás dentro",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      _buildAttendanceButton(
                        label: 'SALIR',
                        color: Colors.redAccent,
                        icon: Icons.logout,
                        onTap: () => _registerAttendance(false),
                      ),
                    ] else ...[
                      const Text(
                        "Registrar Entrada",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (widget.bimProjects.isNotEmpty)
                        InkWell(
                          onTap: _showProjectSelectionModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedProjectId == null
                                        ? "Seleccione Proyecto"
                                        : _getProjectDisplayName(_selectedProjectId!),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      _buildAttendanceButton(
                        label: 'ENTRAR',
                        color: Colors.green,
                        icon: Icons.login,
                        onTap: () => _registerAttendance(true),
                      ),
                    ],

                    const Spacer(),
                    
                    // Footer
                    const Text(
                      "bim20.com",
                      style: TextStyle(
                        color: Colors.white54, 
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  String _getProjectDisplayName(int projectId) {
    try {
      final project = widget.bimProjects.firstWhere(
        (p) => p['id'] == projectId,
        orElse: () => {'name': 'Desconocido', 'code': '', 'nombre': ''},
      );
      
      final code = project['code'] ?? '';
      // Prefer 'nombre' if available, otherwise 'name'
      final rawName = project['nombre'];
      String name = (rawName != null && rawName.toString().isNotEmpty) 
          ? rawName.toString() 
          : (project['name'] ?? 'Desconocido');

      return code.isNotEmpty ? '$code - $name' : name;
    } catch (e) {
      return 'Desconocido';
    }
  }

  void _showProjectSelectionModal() async {
    final selectedId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProjectSelectionSheet(projects: widget.bimProjects),
    );

    if (selectedId != null) {
      setState(() {
        _selectedProjectId = selectedId;
      });
    }
  }
}

class ProjectSelectionSheet extends StatefulWidget {
  final List<dynamic> projects;

  const ProjectSelectionSheet({super.key, required this.projects});

  @override
  State<ProjectSelectionSheet> createState() => _ProjectSelectionSheetState();
}

class _ProjectSelectionSheetState extends State<ProjectSelectionSheet> {
  List<dynamic> _filteredProjects = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredProjects = widget.projects;
  }

  void _filterProjects(String query) {
    setState(() {
      _filteredProjects = widget.projects.where((project) {
        final name = (project['name'] ?? '').toString().toLowerCase();
        final code = (project['code'] ?? '').toString().toLowerCase();
        final nombre = (project['nombre'] ?? '').toString().toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || code.contains(search) || nombre.contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Seleccionar Proyecto",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar por nombre...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: const TextStyle(color: Colors.black),
            onChanged: _filterProjects,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredProjects.isEmpty
                ? const Center(child: Text("No se encontraron proyectos", style: TextStyle(color: Colors.black)))
                : ListView.builder(
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = _filteredProjects[index];
                      final code = project['code'] ?? '';
                      final rawName = project['nombre'];
                      String name = (rawName != null && rawName.toString().isNotEmpty) 
                          ? rawName.toString() 
                          : (project['name'] ?? 'Sin nombre');
                      
                      final displayName = code.isNotEmpty ? '$code - $name' : name;

                      return ListTile(
                        title: Text(displayName, style: const TextStyle(color: Colors.black)),
                        onTap: () => Navigator.pop(context, project['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
