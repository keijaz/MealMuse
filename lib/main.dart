import 'package:flutter/material.dart';
import 'screens/homepage.dart';
import 'firebase_service.dart';
// import 'screens/expiring.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
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
