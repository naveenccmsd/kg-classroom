
import 'package:flutter/material.dart';

import 'StudentDashboard.dart';
import 'TeacherDashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                builder: (context) => const StudentDashboard(),
              ));
            },
            child: const Text('I am a Student'),
          ),
        ],
      ),
    );
  }
}