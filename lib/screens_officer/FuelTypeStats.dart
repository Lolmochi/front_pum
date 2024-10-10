import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FuelTypeStatsPage extends StatefulWidget {
  @override
  _FuelTypeStatsPageState createState() => _FuelTypeStatsPageState();
}

class _FuelTypeStatsPageState extends State<FuelTypeStatsPage> {
  String? selectedFuelType;
  List<String> fuelTypes = [];
  int peopleCount = 0;
  int refuelCount = 0;

  @override
  void initState() {
    super.initState();
    fetchFuelTypes(); // Load fuel types when the page loads
  }

  // Fetch the list of fuel types from the API
  Future<void> fetchFuelTypes() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.44:3000/fuel_types'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          fuelTypes = data.map((item) => item['fuel_type_name'].toString()).toList();
        });
      }
    } catch (e) {
      print("Error fetching fuel types: $e");
    }
  }

  // Fetch stats for the selected fuel type
  Future<void> fetchFuelTypeStats(String fuelType) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.44:3000/fuel_type_stats?fuel_type=$fuelType'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          peopleCount = data['peopleCount'];
          refuelCount = data['refuelCount'];
        });
      }
    } catch (e) {
      print("Error fetching fuel type stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fuel Type Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Fuel Type',
                border: OutlineInputBorder(),
              ),
              value: selectedFuelType,
              onChanged: (value) {
                setState(() {
                  selectedFuelType = value;
                });
                fetchFuelTypeStats(value!);
              },
              items: fuelTypes.map((fuelType) {
                return DropdownMenuItem(
                  value: fuelType,
                  child: Text(fuelType),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            if (selectedFuelType != null)
              Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fuel Type: $selectedFuelType',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'People Refueled: $peopleCount',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Total Refuels: $refuelCount',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
