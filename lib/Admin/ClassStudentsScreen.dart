import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'StudentForm.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String classId;

  const ClassStudentsScreen({Key? key, required this.classId}) : super(key: key);

  @override
  _ClassStudentsScreenState createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  String? _className;

  @override
  void initState() {
    super.initState();
    _fetchClassName();
  }

  Future<void> _fetchClassName() async {
    final doc = await FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
    setState(() {
      _className = doc.data()?['name'] ?? 'Class Students';
    });
  }

  Future<List<Map<String, dynamic>>> _fetchClassStudents() async {
    final query = await FirebaseFirestore.instance.collection('students').where('classId', isEqualTo: widget.classId).get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
  }

  Future<void> _deleteStudent(String studentId) async {
    await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_className ?? 'Class Students'),
      ),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => StudentForm(studentId: student['id'], classId: widget.classId),
                        ));
                        if (result == true) {
                          setState(() {});
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _deleteStudent(student['id']);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => StudentForm(classId: widget.classId),
          ));
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}