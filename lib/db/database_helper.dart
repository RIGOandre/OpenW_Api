import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cities.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE cities(id INTEGER PRIMARY KEY, name TEXT)',
        );
      },
    );
  }

  Future<List<String>> getCities() async {
    final db = await database;
    final result = await db.query('cities', columns: ['name']);
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> insertCity(String city) async {
    final db = await database;
    await db.insert(
      'cities',
      {'name': city},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCity(String city) async {
    final db = await database;
    await db.delete('cities', where: 'name = ?', whereArgs: [city]);
  }
}
