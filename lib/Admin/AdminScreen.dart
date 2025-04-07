import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ClassForm.dart';
import 'ClassStudentsScreen.dart';
import 'TeacherForm.dart';
import 'UnassignedStudentsScreen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const List<String> unassignedStudents = [
    'Student 1',
    'Student 2',
    'Student 3',
  ];

  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final query = await FirebaseFirestore.instance.collection('classes').get();
    setState(() {
      _classes = query.docs.asMap().entries.map((entry) {
        final doc = entry.value;
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'No Name',
          'order': data['order'] ?? entry.key, // Use the index as the default order
        };
      }).toList();
      _classes.sort((a, b) => a['order'].compareTo(b['order'])); // Sort by order
      _classes.insert(0, {'id': null, 'name': 'Unassigned Students'});
      _isLoading = false;
    });
    print('Classes fetched: $_classes'); // Debug print
  }

  Future<void> _updateClassOrder() async {
    for (int i = 0; i < _classes.length; i++) {
      await FirebaseFirestore.instance.collection('classes').doc(_classes[i]['id']).update({'order': i});
    }
  }

  Future<void> _deleteClass(String classId) async {
    await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
    _fetchClasses();
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
            _buildClassTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return FloatingActionButton(
              onPressed: () async {
                if (tabController.index == 0) {
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
                    _fetchClasses();
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

  Widget _buildClassTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex == 0 || newIndex == 0) {
            return; // Prevent reordering the first item
          }
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final classData = _classes.removeAt(oldIndex);
          _classes.insert(newIndex, classData);
        });
        _updateClassOrder();
      },
      children: _classes.map((classData) {
        return ListTile(
          key: ValueKey(classData['id']),
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
                    _fetchClasses();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteClass(classData['id']),
              ),
            ],
          ),
          onTap: classData['id'] != null
              ? () => _showClassStudents(context, classData['id'])
              : () => _showUnassignedStudents(context),
        );
      }).toList(),
    );
  }

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

  static void _showUnassignedStudents(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => UnassignedStudentsScreen(),
    ));
  }

  void _showClassStudents(BuildContext context, String classId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ClassStudentsScreen(classId: classId),
    ));
  }
}