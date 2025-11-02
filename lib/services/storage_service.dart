import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'adilet_favorites';
  static StorageService? _instance;
  final SharedPreferences _prefs;
  List<Map<String, dynamic>>? _cache;

  StorageService._(this._prefs);

  /// Получаем или создаём экземпляр Singleton
  static Future<StorageService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
    return _instance!;
  }

  /// Сохраняет список избранных актов
  Future<void> saveFavorites(List<Map<String, dynamic>> favorites) async {
    _cache = favorites;
    final jsonStr = jsonEncode(favorites);
    await _prefs.setString(_favoritesKey, jsonStr);
  }

  /// Возвращает список избранных актов
  List<Map<String, dynamic>> getFavorites() {
    if (_cache != null) return _cache!;

    final jsonStr = _prefs.getString(_favoritesKey);
    if (jsonStr == null) {
      _cache = <Map<String, dynamic>>[];
      return _cache!;
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _cache = decoded
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
        )
            .toList();
        return _cache!;
      }
      _cache = <Map<String, dynamic>>[];
      return _cache!;
    } catch (e) {
      _cache = <Map<String, dynamic>>[];
      return _cache!;
    }
  }

  /// Добавляет акт в избранное (если его ещё нет)
  Future<void> addFavorite(Map<String, dynamic> act) async {
    final favs = getFavorites();
    final id = act['id'] ?? act['title'];
    final exists = favs.any((e) => (e['id'] ?? e['title']) == id);
    if (!exists) {
      favs.insert(0, act);
      await saveFavorites(favs);
    }
  }

  /// Удаляет акт по id или title
  Future<void> removeFavoriteById(Object? id) async {
    final favs = getFavorites();
    favs.removeWhere((e) => (e['id'] ?? e['title']) == id);
    await saveFavorites(favs);
  }

  /// Проверяет, находится ли акт в избранном
  bool isFavorite(Object? id) {
    final favs = getFavorites();
    return favs.any((e) => (e['id'] ?? e['title']) == id);
  }

  /// Полная очистка избранного
  Future<void> clearFavorites() async {
    _cache = <Map<String, dynamic>>[];
    await _prefs.remove(_favoritesKey);
  }
}
