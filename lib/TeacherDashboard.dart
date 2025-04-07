
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  /*File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadHomeworkImage(_image!);
    }
  }

  Future<void> _uploadHomeworkImage(File image) async {
    final fileName = 'homework_${DateTime.now().millisecondsSinceEpoch}.png';
    final ref = FirebaseStorage.instance.ref().child('homeworks/$fileName');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('homeworks').add({
      'teacherId': FirebaseAuth.instance.currentUser!.uid,
      'imageUrl': url,
      'createdAt': Timestamp.now(),
      'status': 'assigned'
    });
  }*/
  final TextEditingController _urlController = TextEditingController();


  Future<void> _addWebpageUrl() async {
    String? url = _urlController.text;

    if (url.isEmpty) {
      final clipboardData = await Clipboard.getData('text/plain');
      url = clipboardData?.text;
    }


    if (url != null && Uri.tryParse(url)?.hasAbsolutePath == true) {
      await FirebaseFirestore.instance.collection('homeworks').add({
        'teacherId': FirebaseAuth.instance.currentUser!.uid,
        'imageUrl': url,
        'createdAt': Timestamp.now(),
        'status': 'assigned'
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Input or clipboard does not contain a valid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Enter URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addWebpageUrl,
              child: const Text('Add Webpage URL'),
            ),
          ],
        ),
      ),
    );
  }
}