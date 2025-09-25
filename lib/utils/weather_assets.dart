class WeatherAssets {
  static const String _basePath = 'assets/images';
  
  static const Map<String, String> _weatherIcons = {
    "01d": "$_basePath/sunny.gif", // Céu limpo durante o dia
    "01n": "$_basePath/clear_night.gif", // Céu limpo à noite
    "02d": "$_basePath/cloudys.gif", // Poucas nuvens durante o dia
    "02n": "$_basePath/cloudy_night.gif", // Poucas nuvens à noite
    "03d": "$_basePath/cloudy.gif", // Nublado
    "03n": "$_basePath/cloudy.gif",
    "04d": "$_basePath/overcast.gif", // Nublado pesado
    "04n": "$_basePath/overcast.gif",
    "09d": "$_basePath/rain_d.gif", // Chuva
    "09n": "$_basePath/rain_n.gif",
    "10d": "$_basePath/rain_d.gif", // Chuva intensa
    "10n": "$_basePath/rain_n.gif",
    "11d": "$_basePath/thunderstorm.gif", // Tempestade
    "11n": "$_basePath/thunderstorm.gif",
    "13d": "$_basePath/snow_d.gif", // Neve
    "13n": "$_basePath/snow_n.gif",
    "50d": "$_basePath/fog.gif", // Neblina
    "50n": "$_basePath/fog.gif",
  };

  static String getWeatherGif(String weatherCode) {
    return _weatherIcons[weatherCode] ?? _weatherIcons["01d"]!;
  }

  static bool isDayTime(String weatherCode) {
    return weatherCode.endsWith('d');
  }
}