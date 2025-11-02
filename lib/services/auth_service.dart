import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⚙️ Для Flutter Web — localhost
  // ⚙️ Для Android эмулятора — 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000/auth';

  /// Проверка доступности сервера
  static Future<bool> checkServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при пинге сервера: $e');
      return false;
    }
  }

  /// Регистрация пользователя
  static Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "surname": surname,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );

      print('Ответ регистрации: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success' && result['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', result['token']);
          await prefs.setString('user_name', name);
          await prefs.setString('user_surname', surname);
          await prefs.setString('user_email', email);
          await prefs.setString('user_phone', phone);
        }

        return result;
      } else {
        return {
          "status": "error",
          "message":
          "Ошибка ${response.statusCode}: ${response.body}"
        };
      }
    } catch (e) {
      print('Ошибка регистрации: $e');
      return {"status": "error", "message": e.toString()};
    }
  }

  /// Авторизация пользователя
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print('Ответ логина: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success' && result['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', result['token']);

          final user = result['user'];
          if (user != null) {
            await prefs.setString('user_name', user['name'] ?? '');
            await prefs.setString('user_surname', user['surname'] ?? '');
            await prefs.setString('user_email', user['email'] ?? '');
            await prefs.setString('user_phone', user['phone'] ?? '');
          }
        }

        return result;
      } else {
        return {
          "status": "error",
          "message":
          "Ошибка ${response.statusCode}: ${response.body}"
        };
      }
    } catch (e) {
      print('Ошибка входа: $e');
      return {"status": "error", "message": e.toString()};
    }
  }

  /// Выход из системы
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Проверка авторизации
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Получение сохранённого токена
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
