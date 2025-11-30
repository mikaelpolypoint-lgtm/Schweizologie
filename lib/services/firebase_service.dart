import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/city.dart';
import '../models/high_score.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> signOut() async {
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
  // Firestore - Scores
  Future<void> saveScore(String userName, int score) async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      try {
        print("User not signed in. Attempting anonymous sign-in...");
        final userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        print("Anonymous sign-in successful: ${user?.uid}");
      } catch (e) {
        print("Anonymous sign-in failed: $e");
        // Continue anyway, maybe rules allow unauthenticated writes
      }
    }

    try {
      // Save to global highscores collection
      await _firestore.collection('highscores').add({
        'userId': user?.uid ?? 'anonymous',
        'userName': userName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving score: $e');
      rethrow; // Propagate error to trigger timeout handling in provider
    }
  }

  Future<List<HighScore>> getTopHighScores() async {
    try {
      final snapshot = await _firestore
          .collection('highscores')
          .orderBy('score', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => HighScore.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching high scores: $e');
      return [];
    }
  }
}
