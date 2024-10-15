import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class FuelTransactionScreen extends StatefulWidget {
  final String staff_id;

  const FuelTransactionScreen({super.key, required this.staff_id});

  @override
  _FuelTransactionScreenState createState() => _FuelTransactionScreenState();
}

class _FuelTransactionScreenState extends State<FuelTransactionScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedFuelType = 'ดีเซล B7';
  String baseUrl = 'http://192.168.1.20:3000';
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
    getPairedDevices();
  }

  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.location.request().isGranted) {
      print('All permissions granted');
    } else {
      print('Permissions not granted');
    }
  }

  Future<void> getPairedDevices() async {
    try {
      _devices = await bluetooth.getBondedDevices();
      setState(() {});
    } catch (e) {
      print("Error fetching paired devices: $e");
    }
  }

  Future<void> connectToBluetooth() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอุปกรณ์บลูทูธ.')),
      );
      return;
    }

    bool isConnected = await bluetooth.isConnected ?? false;
    if (isConnected) {
      print("Already connected.");
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อสำเร็จ');
      return;
    }

    try {
      await bluetooth.connect(_selectedDevice!);
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อสำเร็จ');
    } catch (e) {
      print("Failed to connect to Bluetooth device: $e");
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อล้มเหลว');
    }
  }

  String _scanResult = ''; // ประกาศและกำหนดค่าเริ่มต้นให้ _scanResult

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // สีของแถบสแกน
        'ยกเลิก', // ปุ่มยกเลิก
        true, // สแกนหลายรูปแบบ (QR, Barcode)
        ScanMode.BARCODE, // โหมดสแกนบาร์โค้ด
      );
    } on PlatformException {
      barcodeScanRes = 'ไม่สามารถเชื่อมต่อกับแพลตฟอร์มได้';
    }

    if (!mounted) return;

    setState(() {
      _scanResult = barcodeScanRes; // กำหนดค่าผลการสแกนให้กับ _scanResult
    });
  }

  Future<void> submitTransaction() async {
    final phone = phoneController.text.replaceAll('-', '').trim();
    final price = double.tryParse(priceController.text);
    print('staff_id: ${widget.staff_id}');

    if (price == null || price <= 0) {
      _showSnackBar('กรุณากรอกราคาที่ถูกต้อง');
      return;
    }

    try {
      final transactionResponse = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phone,
          'fuel_type': selectedFuelType,
          'points_earned': price,
          'staff_id': widget.staff_id,
        }),
      );

      print('Status Code: ${transactionResponse.statusCode}');
      print('Response Body: ${transactionResponse.body}');

      if (transactionResponse.statusCode == 200) {
        final Map<String, dynamic> transaction = json.decode(transactionResponse.body);
        final String? transactionId = transaction['transactionId']?.toString();

        if (transactionId == null || transactionId.isEmpty) {
          _showSnackBar('ไม่สามารถรับหมายเลขรายการจากเซิร์ฟเวอร์ได้.');
          return;
        }

        final pointsEarned = transaction['pointsEarned'] ?? 0;

        final memberResponse = await http.get(Uri.parse('$baseUrl/customers/$phone'));
        final staffResponse = await http.get(Uri.parse('$baseUrl/staff/${widget.staff_id}'));

        if (memberResponse.statusCode == 200 && staffResponse.statusCode == 200) {
          final memberData = json.decode(memberResponse.body);
          final staffData = json.decode(staffResponse.body);

          const dividendPercentage = 0.01;
          final dividend = price * dividendPercentage;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                transactionId: transactionId,
                phoneNumber: phone,
                fuelType: selectedFuelType,
                price: price,
                pointsEarned: pointsEarned,
                dividend: dividend,
                staffFirstName: staffData['first_name'],
                staffLastName: staffData['last_name'],
                memberId: memberData['customer_id'].toString(),
                memberFirstName: memberData['first_name'],
                memberLastName: memberData['last_name'],
                staffId: widget.staff_id,
                selectedDevice: _selectedDevice,
              ),
            ),
          );
        } else {
          _showSnackBar('ไม่สามารถดึงข้อมูลสมาชิกหรือพนักงานได้.');
        }
      } else {
        print('Error: ${transactionResponse.body}');
        _showSnackBar('บันทึกการขายล้มเหลว!');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด. กรุณาลองใหม่อีกครั้ง.');
      print('Exception: $e');
    }
  }

  Future<void> confirmTransaction() async {
    final phone = phoneController.text.replaceAll('-', '').trim();
    final price = double.tryParse(priceController.text);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการทำรายการ'),
          content: Text(
              'เบอร์โทร: $phone\nประเภทน้ำมัน: $selectedFuelType\nราคา: ฿${price?.toStringAsFixed(2)}\nคุณต้องการทำรายการนี้หรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('ยืนยัน'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await submitTransaction();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        title: const Text('บันทึกการขายน้ำมัน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'เบอร์โทร'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedFuelType,
                      decoration: const InputDecoration(labelText: 'ประเภทน้ำมัน'),
                      onChanged: (value) {
                        setState(() {
                          selectedFuelType = value!;
                        });
                      },
                      items: ['ดีเซล B7', 'ดีเซล B10', 'แก๊สโซฮอล์ E20', 'แก๊สโซฮอล์ 91', 'แก๊สโซฮอล์ 95', 'ซูเปอร์พาวเวอร์ดีเซล B7', 'ซูเปอร์พาวเวอร์แก๊สโซฮอล์ 95']
                          .map((fuelType) => DropdownMenuItem(
                                value: fuelType,
                                child: Text(fuelType),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'ราคา'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: scanBarcode,
                            child: const Text('สแกนบาร์โค้ด'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: confirmTransaction,
                            child: const Text('ยืนยัน'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: connectToBluetooth,
                      child: const Text('เชื่อมต่อ Bluetooth'),
                    ),
                    const SizedBox(height: 10),
                    _devices.isNotEmpty
                        ? DropdownButton<BluetoothDevice>(
                            value: _selectedDevice,
                            hint: const Text('เลือกอุปกรณ์ Bluetooth'),
                            onChanged: (BluetoothDevice? device) {
                              setState(() {
                                _selectedDevice = device;
                              });
                            },
                            items: _devices
                                .map((device) => DropdownMenuItem(
                                      value: device,
                                      child: Text(device.name ?? ''),
                                    ))
                                .toList(),
                          )
                        : const Text('ไม่มีอุปกรณ์ที่จับคู่'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


  String generateTransactionId() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    final String randomString = String.fromCharCodes(
      Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    final String timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    return '$timestamp$randomString';
  }

class ReceiptScreen extends StatelessWidget {
  final String transactionId;
  final String phoneNumber;
  final String fuelType;
  final double price;
  final int pointsEarned;
  final double dividend;
  final String staffFirstName;
  final String staffLastName;
  final String memberId;
  final String memberFirstName;
  final String memberLastName;
  final String staffId;
  final BluetoothDevice? selectedDevice;

  const ReceiptScreen({super.key, 
    required this.transactionId,
    required this.phoneNumber,
    required this.fuelType,
    required this.price,
    required this.pointsEarned,
    required this.dividend,
    required this.staffFirstName,
    required this.staffLastName,
    required this.memberId,
    required this.memberFirstName,
    required this.memberLastName,
    required this.staffId,
    this.selectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('หมายเลขรายการ: $transactionId'),
            Text('เบอร์โทร: $phoneNumber'),
            Text('ประเภทน้ำมัน: $fuelType'),
            Text('ราคา: ฿${price.toStringAsFixed(2)}'),
            Text('แต้มสะสม: $pointsEarned'),
            Text('ปันผลประจำปี: ฿${dividend.toStringAsFixed(2)}'),
            Text('ผู้บันทึก: $staffFirstName $staffLastName (ID: $staffId)'),
            Text('สมาชิก: $memberFirstName $memberLastName (ID: $memberId)'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => printReceipt(),
                child: const Text('พิมพ์ใบเสร็จ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> printReceipt() async {
    final bluetooth = BlueThermalPrinter.instance;

    if (selectedDevice == null) {
      print("ยังไม่ได้เลือกอุปกรณ์ Bluetooth.");
      return;
    }

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(selectedDevice!);
      }

      // พิมพ์ข้อความภาษาไทย
      bluetooth.printCustom('ใบเสร็จรับเงิน', 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('หมายเลขรายการ: $transactionId', 1, 0);
      bluetooth.printCustom('เบอร์โทร: $phoneNumber', 1, 0);
      bluetooth.printCustom('ID member: $memberId', 1, 0);
      bluetooth.printCustom('ชื่อนามสกุล: $memberFirstName $memberLastName', 1, 0);
      bluetooth.printCustom('ประเภทน้ำมัน: $fuelType', 1, 0);
      bluetooth.printCustom('ราคา: ฿${price.toStringAsFixed(2)}', 1, 0);
      bluetooth.printCustom('แต้มสะสม: $pointsEarned', 1, 0);
      bluetooth.printCustom('ปันผลประจำปี: ฿${dividend.toStringAsFixed(2)}', 1, 0);
      bluetooth.printCustom('วันที่ทำรายการ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', 1, 0);
      bluetooth.printCustom('ID ผู้บันทึก: $staffId', 1, 0);
      bluetooth.printNewLine();
      bluetooth.printCustom('ขอบคุณที่ใช้บริการ!', 2, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();

      print("พิมพ์ใบเสร็จสำเร็จ.");
    } catch (e) {
      print("ข้อผิดพลาดในการพิมพ์ใบเสร็จ: $e");
    }
  }
}