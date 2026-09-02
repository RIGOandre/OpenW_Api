import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/app_exception.dart';
import 'models/weather_model.dart';
import 'services/city_service.dart';
import 'services/weather_repository.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'utils/weather_assets.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/forecast_widget.dart';
import 'widgets/info_cards.dart';
import 'widgets/weather_error_view.dart';
import 'widgets/weather_loading_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Explorer',
      theme: AppTheme.build(),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  // Services
  late final WeatherRepository _repository;
  late final CityService _cityService;

  // State
  WeatherSnapshot? _snapshot;
  String _selectedCity = 'São Paulo';
  List<String> _cities = <String>[];
  bool _isLoading = true;
  AppException? _error;

  /// Cada busca recebe um número; respostas de buscas antigas são descartadas
  /// para que trocar de cidade rápido não deixe a tela com o dado errado.
  int _requestId = 0;

  // Animations
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _fadeAnimation;

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
    // O repositório fecha o cliente HTTP. O banco fica de fora: o
    // DatabaseHelper é único no aplicativo e não pertence a esta tela.
    _repository.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _repository = WeatherRepository();
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
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadCities();
    } catch (error) {
      // Falhar ao ler a lista não impede mostrar o clima da cidade padrão.
      _showError(error);
    }
    if (!mounted) return;

    await _loadLastSelectedCity();
    if (!mounted) return;

    await _fetchWeatherData(_selectedCity);
  }

  /// Relê a lista de cidades e devolve o que foi lido.
  ///
  /// Quem chama precisa da lista nova para decidir: o campo [_cities] só é
  /// atualizado se a tela ainda estiver montada.
  Future<List<String>> _loadCities() async {
    final cities = await _cityService.getCities();
    if (!mounted) return cities;

    setState(() {
      _cities = cities;
    });
    return cities;
  }

  Future<void> _loadLastSelectedCity() async {
    try {
      final lastCity = await _cityService.getLastSelectedCity();
      if (!mounted) return;

      setState(() {
        _selectedCity = lastCity;
      });
    } catch (error) {
      // O serviço já cai na cidade padrão; aqui fica só o rastro no log.
      debugPrint('Falha ao ler a última cidade selecionada: $error');
    }
  }

  Future<void> _fetchWeatherData(
    String city, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    // Sem chave configurada não vale gastar uma ida à rede para falhar igual.
    if (!_repository.hasApiKey) {
      setState(() {
        _error = const AppException.missingApiKey();
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _repository.load(city, forceRefresh: forceRefresh);
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
      // `from: 0` porque o fade precisa recomeçar a cada troca de cidade.
      _animationController.forward(from: 0);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = AppException.from(error);
        _isLoading = false;
      });
      return;
    }

    // Guardar a escolha é o último passo: uma falha aqui não pode transformar
    // um carregamento bem-sucedido em tela de erro.
    await _cityService.saveLastSelectedCity(city);
  }

  Future<void> _refreshData() async {
    _refreshAnimationController.repeat();
    try {
      // Atualizar de propósito ignora o cache: aqui o usuário quer dado novo.
      await _fetchWeatherData(_selectedCity, forceRefresh: true);
    } finally {
      // O ícone não pode ficar girando para sempre se a busca falhar.
      if (mounted) {
        _refreshAnimationController
          ..stop()
          ..reset();
      }
    }
  }

  void _retry() {
    _fetchWeatherData(_selectedCity, forceRefresh: true);
  }

  /// Troca a cidade exibida. Fechar o menu lateral é com quem chama.
  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
    });
    _fetchWeatherData(city);
  }

  Future<void> _addCity(String cityName) async {
    final city = cityName.trim();
    if (city.isEmpty) return;

    try {
      await _cityService.addCity(city);
      await _loadCities();
      _showMessage('Cidade "$city" adicionada com sucesso!',
          background: Colors.green);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteCity(String city) async {
    // A regra de não remover a última cidade mora no CityService, que é quem
    // sabe o número certo; aqui só se exibe a mensagem que vier de lá.
    try {
      await _cityService.removeCity(city);
      final cities = await _loadCities();
      if (!mounted) return;

      // Se a cidade aberta saiu da lista, cair na primeira que sobrou.
      if (cities.isNotEmpty && !cities.contains(_selectedCity)) {
        _selectCity(cities.first);
      }
      _showMessage('Cidade "$city" removida com sucesso!',
          background: Colors.orange);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    final failure = AppException.from(error);
    // A mensagem do AppException já vem pronta para o usuário; o erro de
    // origem fica no log, que é onde ele serve para alguma coisa.
    if (failure.cause != null) {
      debugPrint('Falha em ${failure.type.name}: ${failure.cause}');
    }
    _showMessage(failure.message, background: Colors.red);
  }

  void _showMessage(String message, {required Color background}) {
    // Todo aviso sai de um `catch` assíncrono: a tela pode já ter sido fechada.
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showAddCityDialog() async {
    // O diálogo devolve o nome digitado e se fecha sozinho: assim a gravação
    // acontece sem ninguém mexer na pilha de rotas depois de um `await`.
    final city = await showDialog<String>(
      context: context,
      builder: (_) => const _AddCityDialog(),
    );
    if (!mounted || city == null) return;

    await _addCity(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  /// Nome no topo da tela.
  ///
  /// O nome que a API devolveu é o melhor acabado, mas ele ainda é o da cidade
  /// anterior enquanto a busca nova não termina — aí vale a cidade escolhida.
  String get _appBarTitle {
    final snapshot = _snapshot;
    if (_isLoading || _error != null || snapshot == null) return _selectedCity;
    return snapshot.weather.cityName;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _appBarTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        RotationTransition(
          // O controller entra direto como `turns` para o giro sair contínuo,
          // sem a aceleração e a freada que uma curva daria a cada volta.
          turns: _refreshAnimationController,
          child: IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.appBar),
      ),
    );
  }

  Widget _buildDrawer() {
    return CustomDrawer(
      cities: _cities,
      currentCity: _selectedCity,
      // Fechar o menu só é seguro aqui, no toque, antes de qualquer `await`.
      onCitySelected: (city) {
        Navigator.pop(context);
        _selectCity(city);
      },
      onCityDeleted: _deleteCity,
      onAddCity: _showAddCityDialog,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const WeatherLoadingWidget();
    }

    final error = _error;
    if (error != null) {
      return WeatherErrorView(
        message: _errorMessage(error),
        icon: _errorIcon(error.type),
        title: _errorTitle(error.type),
        onRetry: _retry,
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Center(
        child: Text(
          'Nenhum dado disponível',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildWeatherContent(snapshot),
    );
  }

  /// Acrescenta a instrução que falta em cada tipo de falha: sem chave
  /// configurada, insistir no botão não resolve; com cidade inexistente, a
  /// saída está no menu lateral.
  String _errorMessage(AppException error) {
    switch (error.type) {
      case AppErrorType.configuration:
      case AppErrorType.unauthorized:
        return '${error.message}\n\n'
            'flutter run --dart-define-from-file=.env';
      case AppErrorType.notFound:
        return '${error.message}\n'
            'Você também pode escolher outra cidade no menu.';
      default:
        return error.message;
    }
  }

  IconData _errorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.offline:
      case AppErrorType.network:
        return Icons.cloud_off;
      case AppErrorType.timeout:
        return Icons.timer_off;
      case AppErrorType.notFound:
        return Icons.location_off;
      case AppErrorType.configuration:
      case AppErrorType.unauthorized:
        return Icons.vpn_key;
      case AppErrorType.database:
        return Icons.storage;
      default:
        return Icons.error_outline;
    }
  }

  String _errorTitle(AppErrorType type) {
    switch (type) {
      case AppErrorType.offline:
      case AppErrorType.network:
        return 'Sem conexão';
      case AppErrorType.timeout:
        return 'Demorou demais';
      case AppErrorType.notFound:
        return 'Cidade não encontrada';
      case AppErrorType.configuration:
      case AppErrorType.unauthorized:
        return 'Chave da API';
      case AppErrorType.database:
        return 'Dados locais';
      case AppErrorType.server:
        return 'Servidor com problema';
      default:
        return 'Oops!';
    }
  }

  Widget _buildWeatherContent(WeatherSnapshot snapshot) {
    final weather = snapshot.weather;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.background(isDay: weather.isDay),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCacheBanner(snapshot),
            _buildCurrentWeatherCard(weather),
            const SizedBox(height: 24),
            _buildLocationCard(weather),
            const SizedBox(height: 24),
            // A referência é a hora da cidade: sem ela, "Hoje" e "Amanhã"
            // mentem para quem consulta um lugar em outro fuso.
            ForecastWidget(
              forecast: snapshot.dailyForecast,
              reference: snapshot.cityNow,
            ),
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

  /// Aviso de que o conteúdo saiu do banco local, e não da rede.
  Widget _buildCacheBanner(WeatherSnapshot snapshot) {
    if (!snapshot.fromCache) return const SizedBox.shrink();

    final savedAt = WeatherDateUtils.getTimeAgo(snapshot.updatedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppTheme.glassCard(radius: 12),
        child: Row(
          children: [
            Icon(
              snapshot.isStale ? Icons.cloud_off : Icons.history,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                snapshot.isStale
                    ? 'Sem conexão. Último clima salvo $savedAt'
                    : 'Dados salvos no aparelho $savedAt',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherModel weather) {
    final description = WeatherUtils.capitalizeFirst(weather.description);

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
            description,
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
                // `forCondition` troca a chuva comum pela animação de temporal
                // quando o código da condição indica chuva forte.
                WeatherAssets.forCondition(weather.icon, weather.conditionId),
                fit: BoxFit.contain,
                semanticLabel: description,
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
      decoration: AppTheme.glassCard(),
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
              // Flexible para nome de cidade longo quebrar em vez de estourar.
              Flexible(
                child: Text(
                  '${weather.cityName}, ${weather.country}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            WeatherUtils.formatCoordinates(weather.latitude, weather.longitude),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Medição das ${WeatherDateUtils.formatTime(weather.observedAt)}, '
            'hora da cidade',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
      // 1.8 deixava o cartão com uns poucos pixels de sobra para ícone e dois
      // textos; 1.6 dá folga sem mudar a grade.
      childAspectRatio: 1.6,
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
          value: '${WeatherUtils.formatWindSpeed(weather.windSpeed)} '
              '${WeatherUtils.getWindDirection(weather.windDegrees)}',
          icon: Icons.air,
          iconColor: Colors.grey[300],
        ),
        InfoCard(
          label: 'Pressão',
          value: WeatherUtils.formatPressure(weather.pressure),
          icon: Icons.compress,
          iconColor: Colors.purple[300],
        ),
        InfoCard(
          label: 'Mínima e máxima',
          value: '${TemperatureUtils.formatDegrees(weather.tempMin)} / '
              '${TemperatureUtils.formatDegrees(weather.tempMax)}',
          icon: Icons.swap_vert,
          iconColor: Colors.teal[200],
        ),
        InfoCard(
          label: 'Visibilidade',
          value: WeatherUtils.formatVisibility(weather.visibility),
          icon: Icons.visibility,
          iconColor: Colors.cyan[200],
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
}

/// Diálogo de cadastro de cidade.
///
/// Cuida do próprio `TextEditingController` — criado e descartado aqui, em vez
/// de ficar solto a cada abertura — e devolve o nome digitado pelo `Navigator`.
class _AddCityDialog extends StatefulWidget {
  const _AddCityDialog();

  @override
  State<_AddCityDialog> createState() => _AddCityDialogState();
}

class _AddCityDialogState extends State<_AddCityDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final city = _controller.text.trim();
    if (city.isEmpty) return;

    Navigator.pop(context, city);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Cidade'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Nome da cidade',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) => ElevatedButton(
            // Campo vazio não tem o que salvar.
            onPressed: value.text.trim().isEmpty ? null : _confirm,
            child: const Text('Adicionar'),
          ),
        ),
      ],
    );
  }
}
