import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/app_config.dart';

class WeatherService {
  final String apiKey = AppConfig.weatherApiKey;

  // Method to get the forecast for multiple days
  Future<Map<String, dynamic>> getForecastByLocation(
    String location,
    int days,
  ) async {
    final url = Uri.parse(
      'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=$days',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load forecast data for $location');
    }
  }

  // New method to get the current weather
  Future<Map<String, dynamic>> getCurrentWeather(String location) async {
    final url = Uri.parse(
      'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$location',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load current weather data for $location');
    }
  }
}
