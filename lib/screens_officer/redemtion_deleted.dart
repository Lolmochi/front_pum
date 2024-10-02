import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeleteRedemptionScreen extends StatefulWidget {
  @override
  _DeleteRedemptionScreenState createState() => _DeleteRedemptionScreenState();
}

class _DeleteRedemptionScreenState extends State<DeleteRedemptionScreen> {
  late Future<List<dynamic>> _redemptions;

  @override
  void initState() {
    super.initState();
    _redemptions = _fetchRedemptions();
  }

  Future<List<dynamic>> _fetchRedemptions() async {
    final response = await http.get(Uri.parse('http://192.168.1.14:3000/redemptions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load redemptions');
    }
  }

  Future<void> _deleteRedemption(String redemptionId) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.14:3000/redemptions/$redemptionId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _redemptions = _fetchRedemptions(); // Refresh the list after deleting
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redemption $redemptionId deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete redemption')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Redemption'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _redemptions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No redemptions found.'));
          } else {
            final redemptions = snapshot.data!;
            return ListView.builder(
              itemCount: redemptions.length,
              itemBuilder: (context, index) {
                final redemption = redemptions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      'Redemption ID: ${redemption['redemption_id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    subtitle: Text(
                      'Customer ID: ${redemption['customer_id']}\n'
                      'Reward ID: ${redemption['reward_id']}\n'
                      'Date: ${redemption['redemption_date']}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        _confirmDelete(context, redemption['redemption_id']);
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String redemptionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete redemption $redemptionId?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRedemption(redemptionId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
