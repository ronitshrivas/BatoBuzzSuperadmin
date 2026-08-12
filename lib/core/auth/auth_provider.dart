import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = true;
  bool _loggedIn = false;
  String? _role; // 'superadmin' or 'admin'
  String? _displayName;
  String? _error;

  bool get loading => _loading;
  bool get loggedIn => _loggedIn;
  bool get isSuperAdmin => _role == 'superadmin';
  String get displayName => _displayName ?? 'Admin';
  String? get error => _error;

  Future<void> init() async {
    await ApiClient.instance.loadToken();
    if (ApiClient.instance.isLoggedIn) {
      _parseToken();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      final res = await ApiClient.instance.post('/api/user/auth/login', {
        'email': email,
        'password': password,
      });
      final data = res['data'];
      final token = data['accessToken'] as String;
      await ApiClient.instance.setToken(token);
      _parseToken();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Check server connection.';
      notifyListeners();
      return false;
    }
  }

  void _parseToken() {
    final token = ApiClient.instance.token!;
    final parts = token.split('.');
    if (parts.length != 3) return;
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map;
    final roles =
        payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    final roleList = roles is List ? roles.cast<String>() : [roles.toString()];
    if (roleList.contains('superadmin')) {
      _role = 'superadmin';
    } else if (roleList.contains('admin')) {
      _role = 'admin';
    }
    _displayName = payload['display_name'] as String?;
    _loggedIn = true;
  }

  Future<void> logout() async {
    await ApiClient.instance.clearToken();
    _loggedIn = false;
    _role = null;
    _displayName = null;
    notifyListeners();
  }
}
