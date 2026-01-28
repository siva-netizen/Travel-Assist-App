import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HotelBookingPage extends StatefulWidget {
  @override
  _HotelBookingPageState createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _checkInDateController = TextEditingController();
  List<dynamic> _hotels = [];

  Future<void> _searchHotels() async {
    final String location = _locationController.text;
    final String checkInDate = _checkInDateController.text;

    if (location.isEmpty || checkInDate.isEmpty) {
      return;
    }

    final String url =
        'https://booking-com18.p.rapidapi.com/web/stays/details?location=$location&checkIn=$checkInDate';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-host': 'booking-com18.p.rapidapi.com',
          'x-rapidapi-key': 'd446b3b06bmsh6c4e6379e10db3fp1c49fbjsndf970452b54e',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _hotels = data['result'];
        });
      } else {
        print('Failed to load hotels: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildHotelCard(dynamic hotel) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotel['name'] ?? 'No Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              hotel['address'] ?? 'No Address',
              style: TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              'Price: ${hotel['price'] ?? 'N/A'} ${hotel['currency'] ?? ''}',
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Logic to open hotel details or booking page
              },
              child: Text('View Details'),
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
        title: Text('Search Hotels'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _checkInDateController,
                decoration: InputDecoration(labelText: 'Check-In Date (YYYY-MM-DD)'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _searchHotels,
                child: Text('Search Hotels'),
              ),
              SizedBox(height: 20),
              if (_hotels.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _hotels.length,
                  itemBuilder: (context, index) {
                    return _buildHotelCard(_hotels[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
