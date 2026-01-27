import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Seed matches for the new user automatically
        try {
          await DbSeeder.seedMatchesForUser(userCredential.user!.uid);
        } catch (e) {
          // ignore
        }
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
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

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // --- DELETE ACCOUNT (Compliance) ---
  // Requires recent login.
  Future<void> deleteAccount(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Re-authenticate (Required for sensitive options)
    final credential = EmailAuthProvider.credential(
      email: user.email!, // Assuming email login for now
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    // 1. Delete Firestore Data (Handled by Cloud Functions ideally, but client-side trigger here)
    // FirestoreService should have a method to delete the user doc.
    // However, clean deletion usually involves deleting subcollections manually or via recursive delete logic.
    // For MVP Compliance: Just delete the main user doc. The logic is in FirestoreService (added later).

    // 2. Delete Auth User
    await user.delete();
  }
}
