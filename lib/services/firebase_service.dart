import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/city.dart';
import '../models/high_score.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // GoogleSignIn is only needed for Mobile. On Web we use FirebaseAuth directly.
  // We avoid initializing it globally to prevent "ClientID not set" errors on Web.

  // Auth
  Future<void> handleRedirectResult() async {
    if (kIsWeb) {
      try {
        print("Checking for redirect result...");
        final result = await _auth.getRedirectResult();
        if (result.user != null) {
          print("Redirect Sign-In Successful! User: ${result.user?.email}");
        } else {
          print("No redirect result found (user is null).");
        }
      } catch (e) {
        print("Error getting redirect result: $e");
      }
    }
  }

  Future<User?> signInWithGoogle() async {
    print("Attempting Google Sign-In...");
    try {
      // Web-specific flow
      if (kIsWeb) {
        print("Detected Web Platform. Using signInWithPopup.");
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        print("Popup Sign-In Successful! User: ${userCredential.user?.email}");
        return userCredential.user; 
      } else {
        print("Detected Mobile Platform.");
        // Mobile flow
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          print("Google Sign-In aborted by user.");
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore - Cities
  Future<List<City>> fetchAllCities() async {
    try {
      final snapshot = await _firestore.collection('cities').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add ID to data if not present or handle it in model
        data['id'] = doc.id; 
        return City.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  // Firestore - Scores
  Future<void> saveScore(int score) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Save to global highscores collection
      await _firestore.collection('highscores').add({
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Anonymous',
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // We could also keep a user-specific history if needed, but the requirement focuses on "the highscore list".
    } catch (e) {
      print('Error saving score: $e');
    }
  }

  Future<List<HighScore>> getTopHighScores() async {
    try {
      final snapshot = await _firestore
          .collection('highscores')
          .orderBy('score', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) => HighScore.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching high scores: $e');
      return [];
    }
  }
}
