import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String city = "São Paulo"; 
  String apiKey = ''; 
  List<String> cities = ["São Paulo", "Concórdia", "Uganda"]; 

  Future<void> fetchWeatherData() async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=pt_br';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
      });
    } else {
      print('Falha ao buscar dados de clima');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        // title: Text('$city - ${weatherData?['sys']['country'] ?? ''}'),
        backgroundColor: Colors.blue,
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: fetchWeatherData,
        //   ),
        // ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
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
                      onPressed: () {
                        deleteCity(city);
                      },
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
                onPressed: () {
                  _showAddCityDialog();
                },
              ),
            ),
          ],
        ),
      ),
      body: weatherData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // icone e temperatra
                  Column(
                    children: [
                      Text(
                        '${weatherData!['main']['temp']}°C',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${weatherData!['weather'][0]['description']}',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                      Image.network(
                        'https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png',
                        scale: 0.9,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // detalhes do local
                  Text(
                    '${city}, ${weatherData!['sys']['country']}',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Latitude: ${weatherData!['coord']['lat']} | Longitude: ${weatherData!['coord']['lon']}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 20),

                  // linha de previsao
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(6, (index) {
                        return Column(
                          children: [
                            Text(
                              '${9 + index * 3}:00',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              '${18 - index}°C',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 20),

                  //  detalhes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoCard(
                        label: 'vento',
                        value: '${weatherData!['wind']['speed']} km/h',
                      ),
                      InfoCard(
                        label: 'umidade',
                        value: '${weatherData!['main']['humidity']}%',
                      ),
                      InfoCard(
                        label: 'sensação térmica',
                        value: '${weatherData!['main']['feels_like']}°C',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // nascer e por
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SunInfoCard(
                        label: 'nascer do sol',
                        value: DateTime.fromMillisecondsSinceEpoch(
                                weatherData!['sys']['sunrise'] * 1000)
                            .toLocal()
                            .toIso8601String()
                            .substring(11, 16),
                      ),
                      SunInfoCard(
                        label: 'pôr do sol',
                        value: DateTime.fromMillisecondsSinceEpoch(
                                weatherData!['sys']['sunset'] * 1000)
                            .toLocal()
                            .toIso8601String()
                            .substring(11, 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  void _showAddCityDialog() {
    String newCity = "";
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
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// Wvento, umidade
class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }
}

// nascer e por
class SunInfoCard extends StatelessWidget {
  final String label;
  final String value;

  SunInfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }
}
