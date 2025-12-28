import 'dart:convert';
import 'package:http/http.dart' as http;

class OdooService {
  String? _baseUrl;

  void setBaseUrl(String url) {
    if (!url.startsWith('http')) {
      _baseUrl = 'https://$url'; 
    } else {
      _baseUrl = url;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_baseUrl == null) throw Exception("Server URL not set");
    
    final uri = Uri.parse('$_baseUrl/bim/employee/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0', // While it's a custom route, it uses type='json', often implies partial JSON-RPC wrapping or just raw body.
        // Wait, Odoo 'type=json' usually expects a JSON-RPC 2.0 envelope:
        // { "jsonrpc": "2.0", "method": "call", "params": { ... }, "id": ... }
        // BUT the user's code just says `kwargs.get`.
        // If it's pure standard Odoo HTTP JSON, it expects the params inside `params`.
        // Let's assume standard Odoo JSON route conventions.
        'method': 'call',
        'params': {
          'bim_user': username,
          'bim_password': password,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['data']['message'] ?? body['error']['message']);
      }
      final result = body['result'];
      if (result['status'] == 'ok') {
        return result;
      } else {
        throw Exception(result['message'] ?? 'Login failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<void> registerAttendance({
    required int employeeId,
    String? checkIn,
    String? checkOut,
    int? projectId,
  }) async {
     if (_baseUrl == null) throw Exception("Server URL not set");

    final uri = Uri.parse('$_baseUrl/bim/employee/attendance');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'employee_id': employeeId,
          'check_in': checkIn,
          'check_out': checkOut,
          'project': projectId,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );

     if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['data']['message'] ?? body['error']['message']);
      }
      final result = body['result'];
      if (result['status'] != 'ok') {
         throw Exception(result['message'] ?? 'Attendance failed');
      }
    }
  }

  Future<bool> checkAttendanceStatus(int employeeId) async {
    if (_baseUrl == null) throw Exception("Server URL not set");

    final uri = Uri.parse('$_baseUrl/bim/employee/check-attendance');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'employee_id': employeeId,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['data']['message'] ?? body['error']['message']);
      }
      final result = body['result'];
      if (result['status'] == 'ok') {
        return result['checked_in'] == true;
      } else {
        throw Exception(result['message'] ?? 'Check status failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<void> changePassword(String user, String oldPassword, String newPassword) async {
    if (_baseUrl == null) throw Exception("Server URL not set");

    final uri = Uri.parse('$_baseUrl/bim/employee/change-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'bim_user': user,
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['data']['message'] ?? body['error']['message']);
      }
      final result = body['result'];
      if (result['status'] != 'ok') {
        throw Exception(result['message'] ?? 'Change password failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getEmployeeAttendances(int employeeId, {int limit = 10, int offset = 0}) async {
    if (_baseUrl == null) throw Exception("Server URL not set");

    final uri = Uri.parse('$_baseUrl/bim/employee/attendances');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'employee_id': employeeId,
          'limit': limit,
          'offset': offset,
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['data']['message'] ?? body['error']['message']);
      }
      final result = body['result'];
      if (result['status'] == 'ok') {
        return result['attendances'] ?? [];
      } else {
         throw Exception(result['message'] ?? 'Fetch failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
