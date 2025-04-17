import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'HomeworkDetails.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<List<Map<String, dynamic>>> _homeworkList;

  @override
  void initState() {
    super.initState();
    _homeworkList = _fetchHomeworkList();
  }

  Future<List<Map<String, dynamic>>> _fetchHomeworkList() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('homeworks')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }
  Future<void> _assignHomework(Map<String, dynamic> homework) async {
    String? selectedClass;
    List<Map<String, String>> classList = []; // List of class ID and name
    Map<String, List<String>> studentMap = {};

    try {
      // Fetch classes and students
      final classesSnapshot = await FirebaseFirestore.instance.collection('classes').get();
      for (var doc in classesSnapshot.docs) {
        classList.add({'id': doc.id, 'name': doc['name']}); // Store class ID and name
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: doc.id)
            .get();
        studentMap[doc.id] = studentsSnapshot.docs.map((e) => e.id).toList();
      }

      // Show dialog for class selection
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Homework'),
                content: DropdownButton<String>(
                  value: selectedClass,
                  hint: const Text('Select Class'),
                  isExpanded: true,
                  items: classList.map((classData) {
                    return DropdownMenuItem(
                      value: classData['id'], // Use class ID as value
                      child: Text(classData['name']!), // Display class name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );

      // Assign homework to all students in the selected class
      if (selectedClass != null) {
        final students = studentMap[selectedClass] ?? [];
        for (var studentId in students) {
          await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .collection('assignedHomeworks')
              .doc(homework['id'])
              .set({
            'title': homework['title'],
            'description': homework['description'],
            'images': homework['images'],
            'assignedAt': FieldValue.serverTimestamp(),
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework assigned successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error assigning homework: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign homework.')),
      );
    }
  }

  void _createOrEditHomework({Map<String, dynamic>? homework}) {
    // Implement homework creation or editing logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _homeworkList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No homework found.'),
            );
          }

          final homeworkList = snapshot.data!;
          return ListView.builder(
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final hw = homeworkList[index];
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(hw['title']),
                subtitle: Text(hw['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _createOrEditHomework(homework: hw),
                    ),
                    IconButton(
                      icon: const Icon(Icons.assignment),
                      onPressed: () => _assignHomework(hw),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkDetails(homework: hw),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEditHomework(),
        child: const Icon(Icons.add),
      ),
    );
  }
}