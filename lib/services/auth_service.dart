import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'hive_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Signup
  Future<User?> signUp(String email, String password, String name, String phoneNumber, {String? profileImage}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Update Firebase Profile with Name
      await userCredential.user?.updateDisplayName(name);
      
      // Mirror to MongoDB (Including Name, Phone & Profile Image)
      await ApiService().syncUser(userCredential.user!.uid, email, password, name: name, phoneNumber: phoneNumber, profileImage: profileImage);
      return userCredential.user;
    } catch (e) {
      debugPrint('SignUp Error: $e');
      rethrow;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Mirror to MongoDB (Sync current creds, Name stays same in DB)
      await ApiService().syncUser(userCredential.user!.uid, email, password, name: userCredential.user?.displayName);
      return userCredential.user;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await HiveService.clearAll();
    await _auth.signOut();
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await signOut(); // Ensure stream sees NULL immediately
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      rethrow;
    }
  }

  // Re-authenticate and then Delete
  Future<void> reauthenticateAndDelete(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await deleteAccount();
      }
    } catch (e) {
      debugPrint('Re-auth Delete Error: $e');
      rethrow;
    }
  }
}
