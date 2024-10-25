import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageManagementScreen extends StatefulWidget {
  final String officer_id;

  const ImageManagementScreen({super.key, required this.officer_id});

  @override
  _ImageManagementScreenState createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen> {
  late Future<List<dynamic>> _images;

  @override
  void initState() {
    super.initState();
    _images = _fetchImages(); // ดึงข้อมูลรูปภาพจาก API เมื่อหน้าโหลด
  }

  Future<List<dynamic>> _fetchImages() async {
    final response = await http.get(Uri.parse('http://192.168.1.34:3000/images'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> _updateImageStatus(int imageId, bool status) async {
    final response = await http.patch(
      Uri.parse('http://192.168.1.34:3000/images/$imageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'status': status ? 'true' : 'false',
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _images = _fetchImages(); // รีเฟรชข้อมูลรูปภาพหลังจากแก้ไข
      });
    } else {
      throw Exception('Failed to update image');
    }
  }

  Future<void> _updateImageDescription(int imageId, String description) async {
    final response = await http.patch(
      Uri.parse('http://192.168.1.34:3000/images/$imageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _images = _fetchImages();
      });
    } else {
      throw Exception('Failed to update description');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Management'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No images found.'));
          } else {
            final images = snapshot.data!;
            return ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Image.network(image['image_url']),
                    title: Text('Image ID: ${image['image_id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${image['description'] ?? 'No description'}'),
                        Row(
                          children: [
                            const Text('Status: '),
                            Checkbox(
                              value: image['status'] == 'true',
                              onChanged: (bool? newValue) {
                                if (newValue != null) {
                                  _updateImageStatus(image['image_id'], newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () {
                        TextEditingController descriptionController = TextEditingController(text: image['description']);
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Edit Description'),
                              content: TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(hintText: 'Enter new description'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _updateImageDescription(image['image_id'], descriptionController.text);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
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
}
