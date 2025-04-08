import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherForm extends StatefulWidget {
  final Map<String, dynamic>? teacher;

  const TeacherForm({Key? key, this.teacher}) : super(key: key);

  @override
  _TeacherFormState createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.teacher?['email'] ?? '';
    _nameController.text = widget.teacher?['name'] ?? '';

  }

  Future<void> _saveTeacher() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final name = _nameController.text;
      final previousEmail = widget.teacher?['email'];


      // Check if email exists in students collection
      final existingStudent = await FirebaseFirestore.instance
          .collection('students')
          .doc(email)
          .get();
      print(email);
      print(existingStudent.id);

      // Check if email exists in teachers collection
      final existingTeacher = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(email)
          .get();
      print(existingTeacher.id);
      if ((existingTeacher.exists && existingTeacher.id != previousEmail) || existingStudent.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email is already in use by another student or teacher')),
          );
        return;
      }

      _formKey.currentState!.save();
      final data = {
        'name': name,
        'email': email,
      };
      // Remove the previous email document if the email has changed
      if (previousEmail != null && previousEmail != email) {
        await FirebaseFirestore.instance.collection('teachers').doc(previousEmail).delete();
      }
      // Save the new or updated teacher data
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(email)
          .set(data);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },

              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },

              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTeacher,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}