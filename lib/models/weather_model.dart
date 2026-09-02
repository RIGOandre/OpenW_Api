/// Clima atual de uma cidade.
///
/// Os horários ([sunrise], [sunset] e [observedAt]) já vêm deslocados para o
/// fuso da cidade consultada: são `DateTime` em UTC cujo "relógio de parede"
/// corresponde à hora local do lugar, e não à hora do aparelho.
class WeatherModel {
  const WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.conditionId,
    required this.humidity,
    required this.windSpeed,
    required this.windDegrees,
    required this.latitude,
    required this.longitude,
    required this.sunrise,
    required this.sunset,
    required this.observedAt,
    required this.timezoneOffset,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.visibility,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = _asMap(json['main']);
    final sys = _asMap(json['sys']);
    final wind = _asMap(json['wind']);
    final coord = _asMap(json['coord']);
    final condition = _firstCondition(json['weather']);
    final offset = Duration(seconds: _asInt(json['timezone']));

    return WeatherModel(
      cityName: _asString(json['name']),
      country: _asString(sys['country']),
      temperature: _asDouble(main['temp']),
      feelsLike: _asDouble(main['feels_like']),
      description: _asString(condition['description']),
      icon: _asString(condition['icon'], fallback: '01d'),
      conditionId: _asInt(condition['id']),
      humidity: _asInt(main['humidity']),
      windSpeed: _asDouble(wind['speed']),
      windDegrees: _asDouble(wind['deg']),
      latitude: _asDouble(coord['lat']),
      longitude: _asDouble(coord['lon']),
      sunrise: _cityTime(sys['sunrise'], offset),
      sunset: _cityTime(sys['sunset'], offset),
      observedAt: _cityTime(json['dt'], offset),
      timezoneOffset: offset,
      tempMin: _asDouble(main['temp_min']),
      tempMax: _asDouble(main['temp_max']),
      pressure: _asInt(main['pressure']),
      visibility: _asInt(json['visibility']),
    );
  }

  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;

  /// Código de condição da OpenWeatherMap (ex.: 502 = chuva forte).
  final int conditionId;
  final int humidity;

  /// Velocidade do vento em metros por segundo, como a API entrega.
  final double windSpeed;

  /// Direção do vento em graus (0 = norte).
  final double windDegrees;
  final double latitude;
  final double longitude;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime observedAt;

  /// Diferença entre o fuso da cidade e o UTC.
  final Duration timezoneOffset;
  final double tempMin;
  final double tempMax;
  final int pressure;

  /// Visibilidade em metros.
  final int visibility;

  /// `true` quando o ícone retornado pela API é de período diurno.
  bool get isDay => !icon.endsWith('n');

  /// Hora atual na cidade consultada.
  DateTime get cityNow => DateTime.now().toUtc().add(timezoneOffset);
}

/// Um dos blocos de 3 em 3 horas devolvidos pelo endpoint de previsão.
class ForecastModel {
  const ForecastModel({
    required this.dateTime,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.conditionId,
    required this.rainChance,
    required this.humidity,
    required this.windSpeed,
  });

  factory ForecastModel.fromJson(
    Map<String, dynamic> json, {
    Duration cityOffset = Duration.zero,
  }) {
    final main = _asMap(json['main']);
    final wind = _asMap(json['wind']);
    final condition = _firstCondition(json['weather']);

    return ForecastModel(
      dateTime: _forecastTime(json, cityOffset),
      temperature: _asDouble(main['temp']),
      tempMin: _asDouble(main['temp_min']),
      tempMax: _asDouble(main['temp_max']),
      description: _asString(condition['description']),
      icon: _asString(condition['icon'], fallback: '01d'),
      conditionId: _asInt(condition['id']),
      rainChance: _asDouble(json['pop']) * 100,
      humidity: _asInt(main['humidity']),
      windSpeed: _asDouble(wind['speed']),
    );
  }

  /// Lê a resposta completa de `/forecast`, aplicando o fuso da cidade.
  static List<ForecastModel> listFromResponse(Map<String, dynamic> json) {
    final items = json['list'];
    if (items is! List) return const <ForecastModel>[];

    final offset = Duration(seconds: _asInt(_asMap(json['city'])['timezone']));
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => ForecastModel.fromJson(item, cityOffset: offset))
        .toList(growable: false);
  }

  /// Horário do bloco no fuso da cidade.
  final DateTime dateTime;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int conditionId;

  /// Probabilidade de chuva já convertida para percentual.
  final double rainChance;
  final int humidity;
  final double windSpeed;
}

