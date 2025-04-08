import 'firebase_service.dart';

class StudentService extends FirebaseService {
  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final query = await firestore.collection('classes').get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> fetchStudentData(String studentId) async {
    final doc = await firestore.collection('students').doc(studentId).get();
    return doc.data();
  }

  Future<void> saveStudent(String? previousEmail, Map<String, dynamic> studentData) async {
    final email = studentData['email'];

    // Remove the previous email document if the email has changed
    if (previousEmail != null && previousEmail != email) {
      await firestore.collection('students').doc(previousEmail).delete();
    }

    await firestore.collection('students').doc(email).set(studentData);
  }

  Future<bool> isEmailInUse(String email, String? previousEmail) async {
    final existingStudent = await firestore.collection('students').doc(email).get();
    final existingTeacher = await firestore.collection('teachers').doc(email).get();

    return (existingStudent.exists && existingStudent.id != previousEmail) || existingTeacher.exists;
  }
}