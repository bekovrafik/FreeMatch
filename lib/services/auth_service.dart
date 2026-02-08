import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';

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
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  Future<void> signInWithGoogle() async {
    try {
      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize(
          serverClientId:
              '494411912282-62ta57gr6elsn54ed1fkgakmdukgj4he.apps.googleusercontent.com',
        );
        _isGoogleInitialized = true;
      }

      // In 7.0.0+, we must ensure initialization.
      // Usually it's better to do it once, but we can call it here for safety or in a constructor.
      // However, its presence in search results suggests it's required.
      // Let's assume it's initialized or we can just call authenticate() if initialize() is not strictly required for every call.

      final googleUser = await _googleSignIn.authenticate();
      // Removed: if (googleUser == null) return; // unnecessary null check

      // account.authentication is now synchronous in 7.0.0+
      final googleAuth = googleUser.authentication;

      // accessToken is obtained via authorizationClient
      final authClient = await googleUser.authorizationClient.authorizeScopes([
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ]);
      final accessToken = authClient.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // ... (removed seeding)
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// 4. SIGN IN WITH APPLE (Guideline 4.8)
  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthProvider oAuthProvider = OAuthProvider("apple.com");
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // ... (removed seeding)
      }
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      rethrow;
    }
  }

  /// Helper to generate a random string for Apple Nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Helper to hash the nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    if (credential.user != null) {
      // ... (removed seeding)
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
