import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocabflashcard_app/services/firestore_service.dart'; // Import FirestoreService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService(); // Define and initialize FirestoreService

  // Future<UserCredential?> signInWithEmail(String email, String password) async {
  //   try {
  //     return await _auth.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     print('FirebaseAuthException during email sign-in: ${e.message}');
  //     return null;
  //   } catch (e) {
  //     print('Unknown error during email sign-in: $e');
  //     return null;
  //   }
  // }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Update login streak after successful sign-in
        await _firestoreService.updateLoginStreak();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during email sign-in: ${e.message}');
      return null;
    } catch (e) {
      print('Unknown error during email sign-in: $e');
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during email sign-up: ${e.message}');
      return null;
    } catch (e) {
      print('Unknown error during email sign-up: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-in was canceled by the user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Update login streak after successful sign-in
        await _firestoreService.updateLoginStreak();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google sign-in: ${e.message}');
      return null;
    } catch (e) {
      print('Unknown error during Google sign-in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }
}