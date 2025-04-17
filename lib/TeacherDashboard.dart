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
    final titleController = TextEditingController(text: homework?['title'] ?? '');
    final descriptionController = TextEditingController(text: homework?['description'] ?? '');
    final imagesController = TextEditingController(text: (homework?['images'] ?? []).join(', '));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(homework == null ? 'Create Homework' : 'Edit Homework'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: imagesController,
                  decoration: const InputDecoration(labelText: 'Images (comma-separated URLs)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                final images = imagesController.text.split(',').map((e) => e.trim()).toList();

                if (title.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and description are required.')),
                  );
                  return;
                }

                try {
                  if (homework == null) {
                    // Create new homework with title as document ID
                    await FirebaseFirestore.instance
                        .collection('homeworks')
                        .doc(title) // Use title as document ID
                        .set({
                      'title': title,
                      'description': description,
                      'images': images,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // Update existing homework
                    await FirebaseFirestore.instance
                        .collection('homeworks')
                        .doc(homework['id'])
                        .update({
                      'description': description,
                      'images': images,
                    });
                  }

                  setState(() {
                    _homeworkList = _fetchHomeworkList();
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(homework == null ? 'Homework created!' : 'Homework updated!')),
                  );
                } catch (e) {
                  debugPrint('Error saving homework: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save homework.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete Homework'),
                              content: const Text('Are you sure you want to delete this homework?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('homeworks')
                                .doc(hw['id'])
                                .delete();

                            setState(() {
                              _homeworkList = _fetchHomeworkList();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Homework deleted successfully!')),
                            );
                          } catch (e) {
                            debugPrint('Error deleting homework: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to delete homework.')),
                            );
                          }
                        }
                      },
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