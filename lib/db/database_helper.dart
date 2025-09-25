import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;
  static bool _initialized = false;

  static void _initializeDatabaseFactory() {
    if (!_initialized) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Inicializa o sqflite_ffi para plataformas desktop
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
    }
  }

  Future<Database> get database async {
    _initializeDatabaseFactory();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'weather_explorer.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Erro ao inicializar banco de dados: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Tabela de cidades
      await txn.execute('''
        CREATE TABLE cities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          created_at INTEGER NOT NULL,
          last_accessed INTEGER
        )
      ''');

      // Tabela de cache de clima (opcional para futuras implementações)
      await txn.execute('''
        CREATE TABLE weather_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          city_name TEXT NOT NULL,
          data TEXT NOT NULL,
          cached_at INTEGER NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');

      // Inserir cidades padrão
      final now = DateTime.now().millisecondsSinceEpoch;
      await txn.insert('cities', {
        'name': 'São Paulo',
        'created_at': now,
        'last_accessed': now,
      });
      await txn.insert('cities', {
        'name': 'Concórdia',
        'created_at': now,
        'last_accessed': null,
      });
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // Migrar dados da versão antiga se existir
        try {
          final oldCities = await txn.rawQuery('SELECT name FROM cities');
          await txn.execute('DROP TABLE IF EXISTS cities');
          
          await _onCreate(db, newVersion);
          
          // Re-inserir cidades antigas
          for (final city in oldCities) {
            await insertCity(city['name'] as String);
          }
        } catch (e) {
          // Se falhar, criar nova estrutura
          await _onCreate(db, newVersion);
        }
      });
    }
  }

  Future<List<String>> getCities() async {
    try {
      final db = await database;
      final result = await db.query(
        'cities',
        columns: ['name'],
        orderBy: 'last_accessed DESC, created_at ASC',
      );
      return result.map((row) => row['name'] as String).toList();
    } catch (e) {
      throw Exception('Erro ao buscar cidades: $e');
    }
  }

  Future<void> insertCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      throw Exception('Nome da cidade não pode estar vazio');
    }

    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        'cities',
        {
          'name': cityName.trim(),
          'created_at': now,
          'last_accessed': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw Exception('Erro ao inserir cidade: $e');
    }
  }

  Future<void> updateLastAccessed(String cityName) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        'cities',
        {'last_accessed': now},
        where: 'name = ?',
        whereArgs: [cityName],
      );
    } catch (e) {
      // Não é crítico se falhar
      print('Erro ao atualizar último acesso: $e');
    }
  }

  Future<void> deleteCity(String cityName) async {
    try {
      final db = await database;
      final deleted = await db.delete(
        'cities',
        where: 'name = ?',
        whereArgs: [cityName],
      );
      
      if (deleted == 0) {
        throw Exception('Cidade não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao deletar cidade: $e');
    }
  }

  Future<bool> cityExists(String cityName) async {
    try {
      final db = await database;
      final result = await db.query(
        'cities',
        where: 'LOWER(name) = LOWER(?)',
        whereArgs: [cityName.trim()],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<int> getCitiesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM cities');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearAllCities() async {
    try {
      final db = await database;
      await db.delete('cities');
    } catch (e) {
      throw Exception('Erro ao limpar cidades: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('weather_cache');
    } catch (e) {
      throw Exception('Erro ao limpar cache: $e');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
