// import 'package:flutter/material.dart';
// import 'screens/homepage.dart';
// import 'firebase_service.dart';
// // import 'screens/expiring.dart';

// Future<void> main() async {
//   // Ensure Flutter bindings are initialized
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await FirebaseService.initialize();
  
//   runApp(const FigmaLoginLab());
// }

// class FigmaLoginLab extends StatelessWidget {
//  const FigmaLoginLab({super.key});
//  @override
//  Widget build(BuildContext context) {
//  return MaterialApp(
//  debugShowCheckedModeBanner: false,
//  home: HomePage(),
//  );
//  }
// }

// -----------------------------------------


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/homepage.dart';
import 'firebase_service.dart';
import 'screens/api_service.dart'; 
// import 'screens/expiring.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  bool envLoaded = false;
  bool firebaseInitialized = false;
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
    print('✅ Environment variables loaded successfully');
    
    // Check for essential keys
    final essentialKeys = ['SPOONACULAR_API_KEY'];
    for (final key in essentialKeys) {
      if (dotenv.maybeGet(key) == null) {
        print('⚠️  Essential key missing: $key');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Failed to load .env file: $e');
    print('Stack trace: $stackTrace');
    envLoaded = false;
  }
  
  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
    firebaseInitialized = false;
  }
  
  // Log overall initialization status
  print('🚀 App initialization complete:');
  print('   - Environment: ${envLoaded ? "✅" : "❌"}');
  print('   - Firebase: ${firebaseInitialized ? "✅" : "❌"}');
  
  runApp(const FigmaLoginLab());
}

class FigmaLoginLab extends StatelessWidget {
  const FigmaLoginLab({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
