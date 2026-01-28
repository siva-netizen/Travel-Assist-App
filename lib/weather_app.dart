import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Twilio Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme:
            kIsWeb
                ? ThemeData.light().textTheme
                : GoogleFonts.poppinsTextTheme(),
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final List<String> weatherOptions = [
    'Rain with thunderstorms',
    'Sunny climate',
  ];
  String selectedWeather = 'Rain with thunderstorms';
  bool isLoading = false;

  // Helper to use system fonts on web, Google Fonts on mobile
  TextStyle _textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (kIsWeb) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  Future<void> _makeCall() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user UID
      User? user = FirebaseAuth.instance.currentUser;
      String uid = user?.uid ?? '';

      // Fetch user details from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (userDoc.exists) {
        String username = userDoc.get('username');
        String phone = userDoc.get('phone');

        // Make Twilio API Call
        String message =
            'Hello $username, the climate is detected as $selectedWeather';
        await _triggerTwilioCall(phone, message);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Call sent to $username about the weather',
              style: _textStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User not found. Please sign in again.',
              style: _textStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to make call: $e',
            style: _textStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _triggerTwilioCall(String phone, String message) async {
    const String twilioAccountSid = AppConfig.twilioAccountSid;
    const String twilioAuthToken = AppConfig.twilioAuthToken;
    const String twilioPhoneNumber = AppConfig.twilioPhoneNumber;

    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$twilioAccountSid:$twilioAuthToken'))}';

    final response = await http.post(
      Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Calls.json',
      ),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': '+$phone',
        'From': twilioPhoneNumber,
        'Url':
            'http://twimlets.com/message?Message=${Uri.encodeComponent(message)}',
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to make call: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurpleAccent.shade100,
              Colors.blueAccent.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.cloud,
                    size: 80,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Weather Alert Call',
                  style: _textStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a weather condition to send a voice alert',
                  style: _textStyle(fontSize: 16, color: Colors.black54),
                ),
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedWeather,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.deepPurpleAccent,
                      ),
                      style: _textStyle(fontSize: 14, color: Colors.black87),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWeather = newValue!;
                        });
                      },
                      items:
                          weatherOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTapDown: (_) {
                      if (!isLoading) {
                        setState(() {
                          isLoading = true;
                        });
                        Future.delayed(Duration(milliseconds: 200), () {
                          setState(() {
                            isLoading = false;
                          });
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform:
                          Matrix4.identity()..scale(isLoading ? 0.95 : 1.0),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _makeCall,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurpleAccent,
                                Colors.blueAccent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            alignment: Alignment.center,
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Send Alert',
                                      style: _textStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
