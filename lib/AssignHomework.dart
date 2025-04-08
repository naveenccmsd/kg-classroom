import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignHomework extends StatefulWidget {
  final Map<String, dynamic> homework;
  const AssignHomework({Key? key, required this.homework}) : super(key: key);

  @override
  _AssignHomeworkState createState() => _AssignHomeworkState();
}

class _AssignHomeworkState extends State<AssignHomework> {
  final List<String> _selectedStudents = [];

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    final query = await FirebaseFirestore.instance.collection('students').get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _assignHomework() async {
    for (final student in _selectedStudents) {
      await FirebaseFirestore.instance.collection('assignments').add({
        'student': student,
        'homework': widget.homework['id'],
        'assignedAt': Timestamp.now(),
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Homework')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final studentList = snapshot.data ?? [];
          return ListView.builder(
            itemCount: studentList.length,
            itemBuilder: (context, index) {
              final student = studentList[index];
              final studentName = student['name'] ?? 'Unknown'; // Default value
              final studentId = student['id'] ?? ''; // Default value

              if (studentId.isEmpty) {
                return const SizedBox.shrink(); // Skip invalid entries
              }

              return CheckboxListTile(
                title: Text(studentName),
                value: _selectedStudents.contains(studentId),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudents.add(studentId);
                    } else {
                      _selectedStudents.remove(studentId);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _assignHomework,
        child: const Icon(Icons.check),
      ),
    );
  }
}