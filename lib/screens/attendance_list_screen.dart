import 'package:flutter/material.dart';
import '../services/odoo_service.dart';
import '../utils/theme.dart';

class AttendanceListScreen extends StatefulWidget {
  final OdooService odooService;
  final int employeeId;

  const AttendanceListScreen({super.key, required this.odooService, required this.employeeId});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<dynamic> _attendances = [];
  int _offset = 0;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAttendances();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadAttendances(loadMore: true);
      }
    }
  }

  Future<void> _loadAttendances({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final newAttendances = await widget.odooService.getEmployeeAttendances(
        widget.employeeId, 
        limit: _limit, 
        offset: loadMore ? _offset : 0
      );
      
      if (mounted) {
        setState(() {
          if (loadMore) {
            _attendances.addAll(newAttendances);
          } else {
            _attendances = newAttendances;
          }
          
          if (newAttendances.length < _limit) {
            _hasMore = false;
          }
          
          _offset += newAttendances.length;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _isLoading = false;
           _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Asistencias', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _attendances.isEmpty
              ? const Center(child: Text('No hay registros', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _attendances.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _attendances.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    }

                    final item = _attendances[index];
                    final checkIn = item['check_in'] ?? '-';
                    final checkOut = item['check_out'] ?? 'En curso';
                    final project = item['project_name'] ?? 'Sin proyecto';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.2),
                          child: const Icon(Icons.access_time, color: AppTheme.primaryTeal),
                        ),
                        title: Text('Entrada: $checkIn'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Salida: $checkOut'),
                            if (project != 'Sin proyecto')
                              Text('Proyecto: $project', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
