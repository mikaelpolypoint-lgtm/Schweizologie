import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Game Over',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Final Score: ${game.score}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),
              Text(
                'High Scores',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Consumer<GameProvider>(
                builder: (context, game, child) {
                  return Column(
                    children: game.highScores
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${entry.key + 1}. ${entry.value.userName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${entry.value.score}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  game.restartGame();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
