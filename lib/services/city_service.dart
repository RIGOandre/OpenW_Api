import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';

class CityService {
  static const String _lastSelectedCityKey = 'last_selected_city';
  static const String _defaultCity = 'São Paulo';
  
  final DatabaseHelper _databaseHelper;

  CityService({DatabaseHelper? databaseHelper}) 
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  Future<List<String>> getCities() async {
    try {
      final cities = await _databaseHelper.getCities();
      
      if (cities.isEmpty) {
        // Se não há cidades, inserir as padrão
        await _databaseHelper.insertCity('São Paulo');
        await _databaseHelper.insertCity('Concórdia');
        return await _databaseHelper.getCities();
      }
      
      return cities;
    } catch (e) {
      throw Exception('Erro ao buscar cidades: $e');
    }
  }

  Future<void> addCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      throw Exception('Nome da cidade não pode estar vazio');
    }
    
    try {
      final trimmedCity = cityName.trim();
      
      // Verificar se a cidade já existe
      if (await _databaseHelper.cityExists(trimmedCity)) {
        throw Exception('Esta cidade já está na lista');
      }
      
      await _databaseHelper.insertCity(trimmedCity);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao adicionar cidade: $e');
    }
  }

  Future<void> removeCity(String cityName) async {
    try {
      // Verificar se não é a última cidade
      final count = await _databaseHelper.getCitiesCount();
      if (count <= 1) {
        throw Exception('Não é possível remover a última cidade');
      }
      
      await _databaseHelper.deleteCity(cityName);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro ao remover cidade: $e');
    }
  }

  Future<bool> cityExists(String cityName) async {
    try {
      return await _databaseHelper.cityExists(cityName);
    } catch (e) {
      return false;
    }
  }

  Future<String> getLastSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCity = prefs.getString(_lastSelectedCityKey);
      
      if (lastCity != null) {
        // Verificar se a cidade ainda existe na base de dados
        if (await _databaseHelper.cityExists(lastCity)) {
          return lastCity;
        }
      }
      
      // Se não há última cidade ou ela não existe mais, retornar a primeira disponível
      final cities = await getCities();
      return cities.isNotEmpty ? cities.first : _defaultCity;
    } catch (e) {
      return _defaultCity;
    }
  }

  Future<void> saveLastSelectedCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSelectedCityKey, cityName);
      
      // Atualizar último acesso no banco
      await _databaseHelper.updateLastAccessed(cityName);
    } catch (e) {
      // Não é crítico se falhar
      print('Erro ao salvar última cidade selecionada: $e');
    }
  }

  Future<int> getCitiesCount() async {
    try {
      return await _databaseHelper.getCitiesCount();
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSelectedCityKey);
      await _databaseHelper.clearAllCities();
      
      // Re-inserir cidades padrão
      await _databaseHelper.insertCity('São Paulo');
      await _databaseHelper.insertCity('Concórdia');
    } catch (e) {
      throw Exception('Erro ao limpar dados: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _databaseHelper.close();
    } catch (e) {
      // Não é crítico
      print('Erro ao fechar banco de dados: $e');
    }
  }
}