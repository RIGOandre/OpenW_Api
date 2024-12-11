import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.racingSansOneTextTheme(),
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  List<dynamic>? forecastData;
  String city = "São Paulo";
  String apiKey = '';
  List<String> cities = ["São Paulo", "Concórdia", "Uganda"];

  Future<void> fetchWeatherData() async {
    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=pt_br';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=pt_br';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = json.decode(weatherResponse.body);
          forecastData = json.decode(forecastResponse.body)['list'];
        });
      } else {
        print('Falha ao buscar dados de clima ou previsão');
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
    }
  }

  void selectCity(String selectedCity) {
    setState(() {
      city = selectedCity;
    });
    fetchWeatherData();
    Navigator.pop(context);
  }

  void addCity(String newCity) {
    setState(() {
      cities.add(newCity);
    });
    Navigator.pop(context);
  }

  void deleteCity(String cityToDelete) {
    setState(() {
      cities.remove(cityToDelete);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  // obter o GIF com base no código do clima
  String getWeatherGif(String weatherCode) {
    const gifMap = {
      "01d": "assets/images/sunny.gif", // Céu limpo durante o dia
      "01n": "assets/images/clear_night.gif", // Céu limpo à noite
      "02d": "assets/images/cloudy.gif", // Poucas nuvens durante o dia
      "02n": "assets/images/cloudy.gif", // Poucas nuvens à noite
      "03d": "assets/images/cloudy.gif", // Nublado
      "03n": "assets/images/cloudy.gif",
      "04d": "assets/images/overcast.gif", // Nublado pesado
      "04n": "assets/images/overcast.gif",  
      "09d": "assets/images/rain_d.gif", // Chuva
      "09n": "assets/images/rain_n.gif",
      "10d": "assets/images/heavy_rain.gif", // Chuva intensa
      "10n": "assets/images/heavy_rain.gif", // rain_n
      "11d": "assets/images/thunderstorm.gif", // Tempestade
      "11n": "assets/images/thunderstorm.gif",
      "13d": "assets/images/snow_d.gif", // Neve
      "13n": "assets/images/snow_n.gif",
      "50d": "assets/images/fog.gif", // Neblina diminuir tamanho 
      "50n": "assets/images/fog.gif",
    };

    return gifMap[weatherCode] ?? "assets/images/default.gif";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(city),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchWeatherData,
          ),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Selecione ou Adicione uma Cidade',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return ListTile(
                    title: Text(city),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCity(city),
                    ),
                    onTap: () => selectCity(city),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: Text("Adicionar Cidade"),
                onPressed: () => _showAddCityDialog(),
              ),
            ),
          ],
        ),
      ),
      body: weatherData == null || forecastData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Informações atuais
                  Column(
                    children: [
                      Text(
                        '${weatherData!['main']['temp']}°C',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${weatherData!['weather'][0]['description']}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      Image.asset(
                        getWeatherGif(weatherData!['weather'][0]['icon']),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Localização
                  Text(
                    '${city}, ${weatherData!['sys']['country']}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Latitude: ${weatherData!['coord']['lat']} | Longitude: ${weatherData!['coord']['lon']}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 20),

                  // Previsão dos próximos dias
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Previsão para os próximos dias',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Table(
                          border: TableBorder.all(color: Colors.white),
                          children: _buildForecastRows(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Informações extras
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoCard(
                        label: 'Vento',
                        value: '${weatherData!['wind']['speed']} km/h',
                      ),
                      InfoCard(
                        label: 'Umidade',
                        value: '${weatherData!['main']['humidity']}%',
                      ),
                      InfoCard(
                        label: 'Sensação térmica',
                        value: '${weatherData!['main']['feels_like']}°C',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Nascer e pôr do sol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SunInfoCard(
                        label: 'Nascer do sol',
                        value: DateTime.fromMillisecondsSinceEpoch(
                                weatherData!['sys']['sunrise'] * 1000)
                            .toLocal()
                            .toIso8601String()
                            .substring(11, 16),
                      ),
                      SunInfoCard(
                        label: 'Pôr do sol',
                        value: DateTime.fromMillisecondsSinceEpoch(
                                weatherData!['sys']['sunset'] * 1000)
                            .toLocal()
                            .toIso8601String()
                            .substring(11, 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  List<TableRow> _buildForecastRows() {
    final days = <TableRow>[
      TableRow(
        children: [
          _buildTableCell('Dia'),
          _buildTableCell('Min'),
          _buildTableCell('Max'),
        ],
      ),
    ];

    final dailyData = forecastData!.where((data) {
      final date = DateTime.parse(data['dt_txt']);
      return date.hour == 12;
    }).take(5);

    for (var data in dailyData) {
      final date = DateTime.parse(data['dt_txt']);
      days.add(
        TableRow(
          children: [
            _buildTableCell(
                '${date.day}/${date.month} (${_getWeekday(date.weekday)})'),
            _buildTableCell('${data['main']['temp_min'].toStringAsFixed(1)}°C'),
            _buildTableCell('${data['main']['temp_max'].toStringAsFixed(1)}°C'),
          ],
        ),
      );
    }
    return days;
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado'
    ];
    return weekdays[weekday - 1];
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddCityDialog() {
    String newCity = "Lindóia dos Montes e Vales";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Adicionar Cidade"),
          content: TextField(
            onChanged: (value) {
              newCity = value;
            },
            decoration: InputDecoration(hintText: "Nome da cidade"),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text("Adicionar"),
              onPressed: () {
                if (newCity.isNotEmpty) {
                  addCity(newCity);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class SunInfoCard extends StatelessWidget {
  final String label;
  final String value;

  SunInfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
