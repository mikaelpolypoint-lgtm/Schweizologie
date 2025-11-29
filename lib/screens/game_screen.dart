import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/city.dart';
import '../services/firebase_service.dart';
import 'game_over_screen.dart';
import '../import_cities.dart';

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
      body: GestureDetector(
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
                    const SizedBox(height: 8),
                    const Text("Please import the city data."),
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

            // if (game.gameState == GameState.gameOver) {
            //   return const GameOverScreen();
            // }

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
                        // Drop Zones - Expanded to be easier to hit
                        // North (Top 35%)
                        Positioned(
                          top: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.35,
                          child: _buildDropZoneArea(context, game, Direction.north, "Norden"),
                        ),
                        // South (Bottom 35%)
                        Positioned(
                          bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.35,
                          child: _buildDropZoneArea(context, game, Direction.south, "Süden"),
                        ),
                        // West (Left 35%, Middle 30% height)
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.35,
                          bottom: MediaQuery.of(context).size.height * 0.35,
                          left: 0,
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: _buildDropZoneArea(context, game, Direction.west, "West"),
                        ),
                        // East (Right 35%, Middle 30% height)
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.35,
                          bottom: MediaQuery.of(context).size.height * 0.35,
                          right: 0,
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: _buildDropZoneArea(context, game, Direction.east, "Ost"),
                        ),

                        // Center: City A
                        Align(
                          alignment: Alignment.center,
                          child: _CityCircle(
                            city: game.cityA!,
                            label: "City A",
                            color: Colors.blueGrey,
                          ),
                        ),

                        // Draggable: City B
                        // We place it initially somewhere, or let the user drag it from a "deck".
                        // The prompt implies dragging City B. Let's put it in a corner or floating.
                        // Actually, the prompt image shows City B being dragged.
                        // Let's put City B at the top-left as a "New Card" to drag.
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Draggable<bool>(
                            data: true,
                            feedback: Material(
                              color: Colors.transparent,
                              child: _CityCircle(
                                city: game.cityB!,
                                label: "City B",
                                color: Colors.blue,
                                isDragging: true,
                              ),
                            ),
                            childWhenDragging: Container(), // Hide when dragging
                            child: _CityCircle(
                              city: game.cityB!,
                              label: "City B",
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        
                        // Instruction Text
                        const Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Text(
                            "Drag City B to the correct direction relative to City A",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
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
    );
  }

  Widget _buildHeader(int score) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Schweizologie',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Score: $score',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
      // Wrong Answer
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Leider Falsch", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                "Final Score: ${game.score}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Rank: #${game.getRank()}",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  game.restartGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Try Again"),
              ),
            ),
          ],
        ),
      );
    }
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
            color: isHovered ? Colors.red.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHovered ? Colors.red : Colors.grey,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CityCircle extends StatelessWidget {
  final City city;
  final String label;
  final Color color;
  final bool isDragging;

  const _CityCircle({
    required this.city,
    required this.label,
    required this.color,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isDragging
            ? [const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]
            : [const BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            city.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            city.canton,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
