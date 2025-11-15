// api_service.dart
import 'dart:convert';
import 'dart:io'; // Add this for InternetAddress
import 'package:http/http.dart' as http; // This should work now
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String _baseUrl = 'https://api.spoonacular.com';
  static const String _apiKey = '6d495b2ad5f74b1b8fb8536e2d5beeca';
  // static String get _apiKey {
  //   return dotenv.get('SPOONACULAR_API_KEY');
  // }
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('api.spoonacular.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Get inventory ingredients for current user
  static Future<List<String>> getInventoryIngredients() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final ingredients = querySnapshot.docs
          .map((doc) => doc.data()['name'] as String?)
          .where((name) => name != null && name.isNotEmpty)
          .map((name) => name!.toLowerCase())
          .toList();

      print('Found inventory ingredients: $ingredients');
      return ingredients;
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  // Add this method to your existing ApiService class in api_service.dart

// Fetch detailed recipe information by ID
static Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
  try {
    // Check internet connection first
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      throw Exception('No internet connection. Please check your network settings.');
    }

    // Build the URL for recipe details
    final url = Uri.parse(
      '$_baseUrl/recipes/$recipeId/information?'
      'includeNutrition=false&'
      'apiKey=$_apiKey'
    );

    print('Recipe Details API Request URL: $url');

    // Make the API call with timeout
    final response = await http.get(url).timeout(const Duration(seconds: 30));

    print('Recipe Details API Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> recipeDetails = json.decode(response.body);
      print('Received detailed recipe information');
      return recipeDetails;
    } else {
      print('Recipe Details API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load recipe details: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching recipe details: $e');
    throw e;
  }
}

  // Fetch recipe instructions by ID
  static Future<List<dynamic>> fetchRecipeInstructions(int recipeId) async {
    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      // Build the URL for recipe instructions
      final url = Uri.parse(
        '$_baseUrl/recipes/$recipeId/analyzedInstructions?'
        'apiKey=$_apiKey'
      );

      print('Recipe Instructions API Request URL: $url');

      // Make the API call with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      print('Recipe Instructions API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> instructions = json.decode(response.body);
        print('Received recipe instructions');
        return instructions;
      } else {
        print('Recipe Instructions API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipe instructions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipe instructions: $e');
      throw e;
    }
  }

  // Fetch recipes by ingredients
  static Future<List<dynamic>> fetchRecipesByIngredients({
    int number = 10,
    int ranking = 1,
    bool ignorePantry = false,
  }) async {
    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      // Get ingredients from inventory
      final ingredients = await getInventoryIngredients();
      
      if (ingredients.isEmpty) {
        print('No ingredients found in inventory');
        return [];
      }

      // Convert ingredients list to comma-separated string
      final ingredientsString = ingredients.join(',');
      print('Ingredients for API: $ingredientsString');

      // Build the URL with parameters
      final url = Uri.parse(
        '$_baseUrl/recipes/findByIngredients?'
        'ingredients=$ingredientsString&'
        'number=$number&'
        'ranking=$ranking&'
        'ignorePantry=$ignorePantry&'
        'apiKey=$_apiKey'
      );

      print('API Request URL: $url');

      // Make the API call with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> recipes = json.decode(response.body);
        print('Received ${recipes.length} recipes');
        return recipes;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw e;
    }
  }
}

// api_service.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// class ApiService {
//   static const String _baseUrl = 'https://api.spoonacular.com';
  
//   // Use a static variable to track initialization
//   static bool _isInitialized = false;
//   static String? _apiKey;
  
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Initialize method to be called from main.dart
//   static Future<void> initialize() async {
//     try {
//       _apiKey = dotenv.get('SPOONACULAR_API_KEY');
//       if (_apiKey == null || _apiKey!.isEmpty) {
//         throw Exception('SPOONACULAR_API_KEY not found or empty in .env file');
//       }
//       _isInitialized = true;
//       print('✅ ApiService initialized with API key');
//     } catch (e) {
//       print('❌ ApiService initialization failed: $e');
//       rethrow;
//     }
//   }

//   static String get _validApiKey {
//     if (!_isInitialized || _apiKey == null) {
//       throw Exception('ApiService not initialized. Call ApiService.initialize() first.');
//     }
//     return _apiKey!;
//   }

