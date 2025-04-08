import 'package:flutter/material.dart';
import '../services/teacher_service.dart';

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
  final _teacherService = TeacherService();

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
      final isEmailInUse = await _teacherService.isEmailInUse(email, previousEmail);
      if (isEmailInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already in use by another student or teacher')),
        );
        return;
      }

      _formKey.currentState!.save();
      final teacherData = {
        'name': name,
        'email': email,
      };
      await _teacherService.saveTeacher(previousEmail, teacherData);
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