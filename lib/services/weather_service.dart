import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_exception.dart';
import 'connectivity_service.dart';

/// Cliente HTTP da OpenWeatherMap.
///
/// A chave nunca fica escrita no código: ela chega por `--dart-define`, o que
/// permite publicar o repositório sem expor credenciais.
///
/// ```bash
/// flutter run --dart-define-from-file=.env
/// ```
class WeatherService {
  WeatherService({
    http.Client? client,
    ConnectivityService? connectivity,
    String? apiKey,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _connectivity = connectivity ?? ConnectivityService(),
        _apiKey = (apiKey ?? _environmentApiKey).trim();

  static const String _host = 'api.openweathermap.org';
  static const String _basePath = '/data/2.5';
  static const String _environmentApiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY');

  final http.Client _client;
  final ConnectivityService _connectivity;
  final String _apiKey;

  /// Tempo máximo de espera por resposta.
  final Duration timeout;

  /// `true` quando existe uma chave configurada.
  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Clima atual da cidade, em JSON.
  Future<Map<String, dynamic>> fetchCurrentWeather(String city) =>
      _request('weather', city);

  /// Previsão de 3 em 3 horas para os próximos 5 dias, em JSON.
  Future<Map<String, dynamic>> fetchForecast(String city) =>
      _request('forecast', city);

  Future<Map<String, dynamic>> _request(String endpoint, String city) async {
    if (!hasApiKey) throw const AppException.missingApiKey();
    if (!await _connectivity.isOnline()) throw const AppException.offline();

    // Uri.https escapa acentos e espaços do nome da cidade.
    final url = Uri.https(_host, '$_basePath/$endpoint', <String, String>{
      'q': city,
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'pt_br',
    });

    final response = await _send(url);
    _ensureSuccess(response, city);
    return _decode(response);
  }

  Future<http.Response> _send(Uri url) async {
    try {
      return await _client.get(url).timeout(timeout);
    } on TimeoutException catch (error) {
      throw AppException('O servidor demorou demais para responder',
          type: AppErrorType.timeout, cause: error);
    } on http.ClientException catch (error) {
      throw AppException('Não foi possível falar com o servidor',
          type: AppErrorType.network, cause: error);
    } catch (error) {
      throw AppException('Falha de rede ao buscar os dados',
          type: AppErrorType.network, cause: error);
    }
  }

  void _ensureSuccess(http.Response response, String city) {
    final status = response.statusCode;
    if (status == 200) return;
    if (status == 401) throw const AppException.unauthorized();
    if (status == 404) throw AppException.notFound(city);
    if (status == 429) {
      throw const AppException(
        'Limite de requisições da API atingido. Tente em alguns minutos.',
        type: AppErrorType.server,
      );
    }
    throw AppException.server(status);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      // Decodificar os bytes evita acentos quebrados quando o servidor não
      // informa o charset no cabeçalho.
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Resposta em formato inesperado');
    } on FormatException catch (error) {
      throw AppException('O servidor devolveu uma resposta inválida',
          type: AppErrorType.server, cause: error);
    }
  }

  void dispose() => _client.close();
}