//   // Check internet connectivity
//   static Future<bool> hasInternetConnection() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } on SocketException catch (_) {
//       return false;
//     }
//   }

//   // Get inventory ingredients for current user
//   static Future<List<String>> getInventoryIngredients() async {
//     final user = _auth.currentUser;
//     if (user == null) return [];

//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('inventory')
//           .get();

//       final ingredients = querySnapshot.docs
//           .map((doc) => doc.data()['name'] as String?)
//           .where((name) => name != null && name.isNotEmpty)
//           .map((name) => name!.toLowerCase())
//           .toList();

//       print('Found inventory ingredients: $ingredients');
//       return ingredients;
//     } catch (e) {
//       print('Error fetching inventory: $e');
//       return [];
//     }
//   }

//   // Fetch detailed recipe information by ID
//   static Future<Map<String, dynamic>> fetchRecipeDetails(int recipeId) async {
//     try {
//       final hasConnection = await hasInternetConnection();
//       if (!hasConnection) {
//         throw Exception('No internet connection. Please check your network settings.');
//       }

//       final url = Uri.parse(
//         '$_baseUrl/recipes/$recipeId/information?'
//         'includeNutrition=false&'
//         'apiKey=$_validApiKey'
//       );

//       print('Recipe Details API Request URL: ${url.toString().replaceAll(_validApiKey, '***')}');

//       final response = await http.get(url).timeout(const Duration(seconds: 30));

//       print('Recipe Details API Response Status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> recipeDetails = json.decode(response.body);
//         print('Received detailed recipe information');
//         return recipeDetails;
//       } else {
//         print('Recipe Details API Error: ${response.statusCode} - ${response.body}');
//         throw Exception('Failed to load recipe details: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching recipe details: $e');
//       throw e;
//     }
//   }

//   // Fetch recipe instructions by ID
//   static Future<List<dynamic>> fetchRecipeInstructions(int recipeId) async {
//     try {
//       final hasConnection = await hasInternetConnection();
//       if (!hasConnection) {
//         throw Exception('No internet connection. Please check your network settings.');
//       }

//       final url = Uri.parse(
//         '$_baseUrl/recipes/$recipeId/analyzedInstructions?'
//         'apiKey=$_validApiKey'
//       );

//       print('Recipe Instructions API Request URL: ${url.toString().replaceAll(_validApiKey, '***')}');

//       final response = await http.get(url).timeout(const Duration(seconds: 30));

//       print('Recipe Instructions API Response Status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final List<dynamic> instructions = json.decode(response.body);
//         print('Received recipe instructions');
//         return instructions;
//       } else {
//         print('Recipe Instructions API Error: ${response.statusCode} - ${response.body}');
//         throw Exception('Failed to load recipe instructions: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching recipe instructions: $e');
//       throw e;
//     }
//   }

//   // Fetch recipes by ingredients
//   static Future<List<dynamic>> fetchRecipesByIngredients({
//     int number = 10,
//     int ranking = 1,
//     bool ignorePantry = false,
//   }) async {
//     try {
//       final hasConnection = await hasInternetConnection();
//       if (!hasConnection) {
//         throw Exception('No internet connection. Please check your network settings.');
//       }

//       final ingredients = await getInventoryIngredients();
      
//       if (ingredients.isEmpty) {
//         print('No ingredients found in inventory');
//         return [];
//       }

//       final ingredientsString = ingredients.join(',');
//       print('Ingredients for API: $ingredientsString');

//       final url = Uri.parse(
//         '$_baseUrl/recipes/findByIngredients?'
//         'ingredients=$ingredientsString&'
//         'number=$number&'
//         'ranking=$ranking&'
//         'ignorePantry=$ignorePantry&'
//         'apiKey=$_validApiKey'
//       );

//       print('API Request URL: ${url.toString().replaceAll(_validApiKey, '***')}');

//       final response = await http.get(url).timeout(const Duration(seconds: 30));

//       print('API Response Status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final List<dynamic> recipes = json.decode(response.body);
//         print('Received ${recipes.length} recipes');
//         return recipes;
//       } else {
//         print('API Error: ${response.statusCode} - ${response.body}');
//         throw Exception('Failed to load recipes: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching recipes: $e');
//       throw e;
//     }
//   }
// }