import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnnualDividendsPage extends StatefulWidget {
  const AnnualDividendsPage({super.key});

  @override
  _AnnualDividendsPageState createState() => _AnnualDividendsPageState();
}

class _AnnualDividendsPageState extends State<AnnualDividendsPage> {
  List<dynamic> _customers = [];
  List<dynamic> _selectedCustomers = [];

  // ฟังก์ชันดึงข้อมูลลูกค้าจาก API
  Future<void> fetchCustomers() async {
    final response = await http.get(Uri.parse('http://192.168.1.10:3000/customers'));

    if (response.statusCode == 200) {
      setState(() {
        _customers = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load customers');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  // ฟังก์ชันสร้าง PDF
  Future<void> _generatePdfAndPrint() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.ListView.builder(
            itemCount: _selectedCustomers.length,
            itemBuilder: (context, index) {
              final customer = _selectedCustomers[index];
              return pw.Text(
                  '${customer['first_name']} ${customer['last_name']} - Points: ${customer['points_balance']}');
            },
          );
        },
      ),
    );

    // แสดงหน้าต่างพิมพ์
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annual Dividends Calculator'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                final isSelected = _selectedCustomers.contains(customer);

                return ListTile(
                  title: Text('${customer['first_name']} ${customer['last_name']}'),
                  subtitle: Text('Points: ${customer['points_balance']}'),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedCustomers.add(customer);
                        } else {
                          _selectedCustomers.remove(customer);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _selectedCustomers.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Print'),
                        content: const Text('Are you sure you want to print the selected customers?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _generatePdfAndPrint();
                            },
                            child: const Text('Print'),
                          ),
                        ],
                      ),
                    );
                  },
            child: const Text('Print Selected'),
          ),
        ],
      ),
    );
  }
}
