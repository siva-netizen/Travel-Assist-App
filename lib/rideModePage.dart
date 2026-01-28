import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'getWeather.dart'; // Import your WeatherService
import 'tiwilio_service.dart'; // Ensure this is the correct path

class RideModePage extends StatefulWidget {
  final String startLocation;
  final String destination;
  final List<String> subDestinations;

  const RideModePage({
    Key? key,
    required this.startLocation,
    required this.destination,
    required this.subDestinations,
  }) : super(key: key);

  @override
  _RideModePageState createState() => _RideModePageState();
}

class _RideModePageState extends State<RideModePage> {
  final WeatherService _weatherService = WeatherService();
  late final TwilioService _twilioService;

  List<Map<String, dynamic>> weatherHistory = [];
  DateTime? startDate;
  DateTime? endDate;
  Timer? _timer;
  int forecastDays = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _twilioService = TwilioService(
      accountSid: 'ACf0c77d733f882b88f530f44a9745b947',
      authToken: 'a579b70d743ab53517054167947ad62f',
      fromPhoneNumber: '+18646571669',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? DateTime.now()
          : (endDate ?? DateTime.now().add(Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurpleAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchWeatherForAllLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, String>> newWeatherData = [];
      await _fetchAndAppendWeather(widget.startLocation, newWeatherData);
      for (String subLocation in widget.subDestinations) {
        await _fetchAndAppendWeather(subLocation, newWeatherData);
      }
      await _fetchAndAppendWeather(widget.destination, newWeatherData);

      setState(() {
        weatherHistory.add({
          'timestamp': DateTime.now().toString(),
          'data': newWeatherData,
        });
      });

      // Send alert after fetching weather data
      _sendWeatherAlert(newWeatherData);
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching weather data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAndAppendWeather(
      String location, List<Map<String, String>> weatherData) async {
    try {
      final forecastData =
      await _weatherService.getForecastByLocation(location, forecastDays);
      weatherData.add({
        'location': location,
        'date': forecastData['forecast']['forecastday'][0]['date'],
        'condition': forecastData['forecast']['forecastday'][0]['day']
        ['condition']['text'],
      });
    } catch (e) {
      weatherData.add({
        'location': location,
        'date': 'N/A',
        'condition': 'Error: $e',
      });
    }
  }

  void _sendWeatherAlert(List<Map<String, String>> weatherData) async {
    if (weatherData.isNotEmpty) {
      String message = 'Weather Update for ${weatherData[0]['location']}: '
          '${weatherData[0]['condition']} on ${weatherData[0]['date']}';
      try {
        await _twilioService.sendVoiceAlert('+916380091722', message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weather alert sent successfully',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send weather alert',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startTimer() {
    if (startDate == null || endDate == null) {
      setState(() {
        _errorMessage = "Please select both start and end dates";
      });
      return;
    }

    final daysDifference = endDate!.difference(startDate!).inDays + 1;
    forecastDays = daysDifference > 10 ? 10 : daysDifference;

    // Fetch weather data immediately
    _fetchWeatherForAllLocations();

    // Cancel any existing timer
    _timer?.cancel();

    // Set up periodic fetching
    _timer = Timer.periodic(Duration(seconds: 1840), (timer) {
      _fetchWeatherForAllLocations();
    });
  }

  Widget _buildWeatherTable(List<Map<String, String>> weatherData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.deepPurpleAccent.withOpacity(0.1)),
        dataRowColor: MaterialStateColor.resolveWith((states) =>
        states.contains(MaterialState.selected)
            ? Colors.grey.shade100
            : Colors.white),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        columns: [
          DataColumn(
            label: Text(
              'Location',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Date',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Condition',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
        rows: weatherData.asMap().entries.map((entry) {
          final data = entry.value;
          return DataRow(
            color: MaterialStateColor.resolveWith((states) =>
            entry.key % 2 == 0 ? Colors.white : Colors.grey.shade50),
            cells: [
              DataCell(
                Flexible(
                  child: Text(
                    data['location'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Flexible(
                  child: Text(
                    data['date'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Flexible(
                  child: Text(
                    data['condition'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurpleAccent.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riding Mode Forecast',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Get weather updates for your journey',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.deepPurpleAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  startDate == null
                                      ? 'Select Start Date'
                                      : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: startDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.deepPurpleAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  endDate == null
                                      ? 'Select End Date'
                                      : 'End: ${endDate!.toLocal().toString().split(' ')[0]}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: endDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startTimer,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurpleAccent,
                            Colors.blueAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Start Forecast Updates',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 16),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),
                Text(
                  'Weather History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                weatherHistory.isEmpty
                    ? Center(
                  child: Text(
                    'No weather updates yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: weatherHistory.length,
                  itemBuilder: (context, index) {
                    final historyEntry = weatherHistory[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Update: ${historyEntry['timestamp'].split('.')[0]}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        iconColor: Colors.deepPurpleAccent,
                        collapsedIconColor: Colors.grey.shade600,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: _buildWeatherTable(
                                historyEntry['data']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}