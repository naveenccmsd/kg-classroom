import 'firebase_service.dart';
import 'student_service.dart';
import 'teacher_service.dart';

class RoleService extends FirebaseService {

  Future<void> addRole(String email, String role) async {
    final docRef = firestore.collection('roles').doc(email);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      final roles = List<String>.from(data?['roles'] ?? []);
      if (!roles.contains(role)) {
        roles.add(role);
        await docRef.update({'roles': roles});
      }
    } else {
      await docRef.set({'roles': [role]});
    }
  }

  Future<void> updateRole(String email, String oldRole, String newRole) async {
    final docRef = firestore.collection('roles').doc(email);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      final roles = List<String>.from(data?['roles'] ?? []);
      if (roles.contains(oldRole)) {
        roles.remove(oldRole);
        if (!roles.contains(newRole)) {
          roles.add(newRole);
        }
        await docRef.update({'roles': roles});
      }
    }
  }

  Future<void> removeRole(String email, String role) async {
    final docRef = firestore.collection('roles').doc(email);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      final roles = List<String>.from(data?['roles'] ?? []);
      if (roles.contains(role)) {
        roles.remove(role);
        if (roles.isEmpty) {
          await docRef.delete();
        } else {
          await docRef.update({'roles': roles});
        }
      }
    }
  }
}