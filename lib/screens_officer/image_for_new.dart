import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageDragDropPage extends StatefulWidget {
  final String officer_id;

  const ImageDragDropPage({super.key, required this.officer_id});

  @override
  _ImageDragDropPageState createState() => _ImageDragDropPageState();
}

class _ImageDragDropPageState extends State<ImageDragDropPage> {
  List<Map<String, dynamic>> _activeImages = [];
  List<Map<String, dynamic>> _allImages = [];
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _description = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.get(Uri.parse('http://192.168.1.34:3000/get_images'));

    if (response.statusCode == 200) {
      var images = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      setState(() {
        _activeImages = images
            .where((img) => img['status'] == 'true')
            .map((img) => {
                  ...img,
                  'image_url': 'http://192.168.1.34:3000/uploadnews/${img['image_url']}',
                })
            .toList();
        _allImages = images
            .where((img) => img['status'] == 'false')
            .map((img) => {
                  ...img,
                  'image_url': 'http://192.168.1.34:3000/uploadnews/${img['image_url']}',
                })
            .toList();
      });
    } else {
      _showErrorDialog('Failed to fetch images');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateImageStatus(int imageId, String newStatus) async {
    var response = await http.post(
      Uri.parse('http://192.168.1.34:3000/update_image_status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_id': imageId,
        'officer_id': widget.officer_id,
        'status': newStatus,
      }),
    );

    if (response.statusCode == 200) {
      _fetchImages();
    } else {
      _showErrorDialog('Failed to update image status');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.34:3000/upload_image'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.fields['officer_id'] = widget.officer_id;
    request.fields['description'] = _description;

    var response = await request.send();

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
      _fetchImages();
    } else {
      _showErrorDialog('Image upload failed');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(
                    _imageFile!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : const Text('No image selected', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_imageFile != null) {
                      _uploadImage(_imageFile!);
                    }
                  },
                  child: const Text('Upload Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithDescription(String imageUrl, String description) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                description.isNotEmpty ? description : 'No description',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Implement delete image functionality here
                _deleteImage(imageUrl); // Create this function
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveImageSection() {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final image = details.data;
        if (_activeImages.length < 6) {
          _updateImageStatus(image['image_id'], 'true');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Active image slots are full (6 max).')),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Drag Images Here (Max 6)', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activeImages.length,
                  itemBuilder: (context, index) {
                    final image = _activeImages[index];
                    return Draggable<Map<String, dynamic>>(
                      data: image,
                      feedback: Image.network(image['image_url'], width: 100),
                      child: _buildImageWithDescription(
                        image['image_url'],
                        image['description'] ?? 'No description',
                      ),
                      onDragCompleted: () {
                        _updateImageStatus(image['image_id'], 'false');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageGallerySection() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: _allImages.length,
        itemBuilder: (context, index) {
          final image = _allImages[index];
          return Draggable<Map<String, dynamic>>(
            data: image,
            feedback: Image.network(image['image_url'], width: 100),
            child: _buildImageWithDescription(
              image['image_url'],
              image['description'] ?? 'No description',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildUploadSection(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Active Images', style: TextStyle(fontSize: 20)),
                  ),
                  _buildActiveImageSection(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('All Images', style: TextStyle(fontSize: 20)),
                  ),
                  _buildImageGallerySection(),
                ],
              ),
            ),
    );
  }

  void _deleteImage(String imageUrl) {
    // Implement delete image functionality here
  }
}
