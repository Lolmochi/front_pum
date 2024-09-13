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
  String _searchBy = 'id'; // Default search option
  List<dynamic> searchResults = [];
  Map<String, dynamic>? memberDetails;

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _searchController.dispose();
    super.dispose();
  }

  void searchMembers() async {
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.16:3000/costumers/advanced_search?searchBy=$_searchBy&query=${_searchController.text}'),
    );

    if (response.statusCode == 200) {
      List<dynamic> results = json.decode(response.body);

      setState(() {
        if (results.isNotEmpty) {
          memberDetails = {
            'customer_id': results[0]['customer_id'],
            'first_name': results[0]['first_name'],
            'last_name': results[0]['last_name'],
            'phone_number': results[0]['phone_number'],
            'points_balance': results[0]['points_balance'],
            'dividend': results[0]['dividend']
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
                  DropdownMenuItem(
                      value: 'ดีเซลพรีเมี่ยม', child: Text('ดีเซลพรีเมี่ยม')),
                  DropdownMenuItem(value: 'ไฮดีเซล', child: Text('ไฮดีเซล')),
                  DropdownMenuItem(
                      value: 'ไฮพรีเมียม 97', child: Text('ไฮพรีเมียม 97')),
                  DropdownMenuItem(value: 'e85', child: Text('e85')),
                  DropdownMenuItem(value: 'e20', child: Text('e20')),
                  DropdownMenuItem(
                      value: 'แก็สโซฮอล 91', child: Text('แก็สโซฮอล 91')),
                  DropdownMenuItem(
                      value: 'แก็สโซฮอล 95', child: Text('แก็สโซฮอล 95')),
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
                  'price': price,
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
      final pointsEarned = (updatedTransaction['price'] as num).toInt();
      final annualDividend = (pointsEarned * 0.01).toStringAsFixed(2);

      final response = await http.put(
        Uri.parse(
            'http://192.168.1.16:3000/transactions/${transaction['transaction_id']}'),
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
      Uri.parse('http://192.168.1.38:3000/transactions/$transactionId'),
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
                DropdownMenuItem(value: 'id', child: Text('Search by ID')),
                DropdownMenuItem(
                    value: 'phone_number',
                    child: Text('Search by Phone Number')),
                DropdownMenuItem(value: 'name', child: Text('Search by Name')),
                DropdownMenuItem(
                    value: 'transaction_id',
                    child: Text('Search by Transaction ID')),
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
                                  onPressed: (context) => deleteTransaction(
                                      transaction['transaction_id']),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: Card(
                              child: ListTile(
                                title: Text(
                                    'Transaction ID: ${transaction['transaction_id']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Fuel Type: ${transaction['fuel_type']}'),
                                    Text('Price: ${transaction['price']}'),
                                    Text(
                                        'Points Earned: ${transaction['points_earned']}'),
                                    Text(
                                        'Annual Dividend: ${transaction['annual_dividend']}'),
                                    Text(
                                        'Timestamp: ${transaction['timestamp']}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    )
                  : const Center(child: Text('No results found')),
            ),
          ],
        ),
      ),
    );
  }
}
