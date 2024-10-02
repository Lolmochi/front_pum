import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GetRewardedPage extends StatefulWidget {
  final String staff_id;

  const GetRewardedPage({super.key, required this.staff_id});

  @override
  _GetRewardedPageState createState() => _GetRewardedPageState();
}

class _GetRewardedPageState extends State<GetRewardedPage> {
  List<dynamic> redemptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRedemptions();
  }

  // Function to fetch redemption data from the server
  Future<void> fetchRedemptions() async {
    final url = Uri.parse('http://192.168.1.14:3000/redemptions/get_redemptions'); // Replace with your API URL
    final response = await http.post(
      url,
      body: {
        'staff_id': widget.staff_id, // Pass staff_id to fetch relevant redemptions
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        redemptions = data['redemptions']; // Assuming API returns redemptions in 'redemptions' field
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to update the status of a redemption
  Future<void> updateRedemptionStatus(String redemptionId) async {
    final url = Uri.parse('http://192.168.1.14:3000/redemptions/update_redemption_status'); // Replace with your API URL
    final response = await http.post(
      url,
      body: {
        'redemption_id': redemptionId,
        'staff_id': widget.staff_id,
      },
    );

    if (response.statusCode == 200) {
      // Refresh the list after updating the status
      fetchRedemptions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redemption status updated to completed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Redemptions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : redemptions.isEmpty
              ? const Center(child: Text('No pending redemptions'))
              : ListView.builder(
                  itemCount: redemptions.length,
                  itemBuilder: (context, index) {
                    final redemption = redemptions[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text('Customer ID: ${redemption['customer_id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reward ID: ${redemption['reward_id']}'),
                            Text('Redemption Date: ${redemption['redemption_date']}'),
                            Text('Points Used: ${redemption['points_used']}'),
                            Text('Status: ${redemption['status']}'),
                          ],
                        ),
                        trailing: redemption['status'] == 'pending'
                            ? ElevatedButton(
                                onPressed: () {
                                  _showConfirmationDialog(redemption['redemption_id']);
                                },
                                child: const Text('Mark as Completed'),
                              )
                            : const Text('Completed'),
                      ),
                    );
                  },
                ),
    );
  }

  // Function to show confirmation dialog before updating status
  void _showConfirmationDialog(String redemptionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Redemption'),
          content: const Text('Are you sure this item has been redeemed by the customer?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                updateRedemptionStatus(redemptionId); // Update status
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
