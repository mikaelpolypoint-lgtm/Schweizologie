import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/city.dart';
import '../models/high_score.dart';
import '../services/firebase_service.dart';
import '../import_cities.dart';

enum GameState { loading, playing, gameOver, error }

enum Direction {
  north,
  east,
  south,
  west,
}

class GameProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<City> _allCities = [];
  City? _cityA;
  City? _cityB;
  int _score = 0;
  GameState _gameState = GameState.loading;
  List<HighScore> _highScores = [];

  City? get cityA => _cityA;
  City? get cityB => _cityB;
  int get score => _score;
  GameState get gameState => _gameState;
  List<HighScore> get highScores => _highScores;

  final Random _random = Random();

  Future<void> initGame() async {
    print("${DateTime.now()} initGame called");
    _gameState = GameState.loading;
    notifyListeners();

    try {
      print("${DateTime.now()} Calling loadCitiesFromAssets...");
      _allCities = await loadCitiesFromAssets();
      print("${DateTime.now()} loadCitiesFromAssets returned ${_allCities.length} cities");
      
      if (_allCities.length < 2) {
         print("${DateTime.now()} Error: Too few cities");
         _gameState = GameState.error;
         notifyListeners();
         return;
      }
    } catch (e) {
      print("${DateTime.now()} Error loading cities: $e");
      _gameState = GameState.error;
      notifyListeners();
      return;
    }

    print("${DateTime.now()} Starting new game...");
    _startNewGame();
    print("${DateTime.now()} Game started, state is playing");
  }

  void _startNewGame() {
    _score = 0;
    _cityA = _getRandomCity();
    _cityB = _getRandomCity(exclude: _cityA);
    _gameState = GameState.playing;
    notifyListeners();
  }

  City _getRandomCity({City? exclude}) {
    City city;
    do {
      city = _allCities[_random.nextInt(_allCities.length)];
    } while (city == exclude);
    return city;
  }

  Future<bool> makeGuess(Direction direction) async {
    if (_cityA == null || _cityB == null) return false;

    // Determine valid directions based on relative position
    // We accept ANY direction that is factually true.
    // e.g. If City B is North-East of City A, both North and East are correct.
    
    bool isCorrect = false;
    
    switch (direction) {
      case Direction.north:
        isCorrect = _cityB!.latitude > _cityA!.latitude;
        break;
      case Direction.south:
        isCorrect = _cityB!.latitude < _cityA!.latitude;
        break;
      case Direction.east:
        isCorrect = _cityB!.longitude > _cityA!.longitude;
        break;
      case Direction.west:
        isCorrect = _cityB!.longitude < _cityA!.longitude;
        break;
    }
    
    print("Guess: $direction, Correct? $isCorrect (A: ${_cityA!.name}, B: ${_cityB!.name})");

    if (isCorrect) {
      _score++;
      notifyListeners();
      return true;
    } else {
      try {
        await _endGame();
      } catch (e) {
        print("Error in _endGame: $e");
        // Even if saving score fails, we should return false to show the popup
      }
      return false;
    }
  }

  void nextRound() {
    _cityA = _cityB; // City B becomes City A
    _cityB = _getRandomCity(exclude: _cityA);
    notifyListeners();
  }

  // The old List<int> _highScores = []; definition was removed from the top.
  // This is the correct definition for List<HighScore>.
  // List<HighScore> _highScores = []; // This line is now redundant as it's defined at the top.
  // List<HighScore> get highScores => _highScores; // This getter is now redundant as it's defined at the top.

  Future<void> _endGame() async {
    // We don't set GameState.gameOver anymore, because we want to show a popup on the GameScreen.
    try {
      await _firebaseService.saveScore(_score).timeout(const Duration(seconds: 2));
      _highScores = await _firebaseService.getTopHighScores().timeout(const Duration(seconds: 2));
    } catch (e) {
      print("Error saving score or fetching high scores: $e");
      // Fallback: just keep local high scores or empty list
    }
    notifyListeners();
  }

  int getRank() {
    // Rank calculation based on global high scores
    if (_highScores.isEmpty) return 1;
    
    // Find where our score fits in the sorted list
    // _highScores is already sorted descending by Firestore
    
    for (int i = 0; i < _highScores.length; i++) {
      if (_score >= _highScores[i].score) {
        // If our score is equal to a high score, we share that rank.
        // But wait, we just saved our score to the DB. So our score SHOULD be in this list if it's top 100.
        // If we found our own entry (same ID), that's our rank.
        // But we don't have the ID of the score we just saved easily available without returning it from saveScore.
        // However, simply finding the first index where score >= highscore[i].score is a decent approximation for "rank".
        // Actually, since we saved it, it IS in the list (if top 100).
        return i + 1;
      }
    }
    return _highScores.length + 1; // Not in top 100
  }

  void restartGame() {
    _startNewGame();
  }
}
