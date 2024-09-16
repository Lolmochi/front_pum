import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> transactions = [];
  bool isLoading = true; // Show loader initially
  bool hasError = false; // Handle error state

  @override
  void initState() {
    super.initState();
    fetchRecentTransactions();
  }

  // Fetch recent transactions from the server
  void fetchRecentTransactions() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.10:3000/transactions/recent'));

      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(response.body);
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        print('Failed to load recent transactions');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader when loading
          : hasError
              ? const Center(child: Text('Failed to load transactions')) // Show error message
              : transactions.isEmpty
                  ? const Center(child: Text('No recent transactions available')) // No data case
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return ListTile(
                          title: Text('Transaction ID: ${transaction['transaction_id']}'),
                          subtitle: Text('Fuel Type: ${transaction['fuel_type']} - Price: ${transaction['amount']}'),
                          trailing: Text('Points: ${transaction['points_earned']}'),
                        );
                      },
                    ),
    );
  }
}
