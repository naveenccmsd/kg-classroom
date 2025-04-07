import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassStudentsScreen extends StatelessWidget {
  final String classId;

  const ClassStudentsScreen({Key? key, required this.classId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchClassStudents() async {
    final query = await FirebaseFirestore.instance.collection('students').where('classId', isEqualTo: classId).get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Students')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchClassStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final studentList = snapshot.data ?? [];
          return ListView.builder(
            itemCount: studentList.length,
            itemBuilder: (context, index) {
              final student = studentList[index];
              return ListTile(
                title: Text(student['name']),
                subtitle: Text('DOB: ${student['dob']}'),
              );
            },
          );
        },
      ),
    );
  }
}