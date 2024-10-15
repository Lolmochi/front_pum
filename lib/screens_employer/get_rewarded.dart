import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GetRewardedScreen extends StatefulWidget {
  final String staff_id;

  const GetRewardedScreen({super.key, required this.staff_id});

  @override
  _GetRewardedScreenState createState() => _GetRewardedScreenState();
}

class _GetRewardedScreenState extends State<GetRewardedScreen> {
  List<dynamic> pendingRedemptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingRedemptions(); // ดึงข้อมูลรายการการแลกสินค้าเมื่อเริ่มต้น
  }

  Future<void> fetchPendingRedemptions() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.20:3000/redemptions/get_redemptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': widget.staff_id}),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingRedemptions = jsonDecode(response.body)['redemptions'];
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
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล')),
      );
    }
  }

  Future<void> completeRedemption(String redemptionId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.20:3000/redemptions/update_redemption_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'redemption_id': redemptionId,
          'staff_id': widget.staff_id,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingRedemptions.removeWhere((item) => item['redemption_id'] == redemptionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สถานะการแลกเปลี่ยนสำหรับ $redemptionId อัปเดตสำเร็จ!')),
        );
      } else {
        throw Exception('Failed to update redemption status');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ')),
      );
    }
  }

  // ฟังก์ชันสำหรับแปลงเวลาเป็นเวลาไทย
  String formatThaiDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr).toUtc();
      DateTime thaiDate = parsedDate.add(Duration(hours: 7));
      return DateFormat('dd/MM/yyyy HH:mm').format(thaiDate);
    } catch (e) {
      print('Error parsing date: $e');
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการแลกสินค้า'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พนักงาน ID: ${widget.staff_id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) 
                  : pendingRedemptions.isEmpty
                      ? const Center(child: Text('ไม่มีรายการแลกสินค้า'))
                      : ListView.builder(
                          itemCount: pendingRedemptions.length,
                          itemBuilder: (context, index) {
                            final redemption = pendingRedemptions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'รหัสแลกสินค้า: ${redemption['redemption_id']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text('รหัสลูกค้า: ${redemption['customer_id']}'),
                                    Text('รหัสของรางวัล: ${redemption['reward_id']}'),
                                    Text('วันที่แลก: ${formatThaiDate(redemption['redemption_date'])}'),
                                    Text('แต้มที่ใช้: ${redemption['points_used']}'),
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey[400]),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          completeRedemption(redemption['redemption_id']);
                                        },
                                        child: const Text('ยืนยันรับสินค้า'),
                                      ),
                                    ),
                                  ],
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
}
