import 'package:flutter/material.dart';
import 'package:kg_classroom/services/class_service.dart';
import '../services/student_service.dart';
import 'StudentForm.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String classId;

  const ClassStudentsScreen({Key? key, required this.classId}) : super(key: key);

  @override
  _ClassStudentsScreenState createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final _studentService = StudentService();
  final _classService = ClassService();
  String? _className;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final className = await _classService.fetchClassName(widget.classId);
    final students = await _studentService.fetchClassStudents(widget.classId);
    setState(() {
      _className = className ?? 'Class Students';
      _students = students;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_className ?? 'Class Students')),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
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
                      await _fetchData();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _studentService.deleteStudent(student['id']);
                    await _fetchData();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => StudentForm(classId: widget.classId),
          ));
          if (result == true) {
            await _fetchData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}