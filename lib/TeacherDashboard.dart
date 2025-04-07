import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'HomeworkForm.dart';
import 'AssignHomework.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Future<List<Map<String, dynamic>>> _fetchHomeworks() async {
    final query = await FirebaseFirestore.instance
        .collection('homeworks')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? 'No Title',
        'description': data['description'] ?? 'No Description',
      };
    }).toList();
  }

  late Future<List<Map<String, dynamic>>> _homeworkList;

  @override
  void initState() {
    super.initState();
    _homeworkList = _fetchHomeworks();
  }

  void _refreshHomeworks() {
    setState(() {
      _homeworkList = _fetchHomeworks();
    });
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
          }
          final homeworkList = snapshot.data ?? [];
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
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(
                          builder: (context) => HomeworkForm(homework: hw),
                        ));
                        if (result == true) {
                          _refreshHomeworks();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.assignment),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => AssignHomework(homework: hw),
                        ));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => const HomeworkForm(),
          ));
          if (result == true) {
            _refreshHomeworks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}