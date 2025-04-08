import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/services/role_service.dart';

import 'StudentDashboard.dart';
import 'TeacherDashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  final RoleService _roleService = RoleService();

  RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final studentName = user?.email ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: FutureBuilder<bool>(
        future: _roleService.isTeacher(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final isTeacher = snapshot.data ?? false;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isTeacher)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const TeacherDashboard(),
                    ));
                  },
                  child: const Text('I am a Teacher'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => StudentDashboard(studentName: studentName),
                  ));
                },
                child: const Text('I am a Student'),
              ),
            ],
          );
        },
      ),
    );
  }
}