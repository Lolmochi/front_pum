import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RewardManagementPage extends StatefulWidget {
  const RewardManagementPage({super.key});

  @override
  _RewardManagementPageState createState() => _RewardManagementPageState();
}

class _RewardManagementPageState extends State<RewardManagementPage> {
  final _rewardNameController = TextEditingController();
  final _pointsRequiredController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Function to generate a random 10-character alphanumeric reward ID
  String generateRewardId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(10, (index) => chars[Random().nextInt(chars.length)]).join('');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<void> _submitReward() async {
    if (_image == null ||
        _rewardNameController.text.isEmpty ||
        _pointsRequiredController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all the fields and select an image'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String rewardName = _rewardNameController.text;
    String pointsRequired = _pointsRequiredController.text;
    String description = _descriptionController.text;
    String rewardId = generateRewardId(); // Generate reward_id

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.44:3000/rewards'),
    );
    
    // Add generated reward_id to request fields
    request.fields['reward_id'] = rewardId;
    request.fields['reward_name'] = rewardName;
    request.fields['points_required'] = pointsRequired;
    request.fields['description'] = description;
    
    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    try {
      var response = await request.send();

      if (response.statusCode == 201) { // Changed to 201 for successful creation
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reward added successfully!'),
          backgroundColor: Colors.green,
        ));
        // Clear the form
        _rewardNameController.clear();
        _pointsRequiredController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add reward: $responseBody'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Management'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.camera_alt, size: 50),
                    )
                  : Image.file(
                      _image!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rewardNameController,
              decoration: const InputDecoration(
                labelText: 'Reward Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pointsRequiredController,
              decoration: const InputDecoration(
                labelText: 'Points Required',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReward,
              child: const Text('Submit Reward'),
            ),
          ],
        ),
      ),
    );
  }
}
