import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/app_config.dart';

class LocationService {
  final String apiKey = AppConfig.distanceMatrixApiKey;

  // Method to fetch sub-destinations
  Future<List<String>> fetchSubDestinations(
    String origin,
    String destination,
  ) async {
    final url = Uri.parse(
      'https://api.distancematrix.ai/maps/api/distancematrix/json?origins=$origin&destinations=$destination&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<String> subDestinations = [];
      if (data['rows'].isNotEmpty) {
        // Assuming that the response contains valid data
        for (var address in data['destination_addresses']) {
          subDestinations.add(address);
        }
      }

      return subDestinations;
    } else {
      throw Exception(
        'Failed to load sub-destinations: ${response.reasonPhrase}',
      );
    }
  }
}
