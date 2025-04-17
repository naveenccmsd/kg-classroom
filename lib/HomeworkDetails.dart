import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class HomeworkDetails extends StatefulWidget {
  final Map<String, dynamic> homework;

  const HomeworkDetails({Key? key, required this.homework}) : super(key: key);

  @override
  _HomeworkDetailsState createState() => _HomeworkDetailsState();
}

class _HomeworkDetailsState extends State<HomeworkDetails> {
  late List<Map<String, dynamic>> _images;

  @override
  void initState() {
    super.initState();
    _images = [];
    _fetchExistingImages();
  }
  Future<void> _fetchExistingImages() async {
    final homeworkDoc = FirebaseFirestore.instance
        .collection('homeworks')
        .doc(widget.homework['title']);
    final imagesCollection = homeworkDoc.collection('images');

    final snapshot = await imagesCollection.get();
    final existingImages = snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'data': doc['data'],
      };
    }).toList();

    setState(() {
      _images = existingImages;
    });
  }
  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      // Sort files alphabetically by their names
      final sortedFiles = result.files..sort((a, b) => a.name.compareTo(b.name));

      final newImages = sortedFiles.map((file) {
        final Uint8List? bytes = file.bytes;
        if (bytes != null) {
          return {'name': file.name, 'data': base64Encode(bytes)};
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      setState(() {
        _images.addAll(newImages); // Append sorted images
      });

      await _updateImagesInFirestore();
    }
  }

  Future<void> _updateImagesInFirestore() async {
    final homeworkDoc = FirebaseFirestore.instance
        .collection('homeworks')
        .doc(widget.homework['title']); // Use homework title as document ID

    // Update the top-level homework details
    await homeworkDoc.set({
      'title': widget.homework['title'],
      'description': widget.homework['description'],
    });

    // Add each image as a separate document in the 'images' subcollection
    final imagesCollection = homeworkDoc.collection('images');
    for (int i = 0; i < _images.length; i++) {
      await imagesCollection.doc('image_$i').set(_images[i]);
    }
  }

  Future<void> _deleteImage(int index) async {
    final homeworkDoc = FirebaseFirestore.instance
        .collection('homeworks')
        .doc(widget.homework['title']);
    final imagesCollection = homeworkDoc.collection('images');

    // Delete the image document from Firestore
    await imagesCollection.doc('image_$index').delete();

    // Remove the image from the local list and update Firestore
    setState(() {
      _images.removeAt(index);
    });

    await _updateImagesInFirestore();
  }

  void _viewImage(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(base64Decode(base64Image)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.homework['title'] ?? 'Homework Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.homework['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _images.removeAt(oldIndex);
                    _images.insert(newIndex, item);
                  });
                  _updateImagesInFirestore();
                },
                children: _images
                    .asMap()
                    .entries
                    .map((entry) => Card(
                  key: ValueKey(entry.key),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8.0),
                    leading: GestureDetector(
                      onTap: () => _viewImage(entry.value['data']!),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(entry.value['data']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    title: Text(entry.value['name']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteImage(entry.key),
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}