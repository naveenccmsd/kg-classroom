import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

class RoleService extends FirebaseService {

  Future<List<String>> getRoles(String email) async {
    final docRef = firestore.collection('roles').doc(email);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      return List<String>.from(data?['roles'] ?? []);
    }
    return [];
  }

  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    final email = user.email;
    if (email == null) {
      throw Exception('Signed-in user does not have an email.');
    }
    final roles = await getRoles(email);
    return roles.contains('admin');
  }

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