import 'package:flutter/material.dart';
import 'dart:convert'; // For encoding and decoding JSON
import 'package:http/http.dart' as http;

class SearchAndManagePage extends StatefulWidget {
  const SearchAndManagePage({super.key});

  @override
  _SearchAndManagePageState createState() => _SearchAndManagePageState();
}

class _SearchAndManagePageState extends State<SearchAndManagePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  // Fetch transactions based on search input
  Future<void> _searchTransactions(String searchTerm) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:3000/transactions/search?term=$searchTerm'));
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete transaction by ID
  Future<void> _deleteTransaction(String transactionId) async {
    try {
      final response = await http.delete(Uri.parse('http://192.168.1.10:3000/transactions/$transactionId'));
      if (response.statusCode == 200) {
        // Refresh search results after deletion
        _searchTransactions(_searchController.text);
      } else {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      print(e);
    }
  }

  // Show dialog to edit a transaction
  void _showEditDialog(Map<String, dynamic> transaction) {
    final TextEditingController fuelTypeController = TextEditingController(text: transaction['fuel_type']);
    final TextEditingController amountController = TextEditingController(text: transaction['amount'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: fuelTypeController,
                decoration: const InputDecoration(labelText: 'Fuel Type'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateTransaction(transaction['transaction_id'], fuelTypeController.text, double.parse(amountController.text));
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Update transaction with new data
  Future<void> _updateTransaction(String transactionId, String fuelType, double amount) async {
    try {
      final officerId = '123'; // Static officer_id for example, replace with actual officer's ID in your system
      final response = await http.put(
        Uri.parse('http://192.168.1.10:3000/transactions/$transactionId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'fuel_type': fuelType,
          'amount': amount,
          'officer_id': officerId
        }),
      );
      if (response.statusCode == 200) {
        // Refresh search results after updating
        _searchTransactions(_searchController.text);
      } else {
        throw Exception('Failed to update transaction');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search and Manage Transactions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by ID, Name, Phone, or Transaction ID',
              ),
              onSubmitted: _searchTransactions,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final transaction = _searchResults[index];
                        return Card(
                          child: ListTile(
                            title: Text('Transaction ID: ${transaction['transaction_id']}'),
                            subtitle: Text('Amount: ${transaction['amount']}, Fuel Type: ${transaction['fuel_type']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditDialog(transaction),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTransaction(transaction['transaction_id']),
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
