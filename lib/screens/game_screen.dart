import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/city.dart';
import '../models/high_score.dart';
import '../services/firebase_service.dart';
import '../import_cities.dart';
import '../widgets/contour_map_background.dart';
import '../widgets/city_sign.dart';
import '../widgets/swiss_map_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).initGame();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContourMapBackground(
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Consumer<GameProvider>(
            builder: (context, game, child) {
              if (game.gameState == GameState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (game.gameState == GameState.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        "Not enough cities found!",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Uploading cities... Please wait.")),
                            );
                            await importCitiesFromAssets();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Upload complete! Reloading...")),
                            );
                            if (context.mounted) {
                              Provider.of<GameProvider>(context, listen: false).initGame();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Upload Cities to Firestore"),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<GameProvider>(context, listen: false).initGame();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: Column(
                  children: [

                    _buildHeader(game.score),
                    Expanded(
                      child: KeyboardListener(
                        focusNode: _focusNode,
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              _handleGuess(context, game, Direction.north);
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              _handleGuess(context, game, Direction.south);
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                              _handleGuess(context, game, Direction.west);
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                              _handleGuess(context, game, Direction.east);
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            // Compass Rose Background (Center)
                            Center(
                              child: Opacity(
                                opacity: 0.1,
                                child: Icon(
                                  Icons.explore,
                                  size: 300,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            // Drop Zones
                            // North (Top Center)
                            Positioned(
                              top: 0, left: MediaQuery.of(context).size.width * 0.35, right: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.25,
                              child: _buildDropZoneArea(context, game, Direction.north, "N"),
                            ),
                            // South (Bottom Center)
                            Positioned(
                              bottom: 0, left: MediaQuery.of(context).size.width * 0.35, right: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.25,
                              child: _buildDropZoneArea(context, game, Direction.south, "S"),
                            ),
                            // West (Left Center)
                            Positioned(
                              top: MediaQuery.of(context).size.height * 0.35, bottom: MediaQuery.of(context).size.height * 0.35, left: 0, width: MediaQuery.of(context).size.width * 0.25,
                              child: _buildDropZoneArea(context, game, Direction.west, "W"),
                            ),
                            // East (Right Center)
                            Positioned(
                              top: MediaQuery.of(context).size.height * 0.35, bottom: MediaQuery.of(context).size.height * 0.35, right: 0, width: MediaQuery.of(context).size.width * 0.25,
                              child: _buildDropZoneArea(context, game, Direction.east, "E"),
                            ),
                            
                            // North-West (Top Left)
                            Positioned(
                              top: 0, left: 0, width: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.35,
                              child: _buildDropZoneArea(context, game, Direction.northWest, "NW"),
                            ),
                            // North-East (Top Right)
                            Positioned(
                              top: 0, right: 0, width: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.35,
                              child: _buildDropZoneArea(context, game, Direction.northEast, "NE"),
                            ),
                            // South-West (Bottom Left)
                            Positioned(
                              bottom: 0, left: 0, width: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.35,
                              child: _buildDropZoneArea(context, game, Direction.southWest, "SW"),
                            ),
                            // South-East (Bottom Right)
                            Positioned(
                              bottom: 0, right: 0, width: MediaQuery.of(context).size.width * 0.35, height: MediaQuery.of(context).size.height * 0.35,
                              child: _buildDropZoneArea(context, game, Direction.southEast, "SE"),
                            ),

                            // Center: City A
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CitySign(
                                    city: game.cityA!,
                                    label: "Start",
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.black26),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.straighten, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${game.currentDistance} km",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Draggable: City B
                            Positioned(
                              top: 40,
                              left: 20,
                              child: Draggable<bool>(
                                data: true,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: CitySign(
                                    city: game.cityB!,
                                    label: "Destination",
                                    isDragging: true,
                                  ),
                                ),
                                childWhenDragging: Container(), 
                                child: CitySign(
                                  city: game.cityB!,
                                  label: "Destination",
                                ),
                              ),
                            ),
                            
                            // Instruction Text
                            const Positioned(
                              bottom: 40,
                              left: 0,
                              right: 0,
                              child: Text(
                                "Drag the yellow sign to the correct direction",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }



  Widget _buildHeader(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Color(0xFFD52B1E)),
              const SizedBox(width: 8),
              Text(
                'SCHWEIZOLOGIE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // High Scores Button
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD52B1E), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)],
                ),
                child: IconButton(
                  icon: const Icon(Icons.emoji_events, color: Color(0xFFD52B1E)),
                  tooltip: 'High Scores',
                  onPressed: () => _showHighScoresDialog(context),
                ),
              ),
              // Score Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD52B1E),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                ),
                child: Text(
                  'SCORE: $score',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHighScoresDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF0EAD6),
          title: const Text(
            "TOP 20 HIGH SCORES",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD52B1E)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: FutureBuilder<List<HighScore>>(
              future: Provider.of<FirebaseService>(context, listen: false).getTopHighScores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD52B1E)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final scores = snapshot.data ?? [];
                if (scores.isEmpty) {
                  return const Center(child: Text("No high scores yet!"));
                }
                return ListView.separated(
                  itemCount: scores.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.black12),
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    // Format date: DD.MM.YYYY
                    final date = score.timestamp != null 
                        ? "${score.timestamp!.day.toString().padLeft(2, '0')}.${score.timestamp!.month.toString().padLeft(2, '0')}.${score.timestamp!.year}" 
                        : "-";
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3 ? const Color(0xFFFFD100) : Colors.white,
                        foregroundColor: Colors.black,
                        child: Text("#${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        score.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(date),
                      trailing: Text(
                        "${score.score}",
                        style: const TextStyle(
                          color: Color(0xFFD52B1E),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD52B1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("CLOSE"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropZoneArea(BuildContext context, GameProvider game, Direction direction, String label) {
    return DragTarget<bool>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        _handleGuess(context, game, direction);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFFD52B1E).withOpacity(0.1) : Colors.transparent,
          ),
          child: Center(
            child: AnimatedScale(
              scale: isHovered ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: isHovered ? const Color(0xFFD52B1E) : Colors.grey.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isHovered ? const Color(0xFFD52B1E) : Colors.grey.shade600,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _handleGuess(BuildContext context, GameProvider game, Direction direction) async {
    print("Handling guess for direction: $direction");
    bool correct = false;
    try {
      correct = await game.makeGuess(direction);
      print("Guess result: $correct");
    } catch (e) {
      print("Error making guess: $e");
    }
    
    if (!context.mounted) return;

    if (correct) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Correct!", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                "New Score: ${game.score}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${game.cityA?.name} ➔ ${game.cityB?.name}",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      // Auto-close after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(context).pop();
          game.nextRound();
        }
      });
    } else {
      // Wrong Answer - Game Over
      
      // 1. Show Journey / Game Over Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFF0EAD6),
          title: const Text("GAME OVER", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel, color: Color(0xFFD52B1E), size: 48),
                const SizedBox(height: 8),
                Text(
                  "Final Score: ${game.score}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rank: #${game.getRank()}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Explanation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "You guessed: ${_directionToString(game.lastGuessedDirection)}",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Correct: ${_directionToString(game.correctDirection)}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${game.cityA?.name} ➔ ${game.cityB?.name}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Map Visualization
                const Text("Your Journey:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.56,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Silhouette Map Background
                          Opacity(
                            opacity: 0.2,
                            child: Image.asset(
                              'assets/switzerland_silhouette.png',
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.map, color: Colors.grey)),
                            ),
                          ),
                          // Path Overlay
                          CustomPaint(
                            painter: SwissMapPainter(visitedCities: game.visitedCities),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close Journey Dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD52B1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      );

      // 2. Check for High Score AFTER Journey Dialog closes
      if (game.isHighScore(game.score)) {
        // High Score Dialog
        final TextEditingController nameController = TextEditingController();
        if (!context.mounted) return;
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              bool isSubmitting = false;

              return AlertDialog(
                backgroundColor: const Color(0xFFF0EAD6),
                title: const Text(
                  "NEW HIGH SCORE!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD52B1E)),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFFFD100), size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "You reached Rank #${game.getRank()}!",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text("Enter your name:"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Center(
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Color(0xFFD52B1E))
                        : ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty) {
                                setState(() {
                                  isSubmitting = true;
                                });
                                try {
                                  await game.submitHighScore(nameController.text);
                                } catch (e) {
                                  print("Submit failed: $e");
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD52B1E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text("OK"),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // 3. Restart Game
      game.restartGame();
    }
  }


  String _directionToString(Direction? d) {
    if (d == null) return "-";
    switch (d) {
      case Direction.north: return "North";
      case Direction.northEast: return "North-East";
      case Direction.east: return "East";
      case Direction.southEast: return "South-East";
      case Direction.south: return "South";
      case Direction.southWest: return "South-West";
      case Direction.west: return "West";
      case Direction.northWest: return "North-West";
    }
  }
}
