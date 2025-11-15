import 'package:flutter/material.dart';
import 'inventory_categories.dart';
import 'dishes.dart';

// --- Data Model for Inventory Items ---
class InventoryItem {
  final String name;
  final IconData icon;
  final String category;

  const InventoryItem({
    required this.name,
    required this.icon,
    required this.category,
  });
}

// --- Main Inventory Categories Screen Widget ---
class InventoryCategoriesScreen extends StatelessWidget {
  const InventoryCategoriesScreen({super.key});

  // Data for the main category buttons
  final List<InventoryItem> categories = const [
    InventoryItem(name: 'Vegetables', icon: Icons.grass_outlined, category: 'Vegetable'),
    InventoryItem(name: 'Fruits', icon: Icons.apple, category: 'Fruit'),
    InventoryItem(name: 'Protein', icon: Icons.local_fire_department_outlined, category: 'Protein'),
    InventoryItem(name: 'Dairy', icon: Icons.local_drink_outlined, category: 'Dairy'),
    InventoryItem(name: 'Grains', icon: Icons.grain_outlined, category: 'Grain'),
    InventoryItem(name: 'Beverages', icon: Icons.coffee, category: 'Beverage'),
    InventoryItem(name: 'Snacks', icon: Icons.cookie, category: 'Snack'),
    InventoryItem(name: 'Spices', icon: Icons.energy_savings_leaf, category: 'Spices'),
    InventoryItem(name: 'Other', icon: Icons.more_horiz, category: 'Other'),
  ];

  // Helper function for navigating to the InventoryScreen with category
  void _navigateToInventoryScreen(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryScreen(category: category),
      ),
    );
  }

  // Widget for a single, stylish category button
  Widget _buildCategoryButton(BuildContext context, InventoryItem category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _navigateToInventoryScreen(context, category.category),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C8A94),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 24.0),
            const SizedBox(width: 15),
            Text(
              category.name,
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18.0),
          ],
        ),
      ),
    );
  }

  // Widget for the clickable search bar
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to search functionality - you can implement this later
        // For now, it could navigate to a search screen or show a search dialog
        _showSearchDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 24.0),
            const SizedBox(width: 10),
            Text(
              'Search All Items',
              style: TextStyle(color: Colors.grey[600], fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search'),
          content: const Text('Search functionality would be implemented here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 28.0, color: Colors.black),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Search Bar
              _buildSearchBar(context),

              // Categories List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryButton(context, categories[index]);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Find Recipes Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _navigateToRecipes(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAFB73D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFb8cf6b).withOpacity(0.5),
                  ),
                  child: const Text(
                    'Find Recipes →',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RecipeApp(),
    ),
    );
  }
}

// --- Application Entry Point ---
class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      home: const InventoryCategoriesScreen(),
      routes: {
        // You can also use named routes if preferred
        '/inventory': (context) {
          final category = ModalRoute.of(context)!.settings.arguments as String? ?? 'All';
          return InventoryScreen(category: category);
        },
      },
    );
  }
}