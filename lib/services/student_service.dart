import 'firebase_service.dart';

class StudentService extends FirebaseService {


  Future<List<Map<String, dynamic>>> fetchUnassignedStudents() async {
    final query = await firestore.collection('students').get();
    return query.docs.where((doc) {
      final data = doc.data();
      return !data.containsKey('classId') || data['classId'] == null || data['classId'].isEmpty;
    }).map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchClassStudents(String classId) async {
    final query = await firestore.collection('students').where('classId', isEqualTo: classId).get();
    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'dob': data['dob'] ?? 'No DOB',
      };
    }).toList();
  }

  Future<void> assignStudentToClass(String studentId, String classId) async {
    await firestore.collection('students').doc(studentId).update({'classId': classId});
  }
  Future<void> deleteStudent(String studentId) async {
    await firestore.collection('students').doc(studentId).delete();
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

  Future<void> unassignStudentsFromClass(String classId) async {
    final studentQuery = await firestore.collection('students').where('classId', isEqualTo: classId).get();
    for (final doc in studentQuery.docs) {
      await firestore.collection('students').doc(doc.id).update({'classId': null});
    }
  }
}