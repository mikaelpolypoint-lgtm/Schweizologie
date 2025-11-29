import 'package:cloud_firestore/cloud_firestore.dart';

class HighScore {
  final String id;
  final String userId;
  final String userName;
  final int score;
  final DateTime timestamp;

  HighScore({
    required this.id,
    required this.userId,
    required this.userName,
    required this.score,
    required this.timestamp,
  });

  factory HighScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HighScore(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      score: data['score'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
