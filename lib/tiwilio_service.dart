import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class TwilioService {
  final String accountSid;
  final String authToken;
  final String fromPhoneNumber;

  TwilioService({
    required this.accountSid,
    required this.authToken,
    required this.fromPhoneNumber,
  });

  Future<void> sendVoiceAlert(String toPhoneNumber, String message) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

    // Adding the sponsor message to the main message
    final String fullMessage = '''
      <Response>
        <Say>$message</Say>
        <Pause length="1"/>
        <Say>Sponsored by ABC Hotels. Get 20% off your next visit to ABC Hotel!</Say>
      </Response>
    ''';

    final Map<String, String> requestBody = {
      'To': toPhoneNumber,
      'From': fromPhoneNumber,
      'Twiml': fullMessage,
    };

    final response = await http.post(
      Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Calls.json'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: requestBody,
    );

    print('Request URL: ${response.request?.url}');
    print('Request Body: $requestBody');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      print('Voice alert sent successfully!');
    } else {
      print('Failed to send voice alert: ${response.body}');
    }
  }

  Future<void> sendSmsAlert(String toPhoneNumber, String message) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

    final Map<String, String> requestBody = {
      'To': toPhoneNumber,
      'From': fromPhoneNumber,
      'Body': message,
    };

    final response = await http.post(
      Uri.parse(
          'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
      headers: <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: requestBody,
    );

    print('Request URL: ${response.request?.url}');
    print('Request Body: $requestBody');
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      print('SMS alert sent successfully!');
    } else {
      print('Failed to send SMS alert: ${response.body}');
    }
  }
}
