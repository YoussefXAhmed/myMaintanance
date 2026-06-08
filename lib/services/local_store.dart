import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first persistence built on Hive. Every domain object is stored as a
/// plain JSON map (primitives only) keyed by its id, so no generated type
/// adapters are required.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const String vehicles = 'vehicles';
  static const String maintenance = 'maintenance';
  static const String fuel = 'fuel';
  static const String expenses = 'expenses';
  static const String documents = 'documents';
  static const String settings = 'settings';
  static const String session = 'session';

  static const List<String> _collections = [
    vehicles,
    maintenance,
    fuel,
    expenses,
    documents,
  ];

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    for (final c in _collections) {
      await Hive.openBox(c);
    }
    await Hive.openBox(settings);
    await Hive.openBox(session);
    _ready = true;
  }

  Box _box(String name) => Hive.box(name);

  // ---- Generic collection CRUD ---------------------------------------------
  List<Map<String, dynamic>> all(String collection) {
    return _box(collection).values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic>? get(String collection, String id) {
    final raw = _box(collection).get(id);
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  Future<void> put(String collection, String id, Map<String, dynamic> json) =>
      _box(collection).put(id, json);

  Future<void> delete(String collection, String id) => _box(collection).delete(id);

  Future<void> deleteWhere(String collection, bool Function(Map<String, dynamic>) test) async {
    final box = _box(collection);
    final keys = box.keys.where((k) {
      final v = box.get(k);
      return v is Map && test(Map<String, dynamic>.from(v));
    }).toList();
    await box.deleteAll(keys);
  }

  Future<void> clearAllData() async {
    for (final c in _collections) {
      await _box(c).clear();
    }
  }

  // ---- Settings (key/value) -------------------------------------------------
  T? setting<T>(String key, {T? fallback}) => _box(settings).get(key, defaultValue: fallback) as T?;

  Future<void> setSetting(String key, dynamic value) => _box(settings).put(key, value);

  // ---- Session --------------------------------------------------------------
  Map<String, dynamic>? get currentSession {
    final raw = _box(session).get('user');
    return raw == null ? null : Map<String, dynamic>.from(raw as Map);
  }

  Future<void> saveSession(Map<String, dynamic> user) => _box(session).put('user', user);
  Future<void> clearSession() => _box(session).delete('user');
}
