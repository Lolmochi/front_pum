import 'package:flutter/material.dart';

class HomeStaffScreen extends StatelessWidget {
  final String staff_id;

  const HomeStaffScreen({super.key, required this.staff_id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลักพนักงาน'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'สวัสดีพนักงาน (ID: $staff_id)',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/sales',
                  arguments: {'staff_id': staff_id},
                );
              },
              icon: const Icon(Icons.sell, size: 30), // ไอคอนสำหรับบันทึกการขาย
              label: const Text('บันทึกการขายน้ำมัน', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), backgroundColor: Colors.teal, // เปลี่ยนสีปุ่ม
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/get_rewarded',
                  arguments: {'staff_id': staff_id},
                );
              },
              icon: const Icon(Icons.card_giftcard, size: 30), // ไอคอนสำหรับรับสินค้าที่แลกไว้
              label: const Text('รับสินค้าที่แลกไว้', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), backgroundColor: Colors.teal, // เปลี่ยนสีปุ่ม
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, size: 30), // ไอคอนสำหรับออกจากระบบ
              label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), backgroundColor: Colors.red, // เปลี่ยนสีปุ่มออกจากระบบ
              ),
            ),
          ],
        ),
      ),
    );
  }
}
