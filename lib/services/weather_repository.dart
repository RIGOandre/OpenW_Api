import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/app_exception.dart';
import '../models/weather_model.dart';
import 'weather_service.dart';

/// Junta as duas chamadas da OpenWeatherMap em um único [WeatherSnapshot] e
/// guarda a resposta no banco para quando o aparelho ficar sem rede.
///
/// A tela conversa apenas com esta classe: é aqui que se decide quando servir
/// dado da rede e quando cair para o cache.
class WeatherRepository {
  WeatherRepository({
    WeatherService? weatherService,
    DatabaseHelper? databaseHelper,
    this.cacheTtl = const Duration(minutes: 15),
  })  : _service = weatherService ?? WeatherService(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Chaves do envelope gravado no cache.
  static const String _weatherKey = 'weather';
  static const String _forecastKey = 'forecast';

  final WeatherService _service;
  final DatabaseHelper _databaseHelper;

  /// Por quanto tempo a resposta salva continua valendo como atual.
  ///
  /// Dentro desse prazo [load] responde direto do banco; passado ele, o cache
  /// vira apenas o último recurso para quando a rede falhar.
  final Duration cacheTtl;

  /// `true` quando existe uma chave da API configurada.
  bool get hasApiKey => _service.hasApiKey;

  /// Clima atual e previsão da cidade, vindos da rede ou do cache.
  ///
  /// Com [forceRefresh] em `false`, um cache dentro da validade responde sem
  /// ida à rede, o que evita gastar requisição a cada troca de cidade. O botão
  /// de atualizar passa `true` e sempre tenta a rede primeiro.
  ///
  /// Só falha de conexão autoriza servir dado antigo: chave ausente, chave
  /// inválida e cidade inexistente sobem direto, porque nesses casos o cache
  /// esconderia justamente o que o usuário precisa corrigir.
  Future<WeatherSnapshot> load(String city, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCache(city);
      if (cached != null && !cached.isStale) return cached;
    }

    try {
      final responses = await Future.wait(<Future<Map<String, dynamic>>>[
        _service.fetchCurrentWeather(city),
        _service.fetchForecast(city),
      ]);

      final snapshot = WeatherSnapshot(
        weather: WeatherModel.fromJson(responses[0]),
        forecast: ForecastModel.listFromResponse(responses[1]),
        updatedAt: DateTime.now(),
      );

      await _saveCache(city, responses[0], responses[1]);
      return snapshot;
    } on AppException catch (error) {
      if (!_allowsCacheFallback(error.type)) rethrow;

      final cached = await _readCache(city);
      if (cached == null) rethrow;
      return cached;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Fecha o cliente HTTP.
  ///
  /// O banco não é fechado aqui: [DatabaseHelper] é um singleton compartilhado
  /// com o restante do app.
  void dispose() => _service.dispose();

  /// Dado velho só ajuda quando o problema foi a conexão.
  bool _allowsCacheFallback(AppErrorType type) =>
      type == AppErrorType.offline ||
      type == AppErrorType.network ||
      type == AppErrorType.timeout;

  /// Grava clima e previsão em um único registro.
  ///
  /// O índice de `weather_cache` é único por cidade e a inserção substitui o
  /// que estiver lá: em chamadas separadas, a segunda resposta apagaria a
  /// primeira e o modo offline mostraria a tela pela metade.
  Future<void> _saveCache(
    String city,
    Map<String, dynamic> weather,
    Map<String, dynamic> forecast,
  ) async {
    try {
      await _databaseHelper.saveWeatherPayload(
        city,
        json.encode(<String, dynamic>{
          _weatherKey: weather,
          _forecastKey: forecast,
        }),
        ttl: cacheTtl,
      );
    } catch (error) {
      // Ficar sem cache é aceitável; quebrar o carregamento não.
      debugPrint('Falha ao preparar o cache do clima: $error');
    }
  }

  /// Reconstrói o snapshot a partir do envelope salvo, ou `null` quando não há
  /// cache utilizável para a cidade.
  Future<WeatherSnapshot?> _readCache(String city) async {
    final cached = await _databaseHelper.readWeatherPayload(city);
    if (cached == null) return null;

    try {
      final envelope = json.decode(cached.data);
      if (envelope is! Map<String, dynamic>) return null;

      final weather = envelope[_weatherKey];
      if (weather is! Map<String, dynamic>) return null;

      final forecast = envelope[_forecastKey];
      return WeatherSnapshot(
        weather: WeatherModel.fromJson(weather),
        forecast: forecast is Map<String, dynamic>
            ? ForecastModel.listFromResponse(forecast)
            : const <ForecastModel>[],
        // A data vem da linha do banco, não do envelope, para não existirem
        // duas versões do mesmo carimbo de tempo.
        updatedAt: cached.cachedAt,
        fromCache: true,
        isStale: cached.isExpired,
      );
    } on FormatException catch (error) {
      debugPrint('Cache do clima em formato inesperado: $error');
      return null;
    }
  }
}
