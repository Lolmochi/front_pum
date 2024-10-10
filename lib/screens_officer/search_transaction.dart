import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchTransactionScreen extends StatefulWidget {
  final String officer_id; // เพิ่ม officer_id

  const SearchTransactionScreen({super.key, required this.officer_id});

  @override
  _SearchTransactionScreenState createState() => _SearchTransactionScreenState();
}

class _SearchTransactionScreenState extends State<SearchTransactionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _transactions;
  Map<String, String> fuelTypesMap = {}; // ตัวแปรเพื่อเก็บแมพประเภทน้ำมัน

  @override
  void initState() {
    super.initState();
    _transactions = _fetchTransactions();
    _fetchFuelTypes(); // เรียกฟังก์ชันเพื่อดึงประเภทน้ำมัน
  }

  Future<List<dynamic>> _fetchTransactions([String query = '']) async {
    final response = await http.get(Uri.parse('http://192.168.1.44:3000/transactions?query=$query'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFuelTypes() async { 
      final response = await http.get(Uri.parse('http://192.168.1.44:3000/fuel_types'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        fuelTypesMap = {
          for (var item in data) item['fuel_type_id'].toString(): item['fuel_type_name']
        };
        return data.map((item) => {
          'fuel_type_id': item['fuel_type_id'],
          'fuel_type_name': item['fuel_type_name']
        }).toList();
      } else {
        throw Exception('Failed to load fuel types');
      }
    }


  Future<void> _updateTransaction(String transactionId, String fuelTypeId, String points_earned) async {
    final response = await http.put(
      Uri.parse('http://192.168.1.44:3000/transactions/$transactionId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'fuel_type_id': fuelTypeId,
        'points_earned': points_earned,
        'officer_id': widget.officer_id, // ส่ง officer_id ไปด้วย
      }),
    );

    if (response.statusCode == 200) {
      print('Transaction updated successfully');
      setState(() {
        _transactions = _fetchTransactions(); // Refresh transaction list
      });
    } else {
      print('Failed to update transaction');
    }
  }

  void _showEditDialog(Map<String, dynamic> transaction) async {
      final TextEditingController points_earnedController = TextEditingController(text: transaction['points_earned'].toString());

      List<Map<String, dynamic>> fuelTypes = await _fetchFuelTypes(); // เรียกฟังก์ชันที่อัปเดตแล้ว
      String selectedFuelTypeId = transaction['fuel_type_id'].toString();

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Edit Transaction'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: selectedFuelTypeId,
                        items: fuelTypes.map<DropdownMenuItem<String>>((fuelType) {
                          return DropdownMenuItem<String>(
                            value: fuelType['fuel_type_id'].toString(),
                            child: Text(fuelType['fuel_type_name']),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedFuelTypeId = newValue!;
                          });
                        },
                      ),
                      TextField(
                        controller: points_earnedController,
                        decoration: const InputDecoration(labelText: 'points_earned'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _updateTransaction(
                        transaction['transaction_id'],
                        selectedFuelTypeId,
                        points_earnedController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาธุรกรรม'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาธุรกรรม',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _transactions = _fetchTransactions(_searchController.text);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _transactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่พบธุรกรรม.'));
                  } else {
                    final transactions = snapshot.data!;
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Card(
                          child: ListTile(
                            title: Text('Transaction ID: ${transaction['transaction_id']}'),
                            subtitle: Text('Amount: ${transaction['points_earned']} | Fuel Type: ${fuelTypesMap[transaction['fuel_type_id'].toString()] ?? 'Unknown'}'), // เปลี่ยนที่นี่
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(transaction);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
