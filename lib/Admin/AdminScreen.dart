import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ClassStudentsScreen.dart';
import 'ClassForm.dart';
import 'TeacherForm.dart';
import 'UnassignedStudentsScreen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Future<List<Map<String, dynamic>>> _fetchTeachers() async {
    final query = await FirebaseFirestore.instance.collection('teachers').get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'email': data['email'] ?? 'No Email',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    final query = await FirebaseFirestore.instance.collection('classes').get();
    final classes = query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();
    classes.insert(0, {'id': null, 'name': 'Unassigned Students'});
    return classes;
  }

  Future<void> _deleteClass(String classId) async {
    await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
    setState(() {});
  }

  Future<void> _deleteTeacher(String teacherId) async {
    await FirebaseFirestore.instance.collection('teachers').doc(teacherId).delete();
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
              Tab(text: 'Teachers'),
              Tab(text: 'Classes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTeacherTab(),
            _buildStudentTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return FloatingActionButton(
              onPressed: () async {
                if (tabController?.index == 0) {
                  // Add Teacher
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const TeacherForm(),
                  ));
                  if (result == true) {
                    setState(() {});
                  }
                } else {
                  // Add Class
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ClassForm(),
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

  Widget _buildTeacherTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTeachers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final teacherList = snapshot.data ?? [];
        return ListView.builder(
          itemCount: teacherList.length,
          itemBuilder: (context, index) {
            final teacher = teacherList[index];
            return ListTile(
              title: Text(teacher['name']),
              subtitle: Text('Email: ${teacher['email']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => TeacherForm(teacher: teacher),
                      ));
                      if (result == true) {
                        setState(() {});
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTeacher(teacher['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentTab() {
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
              trailing: classData['id'] != null
                  ? Row(
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
              )
                  : null,
              onTap: classData['id'] != null
                  ? () => _showClassStudents(context, classData['id'])
                  : () => _showUnassignedStudents(context),
            );
          },
        );
      },
    );
  }

  void _showClassStudents(BuildContext context, String classId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ClassStudentsScreen(classId: classId),
    ));
  }

  void _showUnassignedStudents(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => UnassignedStudentsScreen(),
    ));
  }
}