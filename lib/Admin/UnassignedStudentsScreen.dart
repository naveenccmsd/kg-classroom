import 'package:flutter/material.dart';
import '../services/class_service.dart';
import '../services/student_service.dart';

class UnassignedStudentsScreen extends StatefulWidget {
  const UnassignedStudentsScreen({Key? key}) : super(key: key);

  @override
  _UnassignedStudentsScreenState createState() => _UnassignedStudentsScreenState();
}

class _UnassignedStudentsScreenState extends State<UnassignedStudentsScreen> {
  final _studentService = StudentService();
  final _classService = ClassService();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final students = await _studentService.fetchUnassignedStudents();
    final classes = await _classService.fetchClasses();
    setState(() {
      _students = students;
      _filteredStudents = students;
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
      _filteredStudents = filteredStudents;
    });
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
              onPressed: () async {
                await _studentService.assignStudentToClass(studentId, classId);
                await _fetchData();
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
      appBar: AppBar(title: const Text('Unassigned Students')),
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
            child: ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return ListTile(
                  title: Text(student['name']),
                  subtitle: Text('DOB: ${student['dob']}'),
                  trailing: DropdownButton<String>(
                    hint: const Text('Assign to Class'),
                    items: _classes.map((classData) {
                      return DropdownMenuItem<String>(
                        value: classData['id'],
                        child: Text(classData['name']),
                      );
                    }).toList(),
                    onChanged: (classId) {
                      if (classId != null) {
                        final className = _classes.firstWhere((c) => c['id'] == classId)['name'];
                        _confirmAndAssignStudent(student['id'], classId, className);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}