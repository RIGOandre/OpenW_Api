import 'package:flutter_test/flutter_test.dart';

import 'package:api_opw/utils/formatters.dart';

void main() {
  group('TemperatureUtils', () {
    test('arredonda a temperatura e acrescenta a unidade', () {
      expect(TemperatureUtils.formatTemperature(21.4), '21°C');
      expect(TemperatureUtils.formatTemperature(21.5), '22°C');
      expect(TemperatureUtils.formatTemperature(-3.2), '-3°C');
      expect(TemperatureUtils.formatDegrees(18.6), '19°');
    });

    test('só mostra a casa decimal quando ela existe', () {
      expect(TemperatureUtils.formatTemperaturePrecise(21.0), '21°C');
      expect(TemperatureUtils.formatTemperaturePrecise(21.5), '21.5°C');
    });

    test('converte entre Celsius e Fahrenheit', () {
      expect(TemperatureUtils.celsiusToFahrenheit(100), closeTo(212, 0.001));
      expect(TemperatureUtils.fahrenheitToCelsius(32), closeTo(0, 0.001));
    });
  });

  group('WeatherUtils', () {
    test('capitaliza só a primeira letra da descrição da API', () {
      expect(WeatherUtils.capitalizeFirst('CHUVA FORTE'), 'Chuva forte');
      expect(WeatherUtils.capitalizeFirst('céu limpo'), 'Céu limpo');
      expect(WeatherUtils.capitalizeFirst(''), '');
    });

    test('converte o vento de m/s, que é como a API entrega, para km/h', () {
      expect(WeatherUtils.msToKmh(10), closeTo(36, 0.001));
      expect(WeatherUtils.formatWindSpeed(5), '18.0 km/h');
    });

    test('mostra visibilidade em metros e, a partir de 1 km, em quilômetros',
        () {
      expect(WeatherUtils.formatVisibility(999), '999 m');
      expect(WeatherUtils.formatVisibility(1000), '1.0 km');
      expect(WeatherUtils.formatVisibility(10000), '10.0 km');
    });

    test('usa a rosa dos ventos em português e aceita graus fora da volta', () {
      expect(WeatherUtils.getWindDirection(0), 'N');
      expect(WeatherUtils.getWindDirection(90), 'L');
      expect(WeatherUtils.getWindDirection(180), 'S');
      expect(WeatherUtils.getWindDirection(270), 'O');
      expect(WeatherUtils.getWindDirection(350), 'N');
      expect(WeatherUtils.getWindDirection(-10), 'N');
    });

    test('classifica a intensidade do vento', () {
      expect(WeatherUtils.getWindIntensity(0.5), 'Calmo');
      expect(WeatherUtils.getWindIntensity(4.9), 'Brisa leve');
      expect(WeatherUtils.getWindIntensity(40), 'Vendaval');
    });

    test('formata umidade, pressão e chance de chuva', () {
      expect(WeatherUtils.formatHumidity(78), '78%');
      expect(WeatherUtils.formatPressure(1013), '1013 hPa');
      expect(WeatherUtils.formatRainChance(42.4), '42%');
      expect(WeatherUtils.formatRainChance(42.6), '43%');
    });

    test('formata o par de coordenadas com duas casas', () {
      expect(
        WeatherUtils.formatCoordinates(-23.5, -46.6),
        'Lat: -23.50° | Lng: -46.60°',
      );
    });
  });

  group('WeatherDateUtils', () {
    test('formata data, hora e data com hora no padrão brasileiro', () {
      final data = DateTime(2026, 1, 5, 7, 5);
      expect(WeatherDateUtils.formatDate(data), '05/01/2026');
      expect(WeatherDateUtils.formatTime(data), '07:05');
      expect(WeatherDateUtils.formatDateTime(data), '05/01/2026 07:05');
    });

    test('nomeia dias da semana e meses em português', () {
      // 04/01/2026 é um domingo, o caso que depende do `% 7` sobre o weekday.
      expect(WeatherDateUtils.formatWeekDay(DateTime(2026, 1, 4)), 'Dom');
      expect(WeatherDateUtils.formatWeekDay(DateTime(2026, 1, 5)), 'Seg');
      expect(
        WeatherDateUtils.formatWeekDayFull(DateTime(2026, 1, 4)),
        'Domingo',
      );
      expect(
        WeatherDateUtils.formatWeekDayFull(DateTime(2026, 1, 5)),
        'Segunda-feira',
      );
      expect(WeatherDateUtils.formatMonth(DateTime(2026, 3, 1)), 'Mar');
      expect(WeatherDateUtils.formatMonthFull(DateTime(2026, 3, 1)), 'Março');
    });

    test('conta dias inteiros, ignorando o horário', () {
      expect(
        WeatherDateUtils.daysBetween(
          DateTime.utc(2026, 1, 5, 23),
          DateTime.utc(2026, 1, 6, 1),
        ),
        1,
      );
      expect(
        WeatherDateUtils.daysBetween(
          DateTime.utc(2026, 1, 5),
          DateTime.utc(2026, 1, 5, 23),
        ),
        0,
      );
    });

    // A previsão chega no relógio da cidade: comparar com DateTime.now() faria
    // o app dizer "Amanhã" onde é "Hoje" para cidades em outro fuso.
    test('rotula o dia relativo a partir da referência informada', () {
      final cidade = DateTime.utc(2026, 1, 5, 1);

      expect(
        WeatherDateUtils.getRelativeDay(
          DateTime.utc(2026, 1, 5, 23),
          reference: cidade,
        ),
        'Hoje',
      );
      expect(
        WeatherDateUtils.getRelativeDay(
          DateTime.utc(2026, 1, 6, 1),
          reference: cidade,
        ),
        'Amanhã',
      );
      expect(
        WeatherDateUtils.getRelativeDay(
          DateTime.utc(2026, 1, 4, 22),
          reference: cidade,
        ),
        'Ontem',
      );
      expect(
        WeatherDateUtils.getRelativeDay(
          DateTime.utc(2026, 1, 8),
          reference: cidade,
        ),
        'Quinta-feira',
      );
      expect(
        WeatherDateUtils.getRelativeDay(
          DateTime.utc(2026, 1, 20),
          reference: cidade,
        ),
        '20/01/2026',
      );
    });

    test('isToday e isTomorrow também respeitam a referência', () {
      final cidade = DateTime.utc(2026, 1, 5, 23);

      expect(
        WeatherDateUtils.isToday(DateTime.utc(2026, 1, 5, 2), reference: cidade),
        isTrue,
      );
      expect(
        WeatherDateUtils.isTomorrow(
          DateTime.utc(2026, 1, 6, 1),
          reference: cidade,
        ),
        isTrue,
      );
      expect(
        WeatherDateUtils.isToday(DateTime.utc(2026, 1, 6, 1), reference: cidade),
        isFalse,
      );
    });

    test('humaniza o tempo decorrido', () {
      final agora = DateTime.utc(2026, 1, 5, 11, 30);

      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2026, 1, 5, 11, 29, 30),
          reference: agora,
        ),
        'agora há pouco',
      );
      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2026, 1, 5, 11, 10),
          reference: agora,
        ),
        'há 20 min',
      );
      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2026, 1, 5, 10),
          reference: agora,
        ),
        'há 1h',
      );
      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2026, 1, 2, 10),
          reference: agora,
        ),
        'há 3d',
      );
      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2025, 12, 20),
          reference: agora,
        ),
        'em 20/12/2025',
      );
    });

    test('data no futuro não vira tempo negativo', () {
      expect(
        WeatherDateUtils.getTimeAgo(
          DateTime.utc(2026, 1, 5, 12),
          reference: DateTime.utc(2026, 1, 5, 11),
        ),
        'agora há pouco',
      );
    });
  });
}
