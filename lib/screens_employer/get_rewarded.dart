import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class GetRewardedScreen extends StatefulWidget {
  final String staff_id;

  const GetRewardedScreen({super.key, required this.staff_id});

  @override
  _GetRewardedScreenState createState() => _GetRewardedScreenState();
}

class _GetRewardedScreenState extends State<GetRewardedScreen> {
  List<dynamic> pendingRedemptions = [];
  List<dynamic> filteredRedemptions = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    fetchPendingRedemptions();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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

  void _filterRedemptions() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      filteredRedemptions = pendingRedemptions.where((redemption) {
        return redemption['redemption_id'].toString().toLowerCase() == searchTerm;
      }).toList();
    });
  }

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
          _filterRedemptions();
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

  void _showConfirmationDialog(String redemptionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการทำรายการ'),
          content: const Text('คุณต้องการยืนยันการรับสินค้าหรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                completeRedemption(redemptionId);
                Navigator.of(context).pop();
              },
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        _searchController.text = scanData.code!;
        _filterRedemptions();
      });
    });
  }

  void _showQRCodeScanner() {
    setState(() {
      isScanning = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('สแกน QR Code'),
          content: SizedBox(
            height: 300,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller?.pauseCamera();
                setState(() {
                  isScanning = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการแลกสินค้า'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'พนักงาน ID: ${widget.staff_id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'กรอกรหัสของรางวัลเพื่อค้นหา',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _filterRedemptions();
                  if (isScanning) {
                    controller?.pauseCamera();
                    setState(() {
                      isScanning = false;
                    });
                    Navigator.of(context).pop();
                  }
                } else {
                  setState(() {
                    filteredRedemptions = [];
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRedemptions.isEmpty
                      ? const Center(child: Text('กรอกรหัสของรางวัลเพื่อค้นหา'))
                      : ListView.builder(
                          itemCount: filteredRedemptions.length,
                          itemBuilder: (context, index) {
                            final redemption = filteredRedemptions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              color: Colors.lightGreen[50], // เปลี่ยนสีพื้นหลังของ Card
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
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text('รหัสลูกค้า: ${redemption['customer_id']}'),
                                    Text('รหัสของรางวัล: ${redemption['reward_id']}'),
                                    Text('วันที่แลก: ${formatThaiDate(redemption['redemption_date'])}'),
                                    Text('แต้มที่ใช้: ${redemption['points_used']}'),
                                    Text('จำนวนของ: ${redemption['quantity']}'),
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.grey[400]),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showConfirmationDialog(redemption['redemption_id']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal, // เปลี่ยนสีของปุ่ม
                                        ),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showQRCodeScanner,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('แสกน QR Code', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // เปลี่ยนสีของปุ่ม
              ),
            ),
          ],
        ),
      ),
    );
  }
}
