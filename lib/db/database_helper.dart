import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_exception.dart';

/// Resposta da API guardada no banco local.
class CachedWeather {
  const CachedWeather({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// JSON bruto devolvido pela API.
  final String data;
  final DateTime cachedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Acesso ao SQLite: cidades salvas e cache das respostas da API.
class DatabaseHelper {
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static const String citiesTable = 'cities';
  static const String cacheTable = 'weather_cache';
  static const String databaseName = 'weather_explorer.db';
  static const int schemaVersion = 3;
  static const List<String> defaultCities = <String>['São Paulo', 'Concórdia'];

  Database? _database;
  Future<Database>? _opening;
  static bool _factoryReady = false;

  /// Registra a implementação de SQLite adequada à plataforma atual.
  ///
  /// Em Windows, Linux e macOS o plugin nativo não existe, então usamos o
  /// `sqflite_common_ffi`. Chamar mais de uma vez é seguro.
  static void initializePlatform() {
    if (_factoryReady) return;
    if (_isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryReady = true;
  }

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Chave usada para comparar cidades sem depender de acentuação de caixa.
  static String cityKey(String cityName) =>
      cityName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Banco aberto, reaproveitando a mesma conexão entre chamadas simultâneas.
  Future<Database> get database async {
    final opened = _database;
    if (opened != null) return opened;

    final pending = _opening ??= _open();
    try {
      final db = await pending;
      _database = db;
      return db;
    } finally {
      if (identical(_opening, pending)) _opening = null;
    }
  }

  Future<Database> _open() async {
    initializePlatform();
    try {
      final directory = await getDatabasesPath();
      return await openDatabase(
        p.join(directory, databaseName),
        version: schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      );
    } catch (error) {
      throw AppException.database(error);
    }
  }

  // O sqflite já executa onCreate/onUpgrade dentro de uma transação, por isso
  // nenhum destes métodos pode abrir outra — isso travaria a conexão.
  Future<void> _onCreate(Database db, int version) async {
    await _createCitiesSchema(db);
    await _createCacheSchema(db);
    await _seedDefaultCities(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createCitiesSchema(db);

    final columns = await _columnsOf(db, citiesTable);
    if (!columns.contains('created_at')) {
      await db.execute('ALTER TABLE $citiesTable ADD COLUMN created_at INTEGER');
    }
    if (!columns.contains('last_accessed')) {
      await db.execute(
        'ALTER TABLE $citiesTable ADD COLUMN last_accessed INTEGER',
      );
    }
    if (!columns.contains('name_key')) {
      await db.execute('ALTER TABLE $citiesTable ADD COLUMN name_key TEXT');
    }

    await _backfillCities(db);
    await _removeDuplicateCities(db);
    await _createCitiesIndex(db);

    // O cache é descartável: recriar é mais barato do que migrar.
    await db.execute('DROP TABLE IF EXISTS $cacheTable');
    await _createCacheSchema(db);
  }

  Future<void> _createCitiesSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $citiesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_accessed INTEGER
      )
    ''');
    await _createCitiesIndex(db);
  }

  Future<void> _createCitiesIndex(DatabaseExecutor db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cities_name_key '
      'ON $citiesTable (name_key)',
    );
  }

  Future<void> _createCacheSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $cacheTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city_name TEXT NOT NULL,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_weather_cache_city '
      'ON $cacheTable (city_name)',
    );
  }

  Future<void> _seedDefaultCities(DatabaseExecutor db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final city in defaultCities) {
      await db.insert(
        citiesTable,
        <String, Object?>{
          'name': city,
          'name_key': cityKey(city),
          'created_at': now,
          'last_accessed': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<Set<String>> _columnsOf(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((row) => row['name']).whereType<String>().toSet();
  }

  /// Preenche as colunas criadas em versões novas do esquema.
  Future<void> _backfillCities(DatabaseExecutor db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate(
      'UPDATE $citiesTable SET created_at = ? WHERE created_at IS NULL',
      <Object?>[now],
    );

    final rows = await db.query(
      citiesTable,
      columns: <String>['id', 'name', 'name_key'],
    );
    for (final row in rows) {
      final name = row['name'] as String? ?? '';
      final key = cityKey(name);
      if (row['name_key'] == key) continue;
      await db.update(
        citiesTable,
        <String, Object?>{'name_key': key},
        where: 'id = ?',
        whereArgs: <Object?>[row['id']],
      );
    }
  }

  /// Remove cidades repetidas antes de criar o índice único.
  Future<void> _removeDuplicateCities(DatabaseExecutor db) async {
    await db.execute('''
      DELETE FROM $citiesTable
      WHERE id NOT IN (SELECT MIN(id) FROM $citiesTable GROUP BY name_key)
    ''');
  }

  /// Cidades salvas, das mais acessadas recentemente para as mais antigas.
  Future<List<String>> getCities() async {
    try {
      final db = await database;
      final rows = await db.query(
        citiesTable,
        columns: <String>['name'],
        orderBy: 'last_accessed DESC, created_at ASC, id ASC',
      );
      return rows.map((row) => row['name']).whereType<String>().toList();
    } catch (error) {
      throw AppException.database(error);
    }
  }

  /// Insere uma cidade e informa se ela realmente foi adicionada.
  Future<bool> insertCity(String cityName) async {
    final name = cityName.trim();
    if (name.isEmpty) {
      throw const AppException('O nome da cidade não pode ficar em branco');
    }

    try {
      final db = await database;
      final id = await db.insert(
        citiesTable,
        <String, Object?>{
          'name': name,
          'name_key': cityKey(name),
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'last_accessed': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return id != 0;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<void> updateLastAccessed(String cityName) async {
    try {
      final db = await database;
      await db.update(
        citiesTable,
        <String, Object?>{'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'name_key = ?',
        whereArgs: <Object?>[cityKey(cityName)],
      );
    } catch (error) {
      // Não é crítico: apenas a ordenação da lista deixa de ser atualizada.
      debugPrint('Falha ao atualizar o último acesso: $error');
    }
  }

  /// Remove uma cidade e informa se ela existia.
  Future<bool> deleteCity(String cityName) async {
    try {
      final db = await database;
      final removed = await db.delete(
        citiesTable,
        where: 'name_key = ?',
        whereArgs: <Object?>[cityKey(cityName)],
      );
      return removed > 0;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<bool> cityExists(String cityName) async {
    try {
      final db = await database;
      final rows = await db.query(
        citiesTable,
        columns: <String>['id'],
        where: 'name_key = ?',
        whereArgs: <Object?>[cityKey(cityName)],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  Future<int> getCitiesCount() async {
    try {
      final db = await database;
      final rows = await db.rawQuery('SELECT COUNT(*) FROM $citiesTable');
      return Sqflite.firstIntValue(rows) ?? 0;
    } catch (error) {
      return 0;
    }
  }

  Future<void> clearAllCities() async {
    try {
      final db = await database;
      await db.delete(citiesTable);
    } catch (error) {
      throw AppException.database(error);
    }
  }

  /// Repõe as cidades padrão, ignorando as que já estiverem salvas.
  ///
  /// O `onCreate` semeia a lista apenas na instalação: quem chega de uma versão
  /// antiga pelo `_onUpgrade`, ou quem limpa a lista inteira, precisa deste
  /// caminho de volta.
  Future<void> seedDefaultCities() async {
    try {
      final db = await database;
      await _seedDefaultCities(db);
    } catch (error) {
      throw AppException.database(error);
    }
  }

  /// Guarda (ou substitui) a resposta da API de uma cidade.
  Future<void> saveWeatherPayload(
    String cityName,
    String payload, {
    required Duration ttl,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      await db.insert(
        cacheTable,
        <String, Object?>{
          'city_name': cityKey(cityName),
          'data': payload,
          'cached_at': now.millisecondsSinceEpoch,
          'expires_at': now.add(ttl).millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      // Ficar sem cache é aceitável; quebrar a tela por causa disso não é.
      debugPrint('Falha ao gravar o cache do clima: $error');
    }
  }

  /// Última resposta salva para a cidade, mesmo que já tenha expirado.
  Future<CachedWeather?> readWeatherPayload(String cityName) async {
    try {
      final db = await database;
      final rows = await db.query(
        cacheTable,
        where: 'city_name = ?',
        whereArgs: <Object?>[cityKey(cityName)],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final row = rows.first;
      final data = row['data'];
      if (data is! String) return null;

      return CachedWeather(
        data: data,
        cachedAt: _dateFrom(row['cached_at']),
        expiresAt: _dateFrom(row['expires_at']),
      );
    } catch (error) {
      debugPrint('Falha ao ler o cache do clima: $error');
      return null;
    }
  }

  /// Descarta o cache de uma cidade só, usado quando ela sai da lista.
  Future<void> clearCacheFor(String cityName) async {
    try {
      final db = await database;
      await db.delete(
        cacheTable,
        where: 'city_name = ?',
        whereArgs: <Object?>[cityKey(cityName)],
      );
    } catch (error) {
      // Mesmo critério da gravação: cache é descartável, não vale derrubar a
      // remoção da cidade por causa dele.
      debugPrint('Falha ao limpar o cache da cidade: $error');
    }
  }

  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete(cacheTable);
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) await db.close();
  }

  static DateTime _dateFrom(Object? value) =>
      DateTime.fromMillisecondsSinceEpoch(value is int ? value : 0);
}
