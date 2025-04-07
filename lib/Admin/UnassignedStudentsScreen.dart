import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'StudentForm.dart';

class UnassignedStudentsScreen extends StatefulWidget {
  const UnassignedStudentsScreen({super.key});

  @override
  _UnassignedStudentsScreenState createState() => _UnassignedStudentsScreenState();
}

class _UnassignedStudentsScreenState extends State<UnassignedStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _classes = [];
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _unassignedStudentsFuture;

  @override
  void initState() {
    super.initState();
    _unassignedStudentsFuture = _fetchUnassignedStudents();
    _fetchClasses();
  }

  Future<List<Map<String, dynamic>>> _fetchUnassignedStudents() async {
    final query = await FirebaseFirestore.instance.collection('students').get();
    final students = query.docs.where((doc) => !doc.data().containsKey('classId')).map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
    setState(() {
      _students = students;
      _filteredStudents = students;
    });
    return students;
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

  void _filterStudents(String query) {
    final filteredStudents = _students.where((student) {
      final nameLower = student['name'].toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();
    setState(() {
      _searchQuery = query;
      _filteredStudents = filteredStudents;
    });
  }

  Future<void> _assignStudentToClass(String studentId, String classId) async {
    await FirebaseFirestore.instance.collection('students').doc(studentId).update({'classId': classId});
    _unassignedStudentsFuture = _fetchUnassignedStudents();
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems() {
    return _classes.map((classData) {
      return DropdownMenuItem<String>(
        value: classData['id'],
        child: Text(classData['name']),
      );
    }).toList();
  }

  void _confirmAndAssignStudent(String studentId, String classId, String className) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Assignment'),
          content: Text('Are you sure you want to assign this student to $className?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _assignStudentToClass(studentId, classId);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unassigned Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Students',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterStudents,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _unassignedStudentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading students'));
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students found'));
                }
                final studentList = _filteredStudents;
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
                                builder: (context) => StudentForm(studentId: student['id']),
                              ));
                              if (result == true) {
                                setState(() {
                                  _unassignedStudentsFuture = _fetchUnassignedStudents();
                                });
                              }
                            },
                          ),
                          DropdownButton<String>(
                            hint: const Text('Assign to Class'),
                            items: _buildClassDropdownItems(),
                            onChanged: (classId) {
                              if (classId != null) {
                                final className = _classes.firstWhere((classData) => classData['id'] == classId)['name'];
                                _confirmAndAssignStudent(student['id'], classId, className);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => const StudentForm(),
          ));
          if (result == true) {
            setState(() {
              _unassignedStudentsFuture = _fetchUnassignedStudents();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}