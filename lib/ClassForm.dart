import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassForm extends StatefulWidget {
  final Map<String, dynamic>? classData;

  const ClassForm({Key? key, this.classData}) : super(key: key);

  @override
  _ClassFormState createState() => _ClassFormState();
}

class _ClassFormState extends State<ClassForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.classData?['name'] ?? '';
  }

  Future<void> _saveClass() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final data = {
        'name': _name,
      };
      if (widget.classData == null) {
        await FirebaseFirestore.instance.collection('classes').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classData!['id'])
            .update(data);
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveClass,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}