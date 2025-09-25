import 'package:intl/intl.dart';

/// Classe utilitária para formatação de temperaturas
class TemperatureUtils {
  /// Formata uma temperatura em Celsius com símbolo
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°C';
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
  /// Capitaliza a primeira letra de uma string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Formata umidade como percentual
  static String formatHumidity(num humidity) {
    return '${humidity.round()}%';
  }

  /// Formata velocidade do vento
  static String formatWindSpeed(double windSpeed) {
    return '${windSpeed.toStringAsFixed(1)} km/h';
  }

  /// Formata pressão atmosférica
  static String formatPressure(num pressure) {
    return '${pressure.round()} hPa';
  }

  /// Formata visibilidade
  static String formatVisibility(double visibility) {
    if (visibility >= 1000) {
      return '${(visibility / 1000).toStringAsFixed(1)} km';
    }
    return '${visibility.round()} m';
  }

  /// Obtém a descrição da direção do vento
  static String getWindDirection(double degrees) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    
    int index = ((degrees + 11.25) / 22.5).floor() % 16;
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
}

/// Classe utilitária para formatação de datas e horários
class WeatherDateUtils {
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
      'Quinta-feira', 'Sexta-feira', 'Sábado'
    ];
    return weekDaysFull[date.weekday % 7];
  }

  /// Retorna o mês abreviado
  static String formatMonth(DateTime date) {
    const monthsShort = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return monthsShort[date.month - 1];
  }

  /// Retorna o mês completo
  static String formatMonthFull(DateTime date) {
    const monthsFull = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return monthsFull[date.month - 1];
  }

  /// Formata data relativa (Hoje, Amanhã, etc.)
  static String getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final difference = targetDate.difference(today).inDays;
    
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

  /// Calcula a diferença de tempo de forma humanizada
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Agora há pouco';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays}d';
    } else {
      return formatDate(date);
    }
  }

  /// Verifica se uma data é hoje
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && 
           date.month == now.month && 
           date.year == now.year;
  }

  /// Verifica se uma data é amanhã
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.day == tomorrow.day && 
           date.month == tomorrow.month && 
           date.year == tomorrow.year;
  }
}