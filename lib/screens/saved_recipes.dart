import 'package:flutter/material.dart';
import 'recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MAIN APP ENTRY POINT ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCB73)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const SavedRecipesScreen(),
    );
  }
}

// --- SAVED RECIPES SCREEN (STATEFUL) ---
class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryColor = Color(0xFFFFCB73);
  List<DocumentSnapshot> _filteredRecipes = [];
  List<DocumentSnapshot> _allRecipes = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRecipes);
    _searchController.dispose();
    super.dispose();
  }

  // --- FIREBASE DATA FETCHING ---
  Stream<QuerySnapshot> _getSavedRecipesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // --- SEARCH LOGIC ---
  void _filterRecipes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title']?.toString().toLowerCase() ?? '';
          return title.contains(query);
        }).toList();
      }
    });
  }

  // --- NAVIGATION METHOD ---
  void _navigateToRecipeDetail(Map<String, dynamic> recipeData, String documentId) {
    // Extract recipeId from the recipe data - handle both possible field names
    final recipeId = recipeData['recipeId'] ?? recipeData['recipеId'] ?? recipeData['id'];
    
    if (recipeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: recipeData,
          recipeId: recipeId.toString(), // Pass the recipeId explicitly
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSearchBar() {
    // final screenHeight = MediaQuery.of(context).size.height;
    // final headerHeight = screenHeight * 0.25;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        elevation: 8.0,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(30.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Recipe',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: const BorderSide(color: Colors.white, width: 0.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSavedRecipesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading recipes: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Update the recipes lists
        _allRecipes = snapshot.data!.docs;
        if (_searchController.text.isEmpty) {
          _filteredRecipes = _allRecipes;
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _filteredRecipes.length,
          itemBuilder: (context, index) {
            final doc = _filteredRecipes[index];
            final recipeData = doc.data() as Map<String, dynamic>;
            
            return _buildRecipeCard(recipeData, doc.id);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipeData, String documentId) {
    // Extract recipe ID for debugging
    final recipeId = recipeData['recipeId'] ?? recipeData['recipеId'] ?? recipeData['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            recipeData['image'] ?? 'https://via.placeholder.com/60x60',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.fastfood, color: Colors.grey[600]),
              );
            },
          ),
        ),
        title: Text(
          recipeData['title'] ?? 'Untitled Recipe',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Likes: ${recipeData['likes'] ?? 0}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (recipeData['missedIngredientCount'] != null)
              Text(
                'Missing ingredients: ${recipeData['missedIngredientCount']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('View Recipe'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _navigateToRecipeDetail(recipeData, documentId);
            } else if (value == 'delete') {
              _deleteRecipe(documentId);
            }
          },
        ),
        onTap: () {
          _navigateToRecipeDetail(recipeData, documentId);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading your saved recipes...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.bookmark_border,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Recipes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save recipes to see them here!',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Failed to load recipes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe(String documentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe removed from saved recipes'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove recipe: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 60.0;
    const double headerHeight = 150.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // 1. Custom Header Section with Overlapping Search Bar
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Yellow Background Container with Title and Back Button
                Container(
                  height: headerHeight,
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50.0),
                      bottomRight: Radius.circular(50.0),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Back Button
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          // Title
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 48.0),
                              child: Center(
                                child: Text(
                                  'Saved Recipes',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Positioned(
                  bottom: -searchBarHeight / 2,
                  left: 0,
                  right: 0,
                  child: _buildSearchBar(),
                ),
              ],
            ),

            // 2. Main Content Area
            SizedBox(height: searchBarHeight / 2 + 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildRecipeList(),
            ),
          ],
        ),
      ),
    );
  }
}