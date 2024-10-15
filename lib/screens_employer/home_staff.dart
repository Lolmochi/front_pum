import 'package:flutter/material.dart';

class HomeStaffScreen extends StatelessWidget {
  final String staff_id;

  const HomeStaffScreen({super.key, required this.staff_id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลักพนักงาน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // ขยายให้เต็มความกว้าง
          children: [
            Text(
              'สวัสดีพนักงาน (ID: $staff_id)',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // เพิ่มขนาดตัวอักษร
              textAlign: TextAlign.center, // จัดกึ่งกลาง
            ),
            const SizedBox(height: 40), // เว้นระยะห่าง
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/sales',
                  arguments: {'staff_id': staff_id}, // ส่ง staff_id
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), // เพิ่มความสูงปุ่ม
                textStyle: const TextStyle(fontSize: 20), // ขนาดตัวอักษร
              ),
              child: const Text('บันทึกการขายน้ำมัน'),
            ),
            const SizedBox(height: 20), // เว้นระยะห่างระหว่างปุ่ม
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/get_rewarded',
                  arguments: {'staff_id': staff_id}, // ส่ง staff_id
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), // เพิ่มความสูงปุ่ม
                textStyle: const TextStyle(fontSize: 20), // ขนาดตัวอักษร
              ),
              child: const Text('รับสินค้าที่แลกไว้'),
            ),
            const SizedBox(height: 20), // เว้นระยะห่างระหว่างปุ่ม
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login'); // กลับไปหน้าลงชื่อเข้าใช้
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20.0), // เพิ่มความสูงปุ่ม
                textStyle: const TextStyle(fontSize: 20), // ขนาดตัวอักษร
              ),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}
