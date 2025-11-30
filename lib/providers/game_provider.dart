import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/city.dart';
import '../models/high_score.dart';
import '../services/firebase_service.dart';
import '../import_cities.dart';

enum GameState { loading, playing, gameOver, error }

enum Direction {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

class GameProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<City> _allCities = [];
  City? _cityA;
  City? _cityB;
  int _score = 0;
  GameState _gameState = GameState.loading;
  List<HighScore> _highScores = [];
  
  // History tracking
  final List<City> _visitedCities = [];
  
  // Wrong guess details
  double? _lastBearing;
  Direction? _lastGuessedDirection;
  Direction? _correctDirection;

  City? get cityA => _cityA;
  City? get cityB => _cityB;
  int get score => _score;
  GameState get gameState => _gameState;
  List<HighScore> get highScores => _highScores;
  List<City> get visitedCities => _visitedCities;
  
  double? get lastBearing => _lastBearing;
  Direction? get lastGuessedDirection => _lastGuessedDirection;
  Direction? get correctDirection => _correctDirection;

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
    _visitedCities.clear();
    _cityA = _getRandomCity();
    _visitedCities.add(_cityA!); // Add start city
    _cityB = _getRandomCity(exclude: _cityA);
    _gameState = GameState.playing;
    notifyListeners();
  }

  // ... (keep existing methods)

  void nextRound() {
    print("nextRound called. Old A: ${_cityA?.name}, Old B: ${_cityB?.name}");
    _cityA = _cityB; // City B becomes City A
    _visitedCities.add(_cityA!); // Add new city to history
    _cityB = _getRandomCity(exclude: _cityA);
    print("New A: ${_cityA?.name}, New B: ${_cityB?.name}");
    notifyListeners();
  }

  City _getRandomCity({City? exclude}) {
    City city;
    do {
      city = _allCities[_random.nextInt(_allCities.length)];
    } while (city == exclude);
    return city;
  }

  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    var startLatRad = startLat * (pi / 180.0);
    var startLngRad = startLng * (pi / 180.0);
    var endLatRad = endLat * (pi / 180.0);
    var endLngRad = endLng * (pi / 180.0);

    var dLng = endLngRad - startLngRad;

    var y = sin(dLng) * cos(endLatRad);
    var x = cos(startLatRad) * sin(endLatRad) -
        sin(startLatRad) * cos(endLatRad) * cos(dLng);

    var bearingRad = atan2(y, x);
    var bearingDegrees = bearingRad * (180.0 / pi);

    return (bearingDegrees + 360) % 360;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p)/2 +
          cos(lat1 * p) * cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  int get currentDistance {
    if (_cityA == null || _cityB == null) return 0;
    return _calculateDistance(
      _cityA!.latitude, _cityA!.longitude,
      _cityB!.latitude, _cityB!.longitude
    ).round();
  }

  Direction _getDirectionFromBearing(double bearing) {
    // Quadrant 1: North-East (0 to 90)
    if (bearing >= 0 && bearing < 90) return Direction.northEast;
    // Quadrant 2: South-East (90 to 180)
    if (bearing >= 90 && bearing < 180) return Direction.southEast;
    // Quadrant 3: South-West (180 to 270)
    if (bearing >= 180 && bearing < 270) return Direction.southWest;
    // Quadrant 4: North-West (270 to 360)
    return Direction.northWest;
  }

  Future<bool> makeGuess(Direction guess) async {
    if (_cityA == null || _cityB == null) return false;

    double bearing = _calculateBearing(_cityA!.latitude, _cityA!.longitude,
        _cityB!.latitude, _cityB!.longitude);

    // Normalize bearing to 0-360
    if (bearing < 0) bearing += 360;

    bool isCorrect = false;
    int pointsAwarded = 0;
    
    // Determine the "True" direction (always an Intercardinal in this mode)
    Direction trueDirection = _getDirectionFromBearing(bearing);
    
    // Determine valid guesses based on the True direction (Quadrant Logic)
    final Set<Direction> validGuesses = {trueDirection};
    
    if (trueDirection == Direction.northEast) {
      validGuesses.add(Direction.north);
      validGuesses.add(Direction.east);
    } else if (trueDirection == Direction.southEast) {
      validGuesses.add(Direction.south);
      validGuesses.add(Direction.east);
    } else if (trueDirection == Direction.southWest) {
      validGuesses.add(Direction.south);
      validGuesses.add(Direction.west);
    } else if (trueDirection == Direction.northWest) {
      validGuesses.add(Direction.north);
      validGuesses.add(Direction.west);
    }

    // Check if the user's guess is valid
    if (validGuesses.contains(guess)) {
      isCorrect = true;
      // Award points based on the TYPE of direction guessed (Risk/Reward)
      if (guess == Direction.north || guess == Direction.east || guess == Direction.south || guess == Direction.west) {
        pointsAwarded = 1;
      } else {
        pointsAwarded = 3;
      }
    } else {
      isCorrect = false;
    }
    
    print("Guess: $guess, True: $trueDirection");
    print("Valid Answers: ${validGuesses.map((d) => d.toString().split('.').last).join(', ')}");
    print("Result: $isCorrect (A: ${_cityA!.name}, B: ${_cityB!.name})");

    if (isCorrect) {
      _score += pointsAwarded;
    } else {
      // Store details for Game Over screen
      _lastBearing = bearing;
      _lastGuessedDirection = guess;
      _correctDirection = trueDirection;
      
      try {
        await _endGame();
      } catch (e) {
        print("Error ending game: $e");
      }
    }
    
    notifyListeners();
    return isCorrect;
  }



  // The old List<int> _highScores = []; definition was removed from the top.
  // This is the correct definition for List<HighScore>.
  // List<HighScore> _highScores = []; // This line is now redundant as it's defined at the top.
  // List<HighScore> get highScores => _highScores; // This getter is now redundant as it's defined at the top.

  Future<void> _endGame() async {
    try {
      // Fetch high scores to see if user qualifies
      _highScores = await _firebaseService.getTopHighScores().timeout(const Duration(seconds: 10));
    } catch (e) {
      print("Error fetching high scores: $e");
    }
    notifyListeners();
  }

  bool isHighScore(int score) {
    if (_highScores.length < 20) return true;
    return score > _highScores.last.score;
  }

  Future<void> submitHighScore(String name) async {
    try {
      await _firebaseService.saveScore(name, _score).timeout(const Duration(seconds: 15));
      // Refresh high scores
      _highScores = await _firebaseService.getTopHighScores().timeout(const Duration(seconds: 15));
    } catch (e) {
      print("Error submitting high score: $e");
      rethrow; // Let the UI know it failed
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
