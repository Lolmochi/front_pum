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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Button to navigate to other pages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile', arguments: widget.officer_id);
                  },
                  child: const Text('Profile'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/search_transaction', arguments: widget.officer_id);
                  },
                  child: const Text('Transactions'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/redeem_items', arguments: widget.officer_id);
                  },
                  child: const Text('Rewards'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Latest Transactions:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
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
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text('Transaction ID: ${transaction['transaction_id']}'),
                            subtitle: Text(
                              'Customer ID: ${transaction['customer_id']}\n'
                              'Fuel Type ID: ${transaction['fuel_type_id']}\n'
                              'Amount: ${transaction['amount']}\n'
                              'Date: ${transaction['transaction_date']}',
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
