import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // Required for compute
import 'dart:convert';
import 'config/app_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LocationPage());
  }
}

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Position? _currentPosition;
  List<dynamic> _restaurants = [];
  List<dynamic> _attractions = [];
  List<dynamic> _petrolBunks = [];
  final String hereApiKey = AppConfig.hereApiKey;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
        _fetchNearbyPlaces();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permission denied. Using default location.',
              ),
            ),
          );
        }
        // Use a default location for testing (e.g., New York)
        setState(() {
          _currentPosition = Position(
            latitude: 40.7128,
            longitude: -74.0060,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        _fetchNearbyPlaces();
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  // Background isolate function for parsing JSON
  static List<dynamic> parsePlaces(String responseBody) {
    final parsed = json.decode(responseBody);
    return parsed['items'] as List<dynamic>;
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition != null) {
      final double lat = _currentPosition!.latitude;
      final double lon = _currentPosition!.longitude;

      final String restaurantUrl =
          'https://discover.search.hereapi.com/v1/discover?at=$lat,$lon&q=restaurant&apiKey=$hereApiKey';
      final String attractionUrl =
          'https://discover.search.hereapi.com/v1/discover?at=$lat,$lon&q=attraction&apiKey=$hereApiKey';
      final String petrolBunksUrl =
          'https://discover.search.hereapi.com/v1/discover?at=$lat,$lon&q=petrol station&apiKey=$hereApiKey';

      try {
        // Fetch restaurants
        try {
          final restaurantResponse = await http.get(Uri.parse(restaurantUrl));
          print('Restaurant API Status: ${restaurantResponse.statusCode}');
          if (restaurantResponse.statusCode == 200) {
            final data = await compute(parsePlaces, restaurantResponse.body);
            setState(() {
              _restaurants = data;
            });
          } else {
            print('Restaurant API Error: ${restaurantResponse.body}');
          }
        } catch (e) {
          print('Error fetching restaurants: $e');
        }

        // Fetch attractions
        try {
          final attractionResponse = await http.get(Uri.parse(attractionUrl));
          print('Attraction API Status: ${attractionResponse.statusCode}');
          if (attractionResponse.statusCode == 200) {
            final data = await compute(parsePlaces, attractionResponse.body);
            setState(() {
              _attractions = data;
            });
          } else {
            print('Attraction API Error: ${attractionResponse.body}');
          }
        } catch (e) {
          print('Error fetching attractions: $e');
        }

        // Fetch petrol bunks
        try {
          final petrolBunksResponse = await http.get(Uri.parse(petrolBunksUrl));
          print('Petrol API Status: ${petrolBunksResponse.statusCode}');
          if (petrolBunksResponse.statusCode == 200) {
            final data = await compute(parsePlaces, petrolBunksResponse.body);
            setState(() {
              _petrolBunks = data;
            });
          } else {
            print('Petrol API Error: ${petrolBunksResponse.body}');
          }
        } catch (e) {
          print('Error fetching petrol bunks: $e');
        }
      } catch (e) {
        print('Error fetching places: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading nearby places. Check console for details.',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open Google Maps';
      }
    } catch (e) {
      print('Error launching maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open Google Maps')));
      }
    }
  }

  Widget buildPlaceTile(dynamic place, Color tileColor) {
    final double lat = place['position']['lat'];
    final double lon = place['position']['lng'];
    final String title = place['title'];
    final String address = place['address']['label'];

    return Container(
      width: 150,
      height: 150,
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              address,
              style: TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            IconButton(
              icon: Icon(Icons.directions, color: Colors.white),
              onPressed: () => _launchGoogleMaps(lat, lon),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Restaurants, Attractions, & Petrol Bunks"),
      ),
      body:
          _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      "Nearby Restaurants",
                      Icons.restaurant,
                      Colors.redAccent,
                      _restaurants,
                    ),
                    _buildSection(
                      "Nearby Attractions",
                      Icons.local_activity,
                      Colors.blueAccent,
                      _attractions,
                    ),
                    _buildSection(
                      "Nearby Petrol Bunks",
                      Icons.local_gas_station,
                      Colors.greenAccent,
                      _petrolBunks,
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<dynamic> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8.0),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          child:
              items.isEmpty
                  ? Center(child: Text("No results found"))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return buildPlaceTile(items[index], color);
                    },
                  ),
        ),
      ],
    );
  }
}
