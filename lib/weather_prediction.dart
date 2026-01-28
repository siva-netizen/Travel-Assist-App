import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting
import 'config/app_config.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _cityController = TextEditingController();
  DateTime? _selectedDate;
  String? _weatherResult;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> fetchWeather(String cityName, String date) async {
    final String apiKey = AppConfig.weatherbitApiKey;
    final String url =
        'https://api.weatherbit.io/v2.0/forecast/daily?city=$cityName&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> forecastList = data['data'];

      // Find the weather for the specified date
      for (var forecast in forecastList) {
        if (forecast['datetime'] == date) {
          String description = forecast['weather']['description'];
          setState(() {
            _weatherResult = "Weather on $date in $cityName: $description";
          });
          return;
        }
      }

      setState(() {
        _weatherResult = "No weather data available for the selected date.";
      });
    } else {
      setState(() {
        _weatherResult = "Error fetching weather data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Forecast')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: 'Enter City Name'),
            ),
            SizedBox(height: 20),
            Text(
              _selectedDate == null
                  ? 'No date selected!'
                  : 'Selected date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Date'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_cityController.text.isNotEmpty && _selectedDate != null) {
                  String city = _cityController.text;
                  String formattedDate = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_selectedDate!);
                  fetchWeather(city, formattedDate);
                } else {
                  setState(() {
                    _weatherResult = "Please enter a city and select a date.";
                  });
                }
              },
              child: Text('Fetch Weather'),
            ),
            SizedBox(height: 20),
            _weatherResult != null
                ? Text(_weatherResult!, style: TextStyle(fontSize: 18))
                : Container(),
          ],
        ),
      ),
    );
  }
}
