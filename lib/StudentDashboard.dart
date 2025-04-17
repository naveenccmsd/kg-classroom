import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'HomeworkViewer.dart';

class StudentDashboard extends StatefulWidget {
  final String studentEmail;

  const StudentDashboard({required this.studentEmail, Key? key}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<Map<String, dynamic>>> _assignedHomework;

  @override
  void initState() {
    super.initState();
    _assignedHomework = _fetchAssignedHomework();
  }

  Future<List<Map<String, dynamic>>> _fetchAssignedHomework() async {
    debugPrint('Fetching assigned homework for student: ${widget.studentEmail}');

    try {
      final assignedHomeworkSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentEmail)
          .collection('assignedHomeworks')
          .get();

      debugPrint('Assigned homework snapshot retrieved: ${assignedHomeworkSnapshot.docs.length} documents found.');

      return assignedHomeworkSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching assigned homework: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assignedHomework,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final homeworkList = snapshot.data ?? [];
          if (homeworkList.isEmpty) {
            return const Center(child: Text('No assigned homework.'));
          }

          return ListView.builder(
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final homework = homeworkList[index];
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(homework['title'] ?? 'Untitled'),
                subtitle: Text(homework['description'] ?? 'No description'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkViewer(
                        homeworkId: homework['id'],
                        studentEmail: widget.studentEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}