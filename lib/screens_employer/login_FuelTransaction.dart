import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<Login> {
  final _idController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.44:3000/staff/login'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'staff_id': _idController.text,
          'phone_number': _phoneNumberController.text,
        }),
      );

      print('Response body: ${response.body}'); // ตรวจสอบการตอบกลับ

      if (response.statusCode == 200) {
        // อาจต้องตรวจสอบข้อมูลที่ตอบกลับจากเซิร์ฟเวอร์ที่นี่
        Navigator.pushNamed(
          context, 
          '/home_staff',
          arguments: {'staff_id': _idController.text},  // ส่ง staffId ไปยังหน้าจอ /sales
        );
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'รหัสหรือเบอร์โทรศัพท์ไม่ถูกต้อง';
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
        errorMessage = 'การเชื่อมต่อผิดพลาด';
      });
      print('Error: $e');
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
        title: const Text('เข้าสู่ระบบ'),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้ใช้',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('เข้าสู่ระบบ'),
            ),
            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/login_officer');
              },
            ),
          ],
        ),
      ),
    );
  }
}
