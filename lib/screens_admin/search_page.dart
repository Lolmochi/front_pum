import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchBy = 'customer_id'; // Default search option
  List<dynamic> searchResults = [];
  Map<String, dynamic>? memberDetails;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void searchMembers() async {
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.14:3000/transactions/search?term=${_searchController.text}'),
    );

    if (response.statusCode == 200) {
      List<dynamic> results = json.decode(response.body);

      setState(() {
        if (results.isNotEmpty) {
          memberDetails = {
            'id': results[0]['customer_id'],
            'name': results[0]['customer_name'],
            'surname': results[0]['customer_surname'],
            'phone_number': results[0]['phone_number'],
            'points': results[0]['points_balance'],
            'annual': results[0]['dividend']
          };
          searchResults = results;
        } else {
          memberDetails = null;
          searchResults = [];
        }
      });
    } else {
      print('Failed to load search results');
    }
  }

  Future<void> editTransaction(Map<String, dynamic> transaction) async {
    final updatedTransaction = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String fuelType = transaction['fuel_type'] ?? '';
        double price = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fuelType,
                items: const [
                  DropdownMenuItem(value: 'Diesel Premium', child: Text('Diesel Premium')),
                  DropdownMenuItem(value: 'HiDiesel', child: Text('HiDiesel')),
                  DropdownMenuItem(value: 'Hi Premium 97', child: Text('Hi Premium 97')),
                  DropdownMenuItem(value: 'E85', child: Text('E85')),
                  DropdownMenuItem(value: 'E20', child: Text('E20')),
                  DropdownMenuItem(value: 'Gasohol 91', child: Text('Gasohol 91')),
                  DropdownMenuItem(value: 'Gasohol 95', child: Text('Gasohol 95')),
                ],
                onChanged: (value) => fuelType = value!,
                decoration: const InputDecoration(labelText: 'Fuel Type'),
              ),
              TextField(
                onChanged: (value) => price = double.tryParse(value) ?? price,
                controller: TextEditingController(text: price.toString()),
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'fuel_type': fuelType,
                  'amount': price,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updatedTransaction != null) {
      // Calculate points and annual dividend
      final pointsEarned = (updatedTransaction['amount'] as num).toInt();
      final annualDividend = (pointsEarned * 0.01).toStringAsFixed(2);

      final response = await http.put(
        Uri.parse(
            'http://192.168.1.14:3000/transactions/${transaction['transaction_id']}'),
        body: json.encode({
          ...updatedTransaction,
          'points_earned': pointsEarned,
          'annual_dividend': annualDividend,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          transaction
            ..addAll(updatedTransaction)
            ..['points_earned'] = pointsEarned
            ..['annual_dividend'] = annualDividend;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction edited successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to edit transaction: ${response.body}')),
        );
      }
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.14:3000/transactions/$transactionId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        searchResults.removeWhere(
            (transaction) => transaction['transaction_id'] == transactionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to delete transaction: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search Members'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _searchBy,
              items: const [
                DropdownMenuItem(value: 'customer_id', child: Text('Search by Customer ID')),
                DropdownMenuItem(value: 'phone_number', child: Text('Search by Phone Number')),
                DropdownMenuItem(value: 'name', child: Text('Search by Name')),
                DropdownMenuItem(value: 'transaction_id', child: Text('Search by Transaction ID')),
              ],
              onChanged: (value) {
                setState(() {
                  _searchBy = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Search By'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter your search query',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchMembers,
                ),
              ),
              onSubmitted: (_) => searchMembers(),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: memberDetails != null
                  ? ListView.builder(
                      itemCount: searchResults.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Card(
                            color: Colors.blueAccent.withOpacity(0.2),
                            child: ListTile(
                              title: Text(
                                'Member ID: ${memberDetails!['id']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Name: ${memberDetails!['name']} ${memberDetails!['surname']}'),
                                  Text(
                                      'Phone: ${memberDetails!['phone_number']}'),
                                  Text('Points: ${memberDetails!['points']}'),
                                  Text(
                                      'Annual Dividend: ${memberDetails!['annual']}'),
                                ],
                              ),
                            ),
                          );
                        } else {
                          final transaction = searchResults[index - 1];
                          return Slidable(
                            key: ValueKey(transaction['transaction_id']),
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) =>
                                      editTransaction(transaction),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) =>
                                      deleteTransaction(transaction['transaction_id']),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text('Transaction ID: ${transaction['transaction_id']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: ${transaction['transaction_date']}'),
                                    Text('Fuel Type: ${transaction['fuel_type_name']}'),
                                    Text('Amount: ${transaction['amount']}'),
                                    Text('Points Earned: ${transaction['points_earned']}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    )
                  : const Center(child: Text('No member details available')),
            ),
          ],
        ),
      ),
    );
  }
}
