import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:charset_converter/charset_converter.dart';

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

  const ReceiptScreen({
    super.key,
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

      String thaiText = "ใบเสร็จรับเงิน";

      // พิมพ์ข้อความทีละตัว
      for (int i = 0; i < thaiText.length; i++) {
        bluetooth.printCustom(thaiText[i], 1, 0);
      }

      bluetooth.printNewLine();
      bluetooth.paperCut();

      print("พิมพ์ข้อความภาษาไทยสำเร็จ.");
    } catch (e) {
      print("ข้อผิดพลาดในการพิมพ์ภาษาไทย: $e");
    }
  }
}
