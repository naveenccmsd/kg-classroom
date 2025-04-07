import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentForm extends StatefulWidget {
  final String? studentId;
  final String? classId;

  const StudentForm({Key? key, this.studentId, this.classId}) : super(key: key);

  @override
  _StudentFormState createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    if (widget.classId != null) {
      _selectedClassId = widget.classId;
    }
    if (widget.studentId != null) {
      _fetchStudentData();
    }
  }

  Future<void> _fetchClasses() async {
    final query = await FirebaseFirestore.instance.collection('classes').get();
    final classes = query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();
    setState(() {
      _classes = classes;
    });
  }

  Future<void> _fetchStudentData() async {
    final doc = await FirebaseFirestore.instance.collection('students').doc(widget.studentId).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _selectedClassId = data['classId'];
    }
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState?.validate() ?? false) {
      final studentData = {
        'name': _nameController.text,
        'dob': _dobController.text,
        'classId': _selectedClassId,
      };
      if (widget.studentId != null) {
        await FirebaseFirestore.instance.collection('students').doc(widget.studentId).update(studentData);
      } else {
        await FirebaseFirestore.instance.collection('students').add(studentData);
      }
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
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
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date of birth';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Class'),
                value: _selectedClassId,
                items: _classes.map((classData) {
                  return DropdownMenuItem<String>(
                    value: classData['id'],
                    child: Text(classData['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                  });
                },
                onSaved: (value) {
                  _selectedClassId = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStudent,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}