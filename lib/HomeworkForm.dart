import 'dart:convert';
import 'package:flutter/material.dart';

class HomeworkForm extends StatefulWidget {
  final Map<String, dynamic>? homework;

  const HomeworkForm({Key? key, this.homework}) : super(key: key);

  @override
  _HomeworkFormState createState() => _HomeworkFormState();
}

class _HomeworkFormState extends State<HomeworkForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _images = [];

  @override
  void initState() {
    super.initState();
    if (widget.homework != null) {
      _titleController.text = widget.homework!['title'] ?? '';
      _descriptionController.text = widget.homework!['description'] ?? '';
      _images.addAll(List<String>.from(widget.homework!['images'] ?? []));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homework Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}