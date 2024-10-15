import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FuelTypeStatsPage extends StatefulWidget {
  const FuelTypeStatsPage({super.key});

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
      final response = await http.get(Uri.parse('http://192.168.1.20:3000/fuel_types'));
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
      final response = await http.get(Uri.parse('http://192.168.1.20:3000/fuel_type_stats?fuel_type=$fuelType'));
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
        title: const Text('Fuel Type Statistics'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Fuel Type',
                prefixIcon: const Icon(Icons.local_gas_station, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: selectedFuelType,
              onChanged: (value) {
                setState(() {
                  selectedFuelType = value;
                });
                if (value != null) {
                  fetchFuelTypeStats(value);
                }
              },
              items: fuelTypes.map((fuelType) {
                return DropdownMenuItem(
                  value: fuelType,
                  child: Text(fuelType, overflow: TextOverflow.ellipsis), // แสดงชื่อประเภทน้ำมันด้วย overflow
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (selectedFuelType != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4.0,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_gas_station, size: 30, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          Expanded( // ใช้ Expanded เพื่อให้มีพื้นที่มากขึ้นในการแสดงผล
                            child: Text(
                              'Fuel Type: $selectedFuelType',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                              overflow: TextOverflow.ellipsis, // แสดง overflow
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.blueAccent),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 24, color: Colors.black54),
                          const SizedBox(width: 10),
                          Text(
                            'People Refueled: $peopleCount',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.repeat, size: 24, color: Colors.black54),
                          const SizedBox(width: 10),
                          Text(
                            'Total Refuels: $refuelCount',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
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
