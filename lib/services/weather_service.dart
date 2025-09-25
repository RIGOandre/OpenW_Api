import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey = '';
  
  final http.Client _client;
  final Connectivity _connectivity;

  WeatherService({
    http.Client? client,
    Connectivity? connectivity,
  }) : _client = client ?? http.Client(),
       _connectivity = connectivity ?? Connectivity();

  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<WeatherModel> getCurrentWeather(String city) async {
    if (!await _hasInternetConnection()) {
      throw Exception('Sem conexão com a internet');
    }

    final url = Uri.parse(
      '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric&lang=pt_br',
    );

    try {
      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na requisição'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Cidade não encontrada');
      } else if (response.statusCode == 401) {
        throw Exception('Chave da API inválida');
      } else {
        throw Exception('Erro no servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro de rede: $e');
    }
  }

  Future<List<ForecastModel>> getForecast(String city) async {
    if (!await _hasInternetConnection()) {
      throw Exception('Sem conexão com a internet');
    }

    final url = Uri.parse(
      '$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric&lang=pt_br',
    );

    try {
      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na requisição'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList
            .map((item) => ForecastModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('Cidade não encontrada');
      } else if (response.statusCode == 401) {
        throw Exception('Chave da API inválida');
      } else {
        throw Exception('Erro no servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro de rede: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}