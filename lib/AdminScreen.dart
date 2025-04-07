import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ClassStudentsScreen.dart';
import 'StudentForm.dart';
import 'ClassForm.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    final query = await FirebaseFirestore.instance.collection('classes').get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchUnassignedStudents() async {
    final query = await FirebaseFirestore.instance.collection('students').where('classId', isEqualTo: null).get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
  }

  Future<void> _deleteClass(String classId) async {
    await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
    setState(() {});
  }

  Future<void> _assignStudentToClass(String studentId, String classId) async {
    await FirebaseFirestore.instance.collection('students').doc(studentId).update({'classId': classId});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Classes'),
              Tab(text: 'Unassigned Students'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClassTab(),
            _buildUnassignedStudentsTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return FloatingActionButton(
              onPressed: () async {
                if (tabController?.index == 0) {
                  // Add Class
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ClassForm(),
                  ));
                  if (result == true) {
                    setState(() {});
                  }
                } else {
                  // Add Student
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const StudentForm(),
                  ));
                  if (result == true) {
                    setState(() {});
                  }
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final classList = snapshot.data ?? [];
        return ListView.builder(
          itemCount: classList.length,
          itemBuilder: (context, index) {
            final classData = classList[index];
            return ListTile(
              title: Text(classData['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ClassForm(classData: classData),
                      ));
                      if (result == true) {
                        setState(() {});
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteClass(classData['id']),
                  ),
                ],
              ),
              onTap: () => _showClassStudents(context, classData['id']),
            );
          },
        );
      },
    );
  }

  Widget _buildUnassignedStudentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUnassignedStudents(),
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
              trailing: DropdownButton<String>(
                hint: const Text('Assign to Class'),
                items: _buildClassDropdownItems(),
                onChanged: (classId) {
                  if (classId != null) {
                    _assignStudentToClass(student['id'], classId);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems() {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Unassigned'),
      ),
      ..._classes.map((classData) {
        return DropdownMenuItem<String>(
          value: classData['id'],
          child: Text(classData['name']),
        );
      }).toList(),
    ];
  }

  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses().then((classes) {
      setState(() {
        _classes = classes;
      });
    });
  }

  void _showClassStudents(BuildContext context, String classId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ClassStudentsScreen(classId: classId),
    ));
  }
}