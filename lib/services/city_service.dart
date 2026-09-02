import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_helper.dart';
import '../models/app_exception.dart';

/// Lista de cidades favoritas e a última cidade escolhida pelo usuário.
class CityService {
  CityService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static const String _lastSelectedCityKey = 'last_selected_city';

  /// Cidade exibida quando nem o banco nem as preferências respondem.
  static String get _defaultCity => DatabaseHelper.defaultCities.first;

  final DatabaseHelper _databaseHelper;

  /// Cidades salvas, semeando as padrão quando a lista está vazia.
  Future<List<String>> getCities() async {
    try {
      final cities = await _databaseHelper.getCities();
      if (cities.isNotEmpty) return cities;

      // A semente roda no onCreate, que não acontece em banco já existente:
      // sem este caminho, quem migra de uma versão antiga fica sem cidade
      // nenhuma e sem como voltar.
      await _databaseHelper.seedDefaultCities();
      return await _databaseHelper.getCities();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<void> addCity(String cityName) async {
    final trimmedCity = cityName.trim();
    if (trimmedCity.isEmpty) {
      throw const AppException('O nome da cidade não pode ficar em branco');
    }

    try {
      // Quem decide se a cidade entrou é o índice único do banco: consultar
      // antes e inserir depois deixaria brecha entre as duas chamadas.
      final inserida = await _databaseHelper.insertCity(trimmedCity);
      if (!inserida) {
        throw const AppException('Esta cidade já está na lista');
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<void> removeCity(String cityName) async {
    try {
      // getCitiesCount() devolve 0 quando o banco falha, e isso viraria um
      // "última cidade" enganoso na tela; a lista deixa o erro real subir.
      final cities = await _databaseHelper.getCities();
      if (cities.length <= 1) {
        throw const AppException('Não é possível remover a última cidade');
      }

      final removida = await _databaseHelper.deleteCity(cityName);
      if (!removida) {
        throw const AppException('Esta cidade não está mais na lista');
      }

      // Sem a cidade na lista, o clima guardado dela só ocupa espaço.
      await _databaseHelper.clearCacheFor(cityName);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  Future<bool> cityExists(String cityName) {
    return _databaseHelper.cityExists(cityName);
  }

  Future<int> getCitiesCount() {
    return _databaseHelper.getCitiesCount();
  }

  /// Última cidade aberta, ou a primeira da lista quando ela não existe mais.
  Future<String> getLastSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCity = prefs.getString(_lastSelectedCityKey);

      if (lastCity != null && await _databaseHelper.cityExists(lastCity)) {
        return lastCity;
      }

      final cities = await getCities();
      return cities.isNotEmpty ? cities.first : _defaultCity;
    } catch (error) {
      // A tela precisa de uma cidade para abrir, mesmo que o banco falhe.
      debugPrint('Falha ao recuperar a última cidade: $error');
      return _defaultCity;
    }
  }

  Future<void> saveLastSelectedCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSelectedCityKey, cityName);
      await _databaseHelper.updateLastAccessed(cityName);
    } catch (error) {
      // Não é crítico: no máximo a lista abre na ordem antiga.
      debugPrint('Falha ao salvar a última cidade selecionada: $error');
    }
  }

  /// Volta o app ao estado de instalação: cidades padrão e nada em cache.
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSelectedCityKey);
      await _databaseHelper.clearAllCities();
      // A semente vem antes de limpar o cache: se algo falhar daqui em diante,
      // o usuário ainda fica com a lista de cidades de volta.
      await _databaseHelper.seedDefaultCities();
      await _databaseHelper.clearCache();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.database(error);
    }
  }

  /// Fecha o banco.
  ///
  /// [DatabaseHelper] é um singleton usado pelo app inteiro, então isto só faz
  /// sentido ao encerrar o app de vez, nunca no `dispose()` de uma tela.
  Future<void> dispose() async {
    try {
      await _databaseHelper.close();
    } catch (error) {
      debugPrint('Falha ao fechar o banco de dados: $error');
    }
  }
}
