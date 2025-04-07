import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeworkForm extends StatefulWidget {
  final Map<String, dynamic>? homework;

  const HomeworkForm({Key? key, this.homework}) : super(key: key);

  @override
  _HomeworkFormState createState() => _HomeworkFormState();
}

class _HomeworkFormState extends State<HomeworkForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;

  @override
  void initState() {
    super.initState();
    _title = widget.homework?['title'] ?? '';
    _description = widget.homework?['description'] ?? '';
  }

  Future<void> _saveHomework() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final data = {
        'title': _title,
        'description': _description,
        'createdAt': Timestamp.now(),
      };
      if (widget.homework == null) {
        await FirebaseFirestore.instance.collection('homeworks').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('homeworks')
            .doc(widget.homework!['id'])
            .update(data);
      }
      Navigator.pop(context, true);
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
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveHomework,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}