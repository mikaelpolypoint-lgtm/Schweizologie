import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/city.dart';
import '../import_cities.dart';
import '../widgets/contour_map_background.dart';
import '../widgets/city_sign.dart';

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
                              child: CitySign(
                                city: game.cityA!,
                                label: "Start",
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  backgroundColor: const Color(0xFFD52B1E),
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
}
