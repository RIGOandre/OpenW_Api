import 'package:intl/intl.dart';

/// Classe utilitária para formatação de temperaturas
class TemperatureUtils {
  const TemperatureUtils._();

  /// Formata uma temperatura em Celsius com símbolo
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°C';
  }

  /// Formata uma temperatura sem a unidade, para composições curtas
  static String formatDegrees(double temperature) {
    return '${temperature.round()}°';
  }

  /// Converte Celsius para Fahrenheit
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  /// Converte Fahrenheit para Celsius
  static double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  /// Formata temperatura com uma casa decimal se necessário
  static String formatTemperaturePrecise(double temperature) {
    if (temperature == temperature.roundToDouble()) {
      return '${temperature.round()}°C';
    }
    return '${temperature.toStringAsFixed(1)}°C';
  }
}

/// Classe utilitária para formatação de dados meteorológicos
class WeatherUtils {
  const WeatherUtils._();

  /// Capitaliza a primeira letra de uma string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Formata umidade como percentual
  static String formatHumidity(num humidity) {
    return '${humidity.round()}%';
  }

  /// Converte metros por segundo em quilômetros por hora
  static double msToKmh(double metersPerSecond) => metersPerSecond * 3.6;

  /// Formata velocidade do vento
  ///
  /// A OpenWeatherMap entrega o vento em m/s quando `units=metric`, então a
  /// conversão acontece aqui antes de mostrar o valor em km/h.
  static String formatWindSpeed(double metersPerSecond) {
    return '${msToKmh(metersPerSecond).toStringAsFixed(1)} km/h';
  }

  /// Formata pressão atmosférica
  static String formatPressure(num pressure) {
    return '${pressure.round()} hPa';
  }

  /// Formata visibilidade
  static String formatVisibility(num visibility) {
    if (visibility >= 1000) {
      return '${(visibility / 1000).toStringAsFixed(1)} km';
    }
    return '${visibility.round()} m';
  }

  /// Obtém a descrição da direção do vento na rosa dos ventos em português
  static String getWindDirection(double degrees) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'L', 'ESE', 'SE', 'SSE',
      'S', 'SSO', 'SO', 'OSO',
      'O', 'ONO', 'NO', 'NNO',
    ];

    final index = ((degrees % 360 + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Determina a intensidade do vento
  static String getWindIntensity(double windSpeed) {
    if (windSpeed < 1) return 'Calmo';
    if (windSpeed < 5) return 'Brisa leve';
    if (windSpeed < 11) return 'Brisa suave';
    if (windSpeed < 19) return 'Brisa moderada';
    if (windSpeed < 28) return 'Brisa forte';
    if (windSpeed < 38) return 'Vento forte';
    return 'Vendaval';
  }

  /// Formata chance de chuva como percentual
  static String formatRainChance(num rainChance) {
    return '${rainChance.round()}%';
  }

  /// Formata um par de coordenadas geográficas
  static String formatCoordinates(double latitude, double longitude) {
    return 'Lat: ${latitude.toStringAsFixed(2)}° | '
        'Lng: ${longitude.toStringAsFixed(2)}°';
  }
}

/// Classe utilitária para formatação de datas e horários
class WeatherDateUtils {
  const WeatherDateUtils._();

  /// Formata uma data no formato brasileiro (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formata apenas o horário (HH:mm)
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Formata data e hora completa
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Retorna o dia da semana abreviado
  static String formatWeekDay(DateTime date) {
    const weekDaysShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return weekDaysShort[date.weekday % 7];
  }

  /// Retorna o dia da semana completo
  static String formatWeekDayFull(DateTime date) {
    const weekDaysFull = [
      'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado',
    ];
    return weekDaysFull[date.weekday % 7];
  }

  /// Retorna o mês abreviado
  static String formatMonth(DateTime date) {
    const monthsShort = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return monthsShort[date.month - 1];
  }

  /// Retorna o mês completo
  static String formatMonthFull(DateTime date) {
    const monthsFull = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return monthsFull[date.month - 1];
  }

  /// Formata data relativa (Hoje, Amanhã, etc.)
  ///
  /// [reference] permite comparar com a hora da cidade consultada em vez da
  /// hora do aparelho, que pode estar em outro fuso.
  static String getRelativeDay(DateTime date, {DateTime? reference}) {
    final difference = daysBetween(reference ?? DateTime.now(), date);

    switch (difference) {
      case 0:
        return 'Hoje';
      case 1:
        return 'Amanhã';
      case -1:
        return 'Ontem';
      default:
        if (difference > 1 && difference < 7) {
          return formatWeekDayFull(date);
        }
        return formatDate(date);
    }
  }

  /// Diferença em dias entre duas datas, ignorando horário e horário de verão
  static int daysBetween(DateTime from, DateTime to) {
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final toDay = DateTime.utc(to.year, to.month, to.day);
    return toDay.difference(fromDay).inDays;
  }

  /// Calcula a diferença de tempo de forma humanizada
  static String getTimeAgo(DateTime date, {DateTime? reference}) {
    final difference = (reference ?? DateTime.now()).difference(date);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'agora há pouco';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays}d';
    } else {
      return 'em ${formatDate(date)}';
    }
  }

  /// Verifica se uma data é hoje
  static bool isToday(DateTime date, {DateTime? reference}) {
    return daysBetween(reference ?? DateTime.now(), date) == 0;
  }

  /// Verifica se uma data é amanhã
  static bool isTomorrow(DateTime date, {DateTime? reference}) {
    return daysBetween(reference ?? DateTime.now(), date) == 1;
  }
}
