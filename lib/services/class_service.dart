import 'firebase_service.dart';

class ClassService extends FirebaseService{


  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final query = await firestore.collection('classes').get();
    return query.docs.asMap().entries.map((entry) {
      final doc = entry.value;
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'No Name',
        'order': data['order'] ?? entry.key,
      };
    }).toList();
  }

  Future<void> updateClassOrder(List<Map<String, dynamic>> classes) async {
    for (int i = 0; i < classes.length; i++) {
      await firestore.collection('classes').doc(classes[i]['id']).update({'order': i});
    }
  }

  Future<String?> fetchClassName(String classId) async {
    final doc = await firestore.collection('classes').doc(classId).get();
    return doc.data()?['name'];
  }

  Future<void> deleteClass(String classId) async {
    await firestore.collection('classes').doc(classId).delete();
  }

}