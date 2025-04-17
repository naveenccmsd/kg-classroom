import 'package:flutter/material.dart';
import 'package:kg_classroom/services/student_service.dart';
import '../services/class_service.dart';
import '../services/teacher_service.dart';
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
  final _classService = ClassService();
  final _studentService = StudentService();
  final _teacherService = TeacherService();
  List<Map<String, dynamic>> _classes = [];
  final Map<String, dynamic> _staticClasses = {'id': "", 'name': 'Unassigned Students'};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final classes = await _classService.fetchClasses();
    setState(() {
      _classes = classes..sort((a, b) => a['order'].compareTo(b['order']));
      _isLoading = false;
    });
  }

  Future<void> _updateClassOrder() async {
    await _classService.updateClassOrder(_classes);
  }

  Future<void> _deleteClass(String classId) async {
    final studentQuery = await _studentService.fetchClassStudents(classId);
    final studentCount = studentQuery.length;

    if (studentCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('This class has $studentCount students. Do you want to delete the class and unassign the students?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        return;
      }

      await _studentService.unassignStudentsFromClass(classId);
    }

    await _classService.deleteClass(classId);
    _fetchClasses();
  }

  Future<void> _deleteTeacher(String teacherId) async {
    await _teacherService.deleteTeacher(teacherId);
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
                  final result = await Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const TeacherForm(),
                  ));
                  if (result == true) {
                    setState(() {});
                  }
                } else {
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
      future: _teacherService.fetchTeachers(),
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
        if (oldIndex == 0 || newIndex == 0 || oldIndex == newIndex) {
          return;
        }
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final classData = _classes.removeAt(oldIndex - 1);
          _classes.insert(newIndex - 1, classData);
          for (int i = 0; i < _classes.length; i++) {
            _classes[i]['order'] = i;
          }
        });
        _updateClassOrder();
      },
      children: [
        buildUIClasses(_staticClasses),
        ..._classes.map(buildUIClasses).toList(),
      ],
    );
  }

  ListTile buildUIClasses(classData) {
    final bool hasValidId = classData['id'] != null && classData['id'].isNotEmpty;

    return ListTile(
      key: ValueKey(classData['id']),
      title: Text(classData['name']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasValidId)
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
          if (hasValidId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteClass(classData['id']),
            ),
        ],
      ),
      onTap: hasValidId
          ? () => _showClassStudents(context, classData['id'])
          : () => _showUnassignedStudents(context),
    );
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