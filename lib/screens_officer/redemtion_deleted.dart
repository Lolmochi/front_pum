import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Search_deleteRedemptionsScreen extends StatefulWidget {
  const Search_deleteRedemptionsScreen({Key? key}) : super(key: key);

  @override
  _SearchRedemptionsScreenState createState() => _SearchRedemptionsScreenState();
}

class _SearchRedemptionsScreenState extends State<Search_deleteRedemptionsScreen> {
  List<dynamic> redemptions = [];
  bool isLoading = true;
  String selectedStatus = 'all'; // เลือกสถานะเริ่มต้นเป็น all (แสดงทั้งหมด)
  String searchQuery = ''; // สำหรับค้นหาชื่อรางวัล

  @override
  void initState() {
    super.initState();
    fetchRedemptions(); // ดึงข้อมูลเมื่อเริ่มต้น
  }

  Future<void> fetchRedemptions() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.14:3000/redemptions/search_redemptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': selectedStatus != 'all' ? selectedStatus : null,
          'reward_name': searchQuery.isNotEmpty ? searchQuery : null,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          redemptions = jsonDecode(response.body)['redemptions'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load redemptions');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล')),
      );
    }
  }

  void onSearch() {
    setState(() {
      isLoading = true;
    });
    fetchRedemptions(); // ค้นหาทุกครั้งที่มีการเปลี่ยนแปลงสถานะหรือชื่อรางวัล
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหารายการแลกสินค้า'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'ค้นหาด้วยชื่อรางวัล',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value; // อัปเดตค่าการค้นหา
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
                onSearch(); // ค้นหาใหม่เมื่อเปลี่ยนสถานะ
              },
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                DropdownMenuItem(value: 'completed', child: Text('เสร็จสมบูรณ์')),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onSearch,
              child: const Text('ค้นหา'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // แสดงตัวโหลดข้อมูล
                  : ListView.builder(
                      itemCount: redemptions.length,
                      itemBuilder: (context, index) {
                        final redemption = redemptions[index];
                        return Card(
                          child: ListTile(
                            title: Text('รหัสแลกสินค้า: ${redemption['redemption_id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('รางวัล: ${redemption['reward_name']}'),
                                Text('รหัสลูกค้า: ${redemption['customer_id']}'),
                                Text('วันที่แลก: ${redemption['redemption_date']}'),
                                Text('แต้มที่ใช้: ${redemption['points_used']}'),
                                Text('สถานะ: ${redemption['status']}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // ฟังก์ชันลบการแลกสินค้า
                                deleteRedemption(redemption['redemption_id']);
                              },
                              child: const Text('ลบ'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteRedemption(String redemption_id) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.14:3000/redemptions/delete_redemption'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'redemption_id': redemption_id}),
      );

      if (response.statusCode == 200) {
        setState(() {
          redemptions.removeWhere((item) => item['redemption_id'] == redemption_id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบรายการ $redemption_id สำเร็จ!')),
        );
      } else {
        throw Exception('Failed to delete redemption');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรายการ')),
      );
    }
  }
}
