import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OfficerHomeScreen extends StatefulWidget {
  final String officer_id;

  const OfficerHomeScreen({super.key, required this.officer_id});

  @override
  _OfficerHomeScreenState createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  late Future<List<dynamic>> _latestTransactions;

  @override
  void initState() {
    super.initState();
    _latestTransactions = _fetchTransactions();
  }

  Future<List<dynamic>> _fetchTransactions() async {
    final response = await http.get(Uri.parse('http://192.168.1.14:3000/transactions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Home'),
        backgroundColor: Colors.teal, // เปลี่ยนสี AppBar ให้ดูโดดเด่น
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Button row inside a wrap to prevent overflow
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0, // Adjust spacing between buttons
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // เปลี่ยนสีปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/search_transaction', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Transactions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/redeem_items', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.redeem),
                    label: const Text('Rewards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/search_edit_reward', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Reward'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/redemtion_deleted', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('deleted redemtion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 228, 250, 29),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                   ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/history_of_year', arguments: widget.officer_id);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('ประมวลผลรายปี'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 29, 184, 250),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),                 
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Latest Transactions:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _latestTransactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No transactions found.'));
                  } else {
                    final transactions = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true, // To prevent infinite height error
                      physics: const NeverScrollableScrollPhysics(), // Prevent inner scrolling
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0, // เพิ่มเงาให้บัตรดูโดดเด่นขึ้น
                          color: Colors.white, // สีพื้นหลังของบัตร
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // ทำมุมให้โค้งมน
                          ),
                          child: ListTile(
                            title: Text(
                              'Transaction ID: ${transaction['transaction_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            subtitle: Text(
                              'Customer ID: ${transaction['customer_id']}\n'
                              'Fuel Type ID: ${transaction['fuel_type_id']}\n'
                              'Amount: ${transaction['amount']}\n'
                              'Date: ${transaction['transaction_date']}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
