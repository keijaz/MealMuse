import 'package:flutter/material.dart';
import 'home.dart';
import 'api_service.dart'; // Add this import
import 'recipe.dart';

// Define the primary color based on the hex code #5C8A94
const Color _primaryColor = Color(0xFF5C8A94);
const Color _primaryColor30 = Color(0x4D5C8A94); // 30% opacity of #5C8A94 (0x4D is 30% of 0xFF)

// --- Main Application Entry Point ---
void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipes App',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
            .copyWith(primary: _primaryColor),
      ),
      home: const RecipesScreen(),
    );
  }
}

// --- 1. The Filter Screen (Updated) ---
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Data for the filter categories
  final List<String> courses = [
    'Appetizer / Starter',
    'Soup',
    'Salad',
    'First Course',
    'Main Course',
    'Cheese Course',
    'Dessert'
  ];
  final List<String> cuisines = [
    'Chinese',
    'Japanese',
    'Thai',
    'Indian',
    'Korean',
    'Vietnamese',
    'Indonesian',
    'Malaysian',
    'Filipino',
    'Taiwanese'
  ];

  // State to track selected items for multi-selection
  Set<String> selectedCourses = {'Appetizer / Starter'};
  Set<String> selectedCuisines = {'Thai', 'Chinese'};

  // Helper function to build a list of selectable filter items
  Widget _buildFilterSection(
      String title, List<String> items, Set<String> selectedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedItems.remove(item);
                  } else {
                    selectedItems.add(item);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor
                      : _primaryColor30,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: const BoxDecoration(
            color: _primaryColor30,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 48.0),
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 28.0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildFilterSection('Course', courses, selectedCourses),
            const SizedBox(height: 10.0),
            _buildFilterSection('Cuisine', cuisines, selectedCuisines),
          ],
        ),
      ),
    );
  }
}

// --- 2. The Main Screen (Recipes Screen) - UPDATED ---
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final recipes = await ApiService.fetchRecipesByIngredients(
        number: 10,
        ranking: 1,
        ignorePantry: false, // Set to false as requested
      );
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );
  }

  // UPDATED: Navigation method to RecipeDetailScreen
  void _navigateToRecipeDetail(Map<String, dynamic> recipe) {
    // Extract recipe ID - handle different possible field names
    final recipeId = recipe['id']?.toString() ?? '';
    
    if (recipeId.isEmpty) {
      // Show error if no recipe ID found
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
          recipe: recipe,
          recipeId: recipeId, // Pass the recipeId parameter
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // UPDATED: Use the new navigation method
          _navigateToRecipeDetail(recipe);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe['image'] ?? 'https://via.placeholder.com/100x100',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Recipe Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'Untitled Recipe',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Missing ingredients: ${recipe['missedIngredientCount'] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Likes: ${recipe['likes'] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    // Debug: Show recipe ID (optional - remove in production)
                    Text(
                      'ID: ${recipe['id'] ?? 'Not found'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search,
              size: 150.0,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 30.0),
            const Text(
              'No Recipes Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Try adding things to your inventory',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _fetchRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 150.0,
              color: Colors.red[300],
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Error Loading Recipes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _fetchRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Finding recipes based on your inventory...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainAppScreen()),
            );
          },
        ),
        title: const Text('Recipes'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_list, size: 28.0, color: Colors.black),
            onPressed: () => _navigateToFilterScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 28.0, color: Colors.black),
            onPressed: _fetchRecipes,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _recipes.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchRecipes,
                      child: ListView.builder(
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeCard(_recipes[index]);
                        },
                      ),
                    ),
    );
  }
}