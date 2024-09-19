import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OfficerLogin extends StatefulWidget {
  const OfficerLogin({super.key});

  @override
  _OfficerLoginState createState() => _OfficerLoginState();
}

class _OfficerLoginState extends State<OfficerLogin> {
  final _officerIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String errorMessage = '';
  bool _isLoading = false; // Track loading state

  Future<void> _loginOfficer() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.14:3000/officers/login'), // Update this URL
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'officer_id': _officerIdController.text,
          'phone_number': _phoneNumberController.text,
        }),
      );

      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/officer_home',
          arguments: {'officer_id': _officerIdController.text}, // Pass officer_id to home screen
        );
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'รหัสหรือรหัสผ่านไม่ถูกต้อง';
        });
        _showSnackBar(errorMessage, Colors.red);
      } else {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดในการล็อกอิน';
        });
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator
        errorMessage = 'การเชื่อมต่อผิดพลาด';
      });
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Login'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _officerIdController,
              decoration: const InputDecoration(
                labelText: 'Officer ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'phone_number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginOfficer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
              child: _isLoading 
                ? const CircularProgressIndicator() // Show loading indicator
                : const Text('Login'),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
