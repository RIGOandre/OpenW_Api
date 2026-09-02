import 'package:flutter_test/flutter_test.dart';

import 'package:api_opw/models/weather_model.dart';

/// Bloco de previsão com os campos que não interessam ao teste já preenchidos.
ForecastModel bloco({
  required DateTime dateTime,
  double tempMin = 18,
  double tempMax = 25,
  double rainChance = 0,
  String icon = '01d',
  int conditionId = 800,
  String description = 'céu limpo',
}) {
  return ForecastModel(
    dateTime: dateTime,
    temperature: (tempMin + tempMax) / 2,
    tempMin: tempMin,
    tempMax: tempMax,
    description: description,
    icon: icon,
    conditionId: conditionId,
    rainChance: rainChance,
    humidity: 70,
    windSpeed: 3,
  );
}

void main() {
  group('WeatherModel.fromJson', () {
    test('resposta vazia não estoura e cai nos valores padrão', () {
      final weather = WeatherModel.fromJson(<String, dynamic>{});

      expect(weather.cityName, '');
      expect(weather.country, '');
      expect(weather.temperature, 0);
      expect(weather.conditionId, 0);
      expect(weather.icon, '01d');
      expect(weather.isDay, isTrue);
      expect(weather.timezoneOffset, Duration.zero);
      expect(weather.observedAt.isUtc, isTrue);
    });

    test('lê a resposta completa da OpenWeatherMap', () {
      final weather = WeatherModel.fromJson(<String, dynamic>{
        'name': 'São Paulo',
        'timezone': -10800,
        'dt': 1700000000,
        'visibility': 10000,
        'main': <String, dynamic>{
          'temp': 21.4,
          'feels_like': 20.8,
          'temp_min': 19.2,
          'temp_max': 24.6,
          'humidity': 78,
          'pressure': 1013,
        },
        'sys': <String, dynamic>{'country': 'BR'},
        'wind': <String, dynamic>{'speed': 5.0, 'deg': 90},
        'coord': <String, dynamic>{'lat': -23.5, 'lon': -46.6},
        'weather': <dynamic>[
          <String, dynamic>{
            'id': 502,
            'description': 'chuva forte',
            'icon': '10n',
          },
        ],
      });

      expect(weather.cityName, 'São Paulo');
      expect(weather.country, 'BR');
      expect(weather.temperature, closeTo(21.4, 0.001));
      expect(weather.feelsLike, closeTo(20.8, 0.001));
      expect(weather.humidity, 78);
      expect(weather.pressure, 1013);
      expect(weather.visibility, 10000);
      expect(weather.windSpeed, closeTo(5, 0.001));
      expect(weather.windDegrees, closeTo(90, 0.001));
      expect(weather.conditionId, 502);
      expect(weather.description, 'chuva forte');
      expect(weather.icon, '10n');
      expect(weather.isDay, isFalse);
    });

    // Os horários saem em UTC, mas com o relógio de parede da cidade: é isso
    // que permite comparar a previsão sem envolver o fuso do aparelho.
    test('desloca os horários para o fuso da cidade', () {
      final weather = WeatherModel.fromJson(<String, dynamic>{
        'timezone': -10800,
        'dt': 1700000000,
        'weather': <dynamic>[
          <String, dynamic>{'id': 800, 'icon': '01d'},
        ],
      });

      final utc = DateTime.fromMillisecondsSinceEpoch(
        1700000000 * 1000,
        isUtc: true,
      );

      expect(weather.timezoneOffset, const Duration(hours: -3));
      expect(weather.observedAt.isUtc, isTrue);
      expect(weather.observedAt, utc.subtract(const Duration(hours: 3)));
      expect(weather.observedAt.hour, 19);
    });

    test('aceita número vindo como texto, como a API às vezes devolve', () {
      final weather = WeatherModel.fromJson(<String, dynamic>{
        'main': <String, dynamic>{'temp': '19.5', 'humidity': '80'},
      });

      expect(weather.temperature, closeTo(19.5, 0.001));
      expect(weather.humidity, 80);
    });
  });

  group('ForecastModel.listFromResponse', () {
    test('resposta sem lista devolve previsão vazia', () {
      expect(
        ForecastModel.listFromResponse(<String, dynamic>{}),
        isEmpty,
      );
    });

    test('usa dt_txt quando não há dt e aplica o fuso da cidade', () {
      final items = ForecastModel.listFromResponse(<String, dynamic>{
        'city': <String, dynamic>{'timezone': -10800},
        'list': <dynamic>[
          <String, dynamic>{
            'dt_txt': '2026-01-05 12:00:00',
            'pop': 0.42,
            'main': <String, dynamic>{
              'temp': 22.0,
              'temp_min': 18.0,
              'temp_max': 25.0,
              'humidity': 70,
            },
            'wind': <String, dynamic>{'speed': 3.0},
            'weather': <dynamic>[
              <String, dynamic>{
                'id': 500,
                'description': 'chuva leve',
                'icon': '10d',
              },
            ],
          },
        ],
      });

      expect(items, hasLength(1));

      final item = items.first;
      expect(item.dateTime, DateTime.utc(2026, 1, 5, 9));
      expect(item.dateTime.isUtc, isTrue);
      expect(item.rainChance, closeTo(42, 0.001));
      expect(item.tempMin, closeTo(18, 0.001));
      expect(item.tempMax, closeTo(25, 0.001));
      expect(item.icon, '10d');
      expect(item.conditionId, 500);
    });
  });

  group('DailyForecast.fromForecast', () {
    test('lista vazia devolve resumo vazio', () {
      expect(
        DailyForecast.fromForecast(
          const <ForecastModel>[],
          reference: DateTime.utc(2026, 1, 5),
        ),
        isEmpty,
      );
    });

    test('resume o dia e descarta o que já passou', () {
      final dias = DailyForecast.fromForecast(
        <ForecastModel>[
          bloco(dateTime: DateTime.utc(2026, 1, 4, 12), tempMin: 5, tempMax: 9),
          bloco(
            dateTime: DateTime.utc(2026, 1, 5, 9),
            tempMin: 17,
            tempMax: 21,
            rainChance: 10,
          ),
          bloco(
            dateTime: DateTime.utc(2026, 1, 5, 12),
            tempMin: 19,
            tempMax: 27,
            rainChance: 42,
            icon: '10d',
            conditionId: 503,
            description: 'chuva muito forte',
          ),
          bloco(
            dateTime: DateTime.utc(2026, 1, 5, 15),
            tempMin: 18,
            tempMax: 25,
            rainChance: 30,
            icon: '02d',
            conditionId: 801,
          ),
        ],
        reference: DateTime.utc(2026, 1, 5, 7),
      );

      expect(dias, hasLength(1));

      final dia = dias.first;
      expect(dia.date, DateTime.utc(2026, 1, 5));
      expect(dia.tempMin, closeTo(17, 0.001));
      expect(dia.tempMax, closeTo(27, 0.001));
      expect(dia.rainChance, closeTo(42, 0.001));
      // Ícone e descrição vêm do bloco mais próximo do meio-dia.
      expect(dia.icon, '10d');
      expect(dia.conditionId, 503);
      expect(dia.description, 'chuva muito forte');
    });

    // Sem horário fixo de meio-dia na lista o resumo tem de sair mesmo assim:
    // fusos como o da Índia (+5:30) nunca têm bloco com hora cheia igual a 12.
    test('não depende de existir bloco às 12h', () {
      final dias = DailyForecast.fromForecast(
        <ForecastModel>[
          bloco(dateTime: DateTime.utc(2026, 1, 5, 10, 30), tempMax: 20),
          bloco(dateTime: DateTime.utc(2026, 1, 5, 13, 30), tempMax: 28),
        ],
        reference: DateTime.utc(2026, 1, 5),
      );

      expect(dias, hasLength(1));
      expect(dias.first.tempMax, closeTo(28, 0.001));
    });

    test('devolve no máximo cinco dias, em ordem', () {
      final dias = DailyForecast.fromForecast(
        List<ForecastModel>.generate(
          7,
          (index) => bloco(dateTime: DateTime.utc(2026, 1, 5 + index, 12)),
        ),
        reference: DateTime.utc(2026, 1, 5),
      );

      expect(dias, hasLength(5));
      expect(dias.first.date, DateTime.utc(2026, 1, 5));
      expect(dias.last.date, DateTime.utc(2026, 1, 9));
    });
  });

  group('WeatherSnapshot', () {
    test('monta o resumo diário e nasce sem marca de cache', () {
      final weather = WeatherModel.fromJson(<String, dynamic>{
        'timezone': -10800,
      });
      final snapshot = WeatherSnapshot(
        weather: weather,
        forecast: const <ForecastModel>[],
        updatedAt: DateTime.utc(2026, 1, 5, 12),
      );

      expect(snapshot.dailyForecast, isEmpty);
      expect(snapshot.cityNow.isUtc, isTrue);
      expect(snapshot.fromCache, isFalse);
      expect(snapshot.isStale, isFalse);
    });
  });
}
