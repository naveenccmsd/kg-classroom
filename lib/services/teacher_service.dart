import 'firebase_service.dart';

class TeacherService extends FirebaseService {
  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final query = await firestore.collection('teachers').get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'email': data['email'] ?? 'No Email',
      };
    }).toList();
  }
  Future<void> deleteTeacher(String teacherId) async {
    await firestore.collection('teachers').doc(teacherId).delete();
  }

  Future<void> saveTeacher(String? previousEmail, Map<String, dynamic> teacherData) async {
    final email = teacherData['email'];

    // Remove the previous email document if the email has changed
    if (previousEmail != null && previousEmail != email) {
      await firestore.collection('teachers').doc(previousEmail).delete();
    }

    await firestore.collection('teachers').doc(email).set(teacherData);
  }


  Future<bool> isEmailInUse(String email, String? previousEmail) async {
    final existingTeacher = await firestore.collection('teachers').doc(email).get();
    final existingStudent = await firestore.collection('students').doc(email).get();

    return (existingTeacher.exists && existingTeacher.id != previousEmail) || existingStudent.exists;
  }
}