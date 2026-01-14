import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_seeder.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      if (name != null && name.isNotEmpty) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.reload(); // Ensure local user object is updated
      }

      // Seed matches for the new user automatically
      try {
        await DbSeeder.seedMatchesForUser(credential.user!.uid);
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    if (credential.user != null) {
      // Seed matches for the new guest user automatically
      try {
        await DbSeeder.seedMatchesForUser(credential.user!.uid);
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
