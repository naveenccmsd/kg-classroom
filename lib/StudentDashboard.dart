import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'DrawCanvasPage.dart';

class StudentDashboard extends StatelessWidget {
  final String studentName;

  const StudentDashboard({required this.studentName, Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchHomework() async {
    final query = await FirebaseFirestore.instance
        .collection('homeworks')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHomework(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final homeworkList = snapshot.data ?? [];
          return ListView.builder(
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final hw = homeworkList[index];
              final imageUrl = hw['imageUrl'] ?? 'No Image Available'; // Default value

              if (imageUrl == 'No Image Available') {
                return const SizedBox.shrink(); // Skip invalid entries
              }

              return ListTile(
                leading: const Icon(Icons.image),
                title: Text(imageUrl),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => DrawCanvasPage(
                      imageUrl: imageUrl,
                      isTeacher: false,
                      studentName: studentName,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}