/// Resumo de um dia inteiro, montado a partir dos blocos de 3 horas.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.conditionId,
    required this.rainChance,
  });

  /// Agrupa os blocos por dia no fuso da cidade e resume cada um deles.
  ///
  /// Dias anteriores a [reference] são descartados e o ícone escolhido é o do
  /// bloco mais próximo do meio-dia, o que evita depender de um horário exato
  /// existir na lista — como acontecia ao filtrar somente por `hour == 12`.
  static List<DailyForecast> fromForecast(
    List<ForecastModel> items, {
    required DateTime reference,
    int maxDays = 5,
  }) {
    if (items.isEmpty) return const <DailyForecast>[];

    final groups = <DateTime, List<ForecastModel>>{};
    for (final item in items) {
      final day = _dayKey(item.dateTime);
      groups.putIfAbsent(day, () => <ForecastModel>[]).add(item);
    }

    final today = _dayKey(reference);
    final days = groups.keys.where((day) => !day.isBefore(today)).toList()
      ..sort();

    return days.take(maxDays).map((day) {
      final entries = groups[day]!;
      final highlight = _closestToNoon(entries);

      var min = entries.first.tempMin;
      var max = entries.first.tempMax;
      var rain = entries.first.rainChance;
      for (final entry in entries.skip(1)) {
        if (entry.tempMin < min) min = entry.tempMin;
        if (entry.tempMax > max) max = entry.tempMax;
        if (entry.rainChance > rain) rain = entry.rainChance;
      }

      return DailyForecast(
        date: day,
        tempMin: min,
        tempMax: max,
        description: highlight.description,
        icon: highlight.icon,
        conditionId: highlight.conditionId,
        rainChance: rain,
      );
    }).toList(growable: false);
  }

  /// Meia-noite do dia no fuso da cidade.
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int conditionId;
  final double rainChance;

  static DateTime _dayKey(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static ForecastModel _closestToNoon(List<ForecastModel> entries) {
    var best = entries.first;
    var bestDistance = (best.dateTime.hour - 12).abs();
    for (final entry in entries.skip(1)) {
      final distance = (entry.dateTime.hour - 12).abs();
      if (distance < bestDistance) {
        best = entry;
        bestDistance = distance;
      }
    }
    return best;
  }
}

/// Fotografia completa do clima de uma cidade em um dado momento.
class WeatherSnapshot {
  factory WeatherSnapshot({
    required WeatherModel weather,
    required List<ForecastModel> forecast,
    required DateTime updatedAt,
    bool fromCache = false,
    bool isStale = false,
  }) {
    final cityNow = weather.cityNow;
    return WeatherSnapshot._(
      weather: weather,
      forecast: forecast,
      dailyForecast: DailyForecast.fromForecast(forecast, reference: cityNow),
      cityNow: cityNow,
      updatedAt: updatedAt,
      fromCache: fromCache,
      isStale: isStale,
    );
  }

  const WeatherSnapshot._({
    required this.weather,
    required this.forecast,
    required this.dailyForecast,
    required this.cityNow,
    required this.updatedAt,
    required this.fromCache,
    required this.isStale,
  });

  final WeatherModel weather;
  final List<ForecastModel> forecast;
  final List<DailyForecast> dailyForecast;

  /// Hora local da cidade no momento em que o snapshot foi montado.
  final DateTime cityNow;

  /// Quando os dados foram baixados (relógio do aparelho).
  final DateTime updatedAt;

  /// `true` quando o conteúdo veio do banco local.
  final bool fromCache;

  /// `true` quando o cache passou da validade e está sendo exibido assim mesmo.
  final bool isStale;
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

Map<String, dynamic> _firstCondition(Object? value) =>
    value is List && value.isNotEmpty ? _asMap(value.first) : _asMap(null);

String _asString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) return value;
  return fallback;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _asInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Converte um timestamp UTC da API para o relógio local da cidade.
DateTime _cityTime(Object? epochSeconds, Duration offset) =>
    DateTime.fromMillisecondsSinceEpoch(
      _asInt(epochSeconds) * 1000,
      isUtc: true,
    ).add(offset);

DateTime _forecastTime(Map<String, dynamic> json, Duration offset) {
  final timestamp = json['dt'];
  if (timestamp is num) return _cityTime(timestamp, offset);

  // `dt_txt` vem em UTC, mesmo sem trazer o sufixo indicando isso.
  final text = json['dt_txt'];
  if (text is String) {
    final parsed = DateTime.tryParse('${text.trim().replaceFirst(' ', 'T')}Z');
    if (parsed != null) return parsed.add(offset);
  }
  return DateTime.now().toUtc().add(offset);
}
