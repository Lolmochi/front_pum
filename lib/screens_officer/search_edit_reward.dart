import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SearchAndEditRewardPage extends StatefulWidget {
  late final String officer_id;

  @override
  _SearchAndEditRewardPageState createState() => _SearchAndEditRewardPageState();
}

class _SearchAndEditRewardPageState extends State<SearchAndEditRewardPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _rewards;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _rewards = _fetchRewards();
  }

  Future<List<dynamic>> _fetchRewards([String query = '']) async {
    final response = await http.get(Uri.parse('http://192.168.1.44:3000/rewards?query=$query'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load rewards');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateReward(String rewardId, String rewardName, int pointsRequired, String description, File? imageFile) async {
    var uri = Uri.parse('http://192.168.1.44:3000/rewards/$rewardId');
    var request = http.MultipartRequest('PUT', uri);

    request.fields['reward_name'] = rewardName;
    request.fields['points_required'] = pointsRequired.toString();
    request.fields['description'] = description;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Reward updated successfully');
    } else {
      print('Failed to update reward: ${response.statusCode}');
      throw Exception('Failed to update reward');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search and Edit Rewards'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Rewards',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _rewards = _fetchRewards(_searchController.text);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _rewards,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No rewards found.'));
                  } else {
                    final rewards = snapshot.data!;
                    return ListView.builder(
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final reward = rewards[index];
                        return Card(
                          child: ListTile(
                            leading: Image.network(
                              'http://192.168.1.44:3000/uploads/${reward['image']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported, size: 50);
                              },
                            ),
                            title: Text(reward['reward_name']),
                            subtitle: Text('Points: ${reward['points_required']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showEditDialog(reward);
                              },
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

  void showEditDialog(Map<String, dynamic> reward) {
    final TextEditingController rewardNameController = TextEditingController(text: reward['reward_name']);
    final TextEditingController pointsController = TextEditingController(text: reward['points_required'].toString());
    final TextEditingController descriptionController = TextEditingController(text: reward['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reward'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: rewardNameController,
                  decoration: const InputDecoration(labelText: 'Reward Name'),
                ),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(labelText: 'Points Required'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                _selectedImage != null
                    ? Image.file(_selectedImage!, height: 100)
                    : Image.network(
                        'http://192.168.1.44:3000/uploads/${reward['image']}',
                        height: 100,
                      ),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Change Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _updateReward(
                    reward['reward_id'].toString(),
                    rewardNameController.text,
                    int.parse(pointsController.text),
                    descriptionController.text,
                    _selectedImage,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _rewards = _fetchRewards(_searchController.text);
                  });
                } catch (e) {
                  // แสดงข้อความข้อผิดพลาดหากการอัปเดตไม่สำเร็จ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating reward: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
