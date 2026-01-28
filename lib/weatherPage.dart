import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'rideModePage.dart';
import 'getWeather.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService = WeatherService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth instance

  String startLocation = '';
  String destination = '';
  List<String> subDestinations = [];
  bool isRidingMode = false;

  final TextEditingController _subDestinationController = TextEditingController();
  List<Map<String, String>> weatherDataList = [];

  @override
  void dispose() {
    _subDestinationController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getWeather(String location) async {
    try {
      final weatherData = await _weatherService.getCurrentWeather(location);
      return {
        'location': location,
        'temperature': weatherData['current']['temp_c'].toString(),
        'condition': weatherData['current']['condition']['text'],
      };
    } catch (e) {
      return {'location': location, 'error': 'Failed to fetch weather'};
    }
  }

  Future<void> _fetchWeatherForAllLocations() async {
    final allLocations = [startLocation, destination, ...subDestinations];
    final List<Map<String, String>> fetchedWeather = [];

    for (String location in allLocations) {
      if (location.isNotEmpty) {
        final weather = await _getWeather(location);
        fetchedWeather.add(weather);
      }
    }

    setState(() {
      weatherDataList = fetchedWeather;
    });

    // Add weather data to Firestore
    await _addWeatherDataToFirestore(allLocations, fetchedWeather);
  }

  Future<void> _addWeatherDataToFirestore(List<String> locations, List<Map<String, String>> fetchedWeather) async {
    // Get the user's email
    String userEmail = _auth.currentUser?.email ?? 'unknown@example.com'; // Replace with appropriate fallback

    // Prepare data for Firestore
    final weatherData = {
      'start_location': startLocation,
      'destination': destination,
      'sub_destinations': subDestinations,
      'current_weather': fetchedWeather.map((weather) {
        return {
          'location': weather['location'],
          'temperature': weather['temperature'],
          'condition': weather['condition'],
        };
      }).toList(),
      'user_email': userEmail,
    };

    // Add the data to Firestore
    await _firestore.collection('weather_forecast').add(weatherData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Start Location'),
              onChanged: (value) {
                startLocation = value;
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Destination'),
              onChanged: (value) {
                destination = value;
              },
            ),
            SingleChildScrollView(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subDestinationController,
                      decoration: const InputDecoration(labelText: 'Sub-Destination'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (_subDestinationController.text.isNotEmpty) {
                          subDestinations.add(_subDestinationController.text);
                          _subDestinationController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: startLocation.isEmpty && destination.isEmpty
                  ? null
                  : _fetchWeatherForAllLocations,
              child: const Text('Get Weather for All Locations'),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: weatherDataList.isEmpty
                  ? const Center(child: Text('No weather data available.'))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Temp (°C)', style: TextStyle(fontSize: 15))),
                    DataColumn(label: Text('Condition')),
                  ],
                  rows: weatherDataList.map((data) {
                    return DataRow(
                      cells: [
                        DataCell(Text(data['location'] ?? '')),
                        DataCell(Text(data.containsKey('error')
                            ? 'Error'
                            : data['temperature'] ?? 'N/A')),
                        DataCell(Text(data.containsKey('error')
                            ? data['error']!
                            : data['condition'] ?? 'N/A')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Riding Mode'),
              value: isRidingMode,
              onChanged: (value) {
                setState(() {
                  isRidingMode = value;
                });
                if (value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideModePage(
                        startLocation: startLocation,
                        destination: destination,
                        subDestinations: subDestinations,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
