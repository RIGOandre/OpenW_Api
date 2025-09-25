import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'services/city_service.dart';
import 'widgets/weather_loading_widget.dart';
import 'widgets/error_widget.dart' as custom;
import 'widgets/info_cards.dart';
import 'widgets/forecast_widget.dart';
import 'widgets/custom_drawer.dart';
import 'utils/weather_assets.dart';
import 'utils/formatters.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Explorer',
      theme: _buildTheme(),
      home: WeatherScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: const Color(0xFF1E3A8A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  // Services
  late final WeatherService _weatherService;
  late final CityService _cityService;
  
  // State
  WeatherModel? _currentWeather;
  List<ForecastModel>? _forecast;
  String _selectedCity = "São Paulo";
  List<String> _cities = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Animations
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshAnimationController.dispose();
    _weatherService.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _weatherService = WeatherService();
    _cityService = CityService();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadInitialData() async {
    await _loadCities();
    await _loadLastSelectedCity();
    await _fetchWeatherData();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.getCities();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      _showError('Erro ao carregar cidades: $e');
    }
  }

  Future<void> _loadLastSelectedCity() async {
    try {
      final lastCity = await _cityService.getLastSelectedCity();
      setState(() {
        _selectedCity = lastCity;
      });
    } catch (e) {
      // Ignore error, use default city
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _weatherService.getCurrentWeather(_selectedCity),
        _weatherService.getForecast(_selectedCity),
      ]);

      final weather = results[0] as WeatherModel;
      final forecast = results[1] as List<ForecastModel>;

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _isLoading = false;
      });

      await _cityService.saveLastSelectedCity(_selectedCity);
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    _refreshAnimationController.repeat();
    await _fetchWeatherData();
    _refreshAnimationController.stop();
    _refreshAnimationController.reset();
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
    });
    Navigator.pop(context);
    _fetchWeatherData();
  }

  Future<void> _addCity(String cityName) async {
    if (cityName.trim().isEmpty) return;
    
    try {
      await _cityService.addCity(cityName.trim());
      await _loadCities();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cidade "$cityName" adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Erro ao adicionar cidade: $e');
    }
  }

  Future<void> _deleteCity(String city) async {
    if (_cities.length <= 1) {
      _showError('Não é possível remover a última cidade');
      return;
    }

    try {
      await _cityService.removeCity(city);
      await _loadCities();
      
      if (_selectedCity == city && _cities.isNotEmpty) {
        _selectCity(_cities.first);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cidade "$city" removida com sucesso!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _showError('Erro ao remover cidade: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddCityDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Cidade'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nome da cidade',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _addCity(textController.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentWeather?.cityName ?? _selectedCity,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        RotationTransition(
          turns: _rotationAnimation,
          child: IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[800]!,
              Colors.blue[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return CustomDrawer(
      cities: _cities,
      currentCity: _selectedCity,
      onCitySelected: _selectCity,
      onCityDeleted: _deleteCity,
      onAddCity: _showAddCityDialog,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const WeatherLoadingWidget();
    }
    
    if (_errorMessage != null) {
      return custom.ErrorWidget(
        message: _errorMessage!,
        onRetry: _fetchWeatherData,
      );
    }
    
    if (_currentWeather == null || _forecast == null) {
      return const Center(
        child: Text(
          'Nenhum dado disponível',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    final weather = _currentWeather!;
    final forecast = _forecast!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getGradientColors(weather.icon),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCurrentWeatherCard(weather),
            const SizedBox(height: 24),
            _buildLocationCard(weather),
            const SizedBox(height: 24),
            ForecastWidget(forecast: forecast),
            const SizedBox(height: 24),
            _buildInfoCardsGrid(weather),
            const SizedBox(height: 24),
            _buildSunInfoCards(weather),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherModel weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            TemperatureUtils.formatTemperature(weather.temperature),
            style: const TextStyle(
              fontSize: 64,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            WeatherUtils.capitalizeFirst(weather.description),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Hero(
            tag: 'weather-icon',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.1),
              ),
              child: Image.asset(
                WeatherAssets.getWeatherGif(weather.icon),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.wb_sunny,
                    size: 80,
                    color: Colors.orange[300],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(WeatherModel weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${weather.cityName}, ${weather.country}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${weather.latitude.toStringAsFixed(2)}° | Lng: ${weather.longitude.toStringAsFixed(2)}°',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsGrid(WeatherModel weather) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        InfoCard(
          label: 'Sensação térmica',
          value: TemperatureUtils.formatTemperature(weather.feelsLike),
          icon: Icons.thermostat,
          iconColor: Colors.orange[300],
        ),
        InfoCard(
          label: 'Umidade',
          value: WeatherUtils.formatHumidity(weather.humidity),
          icon: Icons.water_drop,
          iconColor: Colors.blue[300],
        ),
        InfoCard(
          label: 'Vento',
          value: WeatherUtils.formatWindSpeed(weather.windSpeed),
          icon: Icons.air,
          iconColor: Colors.grey[300],
        ),
        InfoCard(
          label: 'Pressão',
          value: WeatherUtils.formatPressure(weather.pressure),
          icon: Icons.compress,
          iconColor: Colors.purple[300],
        ),
      ],
    );
  }

  Widget _buildSunInfoCards(WeatherModel weather) {
    return Row(
      children: [
        Expanded(
          child: SunInfoCard(
            label: 'Nascer do sol',
            value: WeatherDateUtils.formatTime(weather.sunrise),
            icon: Icons.wb_sunny,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SunInfoCard(
            label: 'Pôr do sol',
            value: WeatherDateUtils.formatTime(weather.sunset),
            icon: Icons.wb_twilight,
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(String icon) {
    if (WeatherAssets.isDayTime(icon)) {
      return [
        const Color(0xFF1E3A8A),
        const Color(0xFF3B82F6),
      ];
    } else {
      return [
        const Color(0xFF0F172A),
        const Color(0xFF1E293B),
      ];
    }
  }
}