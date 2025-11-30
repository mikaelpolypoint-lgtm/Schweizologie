import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/game_provider.dart';
import 'screens/game_screen.dart';
import 'services/firebase_service.dart';
import 'import_cities.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // TODO: Replace with your actual Firebase Web Config from Firebase Console
      // Go to Project Settings -> General -> Your apps -> Web App -> SDK setup and configuration
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC2wfr0TzaXRTREJzcAxZtySJUVZ2xOey8",
  authDomain: "schweizologie.firebaseapp.com",
  projectId: "schweizologie",
  storageBucket: "schweizologie.firebasestorage.app",
  messagingSenderId: "221742944714",
  appId: "1:221742944714:web:1106bdb033749ab3243f33",
  measurementId: "G-09G11BX17F"
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("Firebase Initialization Error: $e");
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If you are running on Web, you must provide your Firebase Config in lib/main.dart.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: Text(error, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        Provider(create: (_) => FirebaseService()),
      ],
      child: MaterialApp(
        title: 'Schweizologie',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD52B1E), // Swiss Red
            primary: const Color(0xFFD52B1E),
            secondary: const Color(0xFF2D3436), // Dark Slate
            background: const Color(0xFFF0EAD6), // Cream
            surface: const Color(0xFFF0EAD6),
          ),
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0EAD6),
        ),
        home: const GameScreen(),
      ),
    );
  }
}
