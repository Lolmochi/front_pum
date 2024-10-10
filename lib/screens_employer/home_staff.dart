import 'package:flutter/material.dart';

class HomeStaffScreen extends StatelessWidget {
  final String staff_id;

  const HomeStaffScreen({Key? key, required this.staff_id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลักพนักงาน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สวัสดีพนักงาน (ID: $staff_id)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/sales',
                  arguments: {'staff_id': staff_id}, // Pass staff_id
                );
              },
              child: const Text('บันทึกการขายน้ำมัน'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add any other new functionality here
                // Example: Navigate to another page for staff-specific features
              },
              child: const Text('หน้าที่อื่น ๆ สำหรับพนักงาน'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/get_rewarded',
                  arguments: {'staff_id': staff_id}, // Pass staff_id
                );
              },
              child: const Text('รับสินค้าที่แลกไว้'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login
              },
              child: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}
