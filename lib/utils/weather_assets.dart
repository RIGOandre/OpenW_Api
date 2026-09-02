/// Mapeia os códigos de ícone da OpenWeatherMap para as animações locais.
class WeatherAssets {
  const WeatherAssets._();

  static const String _basePath = 'assets/images';
  static const String _fallbackDay = '$_basePath/sunny.gif';
  static const String _fallbackNight = '$_basePath/clear_night.gif';
  static const String _heavyRain = '$_basePath/heavy_rain.gif';

  static const Map<String, String> _weatherIcons = <String, String>{
    '01d': '$_basePath/sunny.gif', // Céu limpo durante o dia
    '01n': '$_basePath/clear_night.gif', // Céu limpo à noite
    '02d': '$_basePath/cloudys.gif', // Poucas nuvens durante o dia
    '02n': '$_basePath/cloudy_night.gif', // Poucas nuvens à noite
    '03d': '$_basePath/cloudy.gif', // Nublado
    '03n': '$_basePath/cloudy.gif',
    '04d': '$_basePath/overcast.gif', // Nublado pesado
    '04n': '$_basePath/overcast.gif',
    '09d': '$_basePath/rain_d.gif', // Chuva
    '09n': '$_basePath/rain_n.gif',
    '10d': '$_basePath/rain_d.gif', // Chuva com sol
    '10n': '$_basePath/rain_n.gif',
    '11d': '$_basePath/thunderstorm.gif', // Tempestade
    '11n': '$_basePath/thunderstorm.gif',
    '13d': '$_basePath/snow_d.gif', // Neve
    '13n': '$_basePath/snow_n.gif',
    '50d': '$_basePath/fog.gif', // Neblina
    '50n': '$_basePath/fog.gif',
  };

  /// Códigos de condição de chuva forte, muito forte e extrema.
  static const Set<int> _heavyRainConditions = <int>{502, 503, 504, 522, 531};

  /// Animação correspondente ao código de ícone da API.
  static String getWeatherGif(String weatherCode) {
    return _weatherIcons[weatherCode] ??
        (isDayTime(weatherCode) ? _fallbackDay : _fallbackNight);
  }

  /// Igual a [getWeatherGif], mas usa a animação de chuva forte quando o
  /// código de condição indica um temporal.
  static String forCondition(String weatherCode, int conditionId) {
    if (_heavyRainConditions.contains(conditionId)) return _heavyRain;
    return getWeatherGif(weatherCode);
  }

  /// A API marca os ícones noturnos com o sufixo `n`; o resto é tratado como dia.
  static bool isDayTime(String weatherCode) => !weatherCode.endsWith('n');
}
