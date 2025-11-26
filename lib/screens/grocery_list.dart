import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedCategory = 'Other';
  String _selectedUnit = 'units'; // Default unit
  
  final List<String> _categories = [
    'Vegetable',
    'Fruit',
    'Protein',
    'Dairy',
    'Grain',
    'Beverage',
    'Snack',
    'Spices',
    'Other'
  ];

  final List<String> _unitOptions = [
    'units',
    'grams',
    'KGs',
    'liters',
    'lbs',
    'tablespoon',
    'teaspoon',
    'cups'
  ];


  // Update unit conversion factors to include all variations
  final Map<String, double> _unitConversionFactors = {
    // Weight units (base: grams)
    'grams': 1.0,
    'g': 1.0,
    'gram': 1.0,
    'kgs': 1000.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'lbs': 453.592,
    'lb': 453.592,
    'pound': 453.592,
    'pounds': 453.592,
    'oz': 28.3495,
    'ounce': 28.3495,
    'ounces': 28.3495,
    
    // Volume units (base: milliliters)
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'liters': 1000.0,
    'liter': 1000.0,
    'l': 1000.0,
    'tablespoon': 14.7868,
    'tbsp': 14.7868,
    'tablespoons': 14.7868,
    'teaspoon': 4.92892,
    'tsp': 4.92892,
    'teaspoons': 4.92892,
    'cups': 236.588,
    'cup': 236.588,
    'fl oz': 29.5735,
    'fluid ounce': 29.5735,
    'fluid ounces': 29.5735,
    
    // Count units (base: units)
    'units': 1.0,
    'unit': 1.0,
    'items': 1.0,
    'item': 1.0,
    'pieces': 1.0,
    'piece': 1.0,
    'pcs': 1.0,
    'pc': 1.0,
    '': 1.0,
  };

  // Base units for each category
  String _getBaseUnit(String unit) {
    final normalizedUnit = unit.toLowerCase().trim();
    
    if (_isWeightUnit(normalizedUnit)) return 'grams';
    if (_isVolumeUnit(normalizedUnit)) return 'ml';
    if (_isCountUnit(normalizedUnit)) return 'units';
    
    return 'units'; // default
  }

  // Convert quantity from one unit to another
  double _convertQuantity(double quantity, String fromUnit, String toUnit) {
    if (fromUnit.toLowerCase().trim() == toUnit.toLowerCase().trim()) {
      return quantity;
    }
    
    final fromFactor = _unitConversionFactors[fromUnit.toLowerCase().trim()] ?? 1.0;
    final toFactor = _unitConversionFactors[toUnit.toLowerCase().trim()] ?? 1.0;
    
    if (fromFactor == 0 || toFactor == 0) return quantity;
    
    // Convert to base unit first, then to target unit
    final baseQuantity = quantity * fromFactor;
    return baseQuantity / toFactor;
  }

  // Format quantity for display (round to reasonable precision)
  String _formatQuantity(double quantity, String unit) {
    if (quantity == quantity.truncateToDouble()) {
      return quantity.toInt().toString();
    }
    
    // For very small quantities, show more decimal places
    if (quantity < 1) {
      return quantity.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    // For larger quantities, show fewer decimal places
    if (quantity < 10) {
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    return quantity.toStringAsFixed(1).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // Choose the best display unit based on quantity
  String _chooseBestDisplayUnit(double baseQuantity, String unitCategory) {
    if (unitCategory == 'weight') {
      if (baseQuantity >= 1000) return 'KGs';
      if (baseQuantity >= 1) return 'grams';
      return 'grams';
    } else if (unitCategory == 'volume') {
      if (baseQuantity >= 1000) return 'liters';
      if (baseQuantity >= 1) return 'ml';
      return 'ml';
    }
    
    return 'units';
  }

  // Get unit category
  String _getUnitCategory(String unit) {
    final normalizedUnit = unit.toLowerCase().trim();
    if (_isWeightUnit(normalizedUnit)) return 'weight';
    if (_isVolumeUnit(normalizedUnit)) return 'volume';
    if (_isCountUnit(normalizedUnit)) return 'count';
    return 'count';
  }

    bool _isWeightUnit(String unit) {
    const weightUnits = {
      'g', 'gram', 'grams', 'kg', 'kgs', 'kilogram', 'kilograms', 
      'oz', 'ounce', 'ounces', 'lb', 'lbs', 'pound', 'pounds'
    };
    return weightUnits.contains(unit.toLowerCase().trim());
  }

  bool _isVolumeUnit(String unit) {
    const volumeUnits = {
      'ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters', 
      'cup', 'cups', 'tsp', 'teaspoon', 'teaspoons', 
      'tbsp', 'tablespoon', 'tablespoons', 
      'fl oz', 'fluid ounce', 'fluid ounces'
    };
    return volumeUnits.contains(unit.toLowerCase().trim());
  }

  bool _isCountUnit(String unit) {
    const countUnits = {
      '', 'item', 'items', 'piece', 'pieces', 'unit', 'units', 
      'pcs', 'pc'
    };
    return countUnits.contains(unit.toLowerCase().trim());
  }


  String _translateCategoryName(String name) {
    switch (name.toLowerCase()) {
      case 'vegetable':
        return TranslationHelper.t('Vegetable', 'سبزی');
      case 'fruits':
        return TranslationHelper.t('Fruit', 'پھل');
      case 'protein':
        return TranslationHelper.t('Protein', 'پروٹین');
      case 'dairy':
        return TranslationHelper.t('Dairy', 'ڈیری');
      case 'grain':
        return TranslationHelper.t('Grain', 'اناج');
      case 'beverage':
        return TranslationHelper.t('Beverage', 'مشروب');
      case 'snack':
        return TranslationHelper.t('Snack', 'اسنیکس');
      case 'spice':
        return TranslationHelper.t('Spice', 'مصالحے');
      case 'other':
        return TranslationHelper.t('Other', 'دیگر');
      default:
        return name;
    }
  }

  @override
  void initState() {
    super.initState();
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  // Helper method to parse quantity from string to double
  double _parseQuantity(dynamic quantity) {
    if (quantity == null) return 1.0;
    if (quantity is num) return quantity.toDouble();
    if (quantity is String) {
      return double.tryParse(quantity) ?? 1.0;
    }
    return 1.0;
  }

  // Helper method to check if units are compatible for merging
  bool _areUnitsCompatible(String unit1, String unit2) {
    // Normalize units
    final normalized1 = unit1.toLowerCase().trim();
    final normalized2 = unit2.toLowerCase().trim();
    
    // If both units are empty or same, they're compatible
    if (normalized1 == normalized2) return true;
    
    // If one unit is empty, consider them compatible (assume same unit)
    if (normalized1.isEmpty || normalized2.isEmpty) return true;
    
    // Check if both units belong to the same category
    return (_isWeightUnit(normalized1) && _isWeightUnit(normalized2)) ||
           (_isVolumeUnit(normalized1) && _isVolumeUnit(normalized2)) ||
           (_isCountUnit(normalized1) && _isCountUnit(normalized2));
  }
  // Add item to inventory with duplicate checking and preserve original unit
  Future<void> _addToInventory(DocumentSnapshot groceryItem) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final data = groceryItem.data() as Map<String, dynamic>;
      final String name = (data['name'] ?? '').toString().toLowerCase().trim();
      final String originalName = data['originalName'] ?? name;
      // Use the original quantity and unit from grocery list - note the field is 'amount' in grocery list
      final double amount = _parseQuantity(data['amount'] ?? '1');
      final String unit = (data['unit'] ?? '').toString();
      final String groceryCategory = data['category'] ?? 'Other';
      final String recipeSource = data['recipeSource'] ?? '';
      final String note = data['note'] ?? '';

      // Debug logging
      print('Moving to inventory: $originalName, amount: $amount, unit: $unit');

      // Check if item already exists in inventory
      final existingInventoryQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .where('name', isEqualTo: name)
          .get();

      if (existingInventoryQuery.docs.isNotEmpty) {
        // Item exists in inventory - merge quantities and preserve units
        final existingDoc = existingInventoryQuery.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final double existingQuantity = _parseQuantity(existingData['quantity'] ?? '1');
        final String existingUnit = (existingData['unit'] ?? '').toString().toLowerCase().trim();
        final String existingCategory = existingData['category'] ?? 'Other';
        final String existingNotes = existingData['notes'] ?? '';
        
        // Check if units are compatible
        if (_areUnitsCompatible(existingUnit, unit)) {
          // Convert both quantities to a common base unit and merge
          final String baseUnit = _getBaseUnit(existingUnit);
          final String unitCategory = _getUnitCategory(existingUnit);
          
          // Convert existing inventory quantity to base unit
          final double existingInBase = _convertQuantity(existingQuantity, existingUnit, baseUnit);
          
          // Convert grocery item quantity to base unit
          final double newInBase = _convertQuantity(amount, unit, baseUnit);
          
          // Merge quantities in base unit
          final double mergedInBase = existingInBase + newInBase;
          
          // Choose the best display unit for the merged quantity
          final String bestDisplayUnit = _chooseBestDisplayUnit(mergedInBase, unitCategory);
          
          // Convert back to the best display unit
          final double mergedQuantity = _convertQuantity(mergedInBase, baseUnit, bestDisplayUnit);
          final String displayQuantity = _formatQuantity(mergedQuantity, bestDisplayUnit);
          
          // Combine notes if there are any from grocery item
          String combinedNotes = existingNotes;
          if (note.isNotEmpty) {
            combinedNotes = existingNotes.isEmpty 
                ? note 
                : '$existingNotes\n$note';
          }

          // Update inventory with merged quantity and best display unit
          // Note: Inventory uses 'quantity' field (not 'amount')
          await existingDoc.reference.update({
            'quantity': displayQuantity, // Use 'quantity' for inventory
            'unit': bestDisplayUnit,
            'updatedAt': FieldValue.serverTimestamp(),
            'notes': combinedNotes,
            // Keep existing category and other inventory-specific fields
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $originalName to inventory: $existingQuantity $existingUnit + $amount $unit = $displayQuantity $bestDisplayUnit'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Units are incompatible - add as new item with original unit and quantity
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('inventory')
              .add({
            'name': name,
            'quantity': amount.toString(), // Use 'quantity' for inventory
            'unit': unit, // Use original unit
            'category': groceryCategory, // Use grocery category for new items
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'notes': note.isNotEmpty ? note : '',
            // Set default expiry date based on category
            'expiryDate': _calculateDefaultExpiryDate(groceryCategory),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $originalName to inventory ($amount $unit)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Item doesn't exist in inventory - add new item with original unit and quantity
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('inventory')
            .add({
          'name': name,
          'quantity': amount.toString(), // Use 'quantity' for inventory
          'unit': unit, // Use original unit
          'category': groceryCategory,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'notes': note.isNotEmpty ? note : '',
          // Set default expiry date based on category
          'expiryDate': _calculateDefaultExpiryDate(groceryCategory),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $originalName to inventory ($amount $unit)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Remove from grocery list after adding to inventory
      await _removeItem(groceryItem.id);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to inventory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to calculate default expiry date based on category
  String _calculateDefaultExpiryDate(String category) {
    final now = DateTime.now();
    final Map<String, int> categoryExpiryDays = {
      'Vegetable': 7,
      'Fruit': 5,
      'Protein': 14,
      'Dairy': 7,
      'Grain': 365, // 1 year for grains
      'Beverage': 180, // 6 months for beverages
      'Snack': 90, // 3 months for snacks
      'Spice': 365, // 1 year for spices
      'Other': 30, // 1 month default
    };

    final days = categoryExpiryDays[category] ?? 30;
    final expiryDate = now.add(Duration(days: days));
    
    // Format as YYYY-MM-DD
    return '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
  }

  // Show bottom sheet menu for grocery items (more reliable positioning)
  void _showItemMenu(DocumentSnapshot doc, String itemName) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  itemName.capitalize(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Divider(
                color: isDarkMode ? const Color(0xFF404040) : Colors.grey[300],
                height: 1,
              ),
              // Menu Items
              _buildMenuOption(
                icon: Icons.inventory_2_outlined,
                title: TranslationHelper.t('Add to Inventory', 'انوینٹری میں شامل کریں'),
                color: Colors.green[700]!,
                onTap: () {
                  Navigator.pop(context);
                  _addToInventory(doc);
                },
              ),
              _buildMenuOption(
                icon: Icons.delete_outline,
                title: TranslationHelper.t('Delete', 'حذف کریں'),
                color: Colors.red[700]!,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(doc.id, itemName);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build menu option
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;

    return ListTile(
      leading: Icon(icon, size: 24, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
      onTap: onTap,
    );
  }

  // Add new item to grocery list with duplicate checking and unit conversion
  Future<void> _addItem() async {
    final user = _auth.currentUser;
    if (user == null || _itemController.text.trim().isEmpty) return;

    final String name = _itemController.text.trim().toLowerCase();
    final String originalName = _itemController.text.trim();
    final double newQuantity = _parseQuantity(_quantityController.text.trim().isEmpty ? '1' : _quantityController.text.trim());
    final String newUnit = _selectedUnit;
    final String category = _selectedCategory;

    try {
      // Check if item already exists in the grocery list
      final existingItemsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .where('name', isEqualTo: name)
          .where('isChecked', isEqualTo: false)
          .get();

      if (existingItemsQuery.docs.isNotEmpty) {
        // Item exists - handle unit conversion and merging
        final existingDoc = existingItemsQuery.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final double existingQuantity = _parseQuantity(existingData['amount'] ?? '1');
        final String existingUnit = (existingData['unit'] ?? '').toString();
        final String existingCategory = existingData['category'] ?? 'Other';
        
        // Check if units and categories are compatible for merging
        if (_areUnitsCompatible(existingUnit, newUnit) && existingCategory == category) {
          // Convert both quantities to a common base unit and merge
          final String baseUnit = _getBaseUnit(existingUnit);
          final String unitCategory = _getUnitCategory(existingUnit);
          
          // Convert existing quantity to base unit
          final double existingInBase = _convertQuantity(existingQuantity, existingUnit, baseUnit);
          
          // Convert new quantity to base unit
          final double newInBase = _convertQuantity(newQuantity, newUnit, baseUnit);
          
          // Merge quantities in base unit
          final double mergedInBase = existingInBase + newInBase;
          
          // Choose the best display unit for the merged quantity
          final String bestDisplayUnit = _chooseBestDisplayUnit(mergedInBase, unitCategory);
          
          // Convert back to the best display unit
          final double mergedQuantity = _convertQuantity(mergedInBase, baseUnit, bestDisplayUnit);
          final String displayQuantity = _formatQuantity(mergedQuantity, bestDisplayUnit);
          
          await existingDoc.reference.update({
            'amount': displayQuantity,
            'unit': bestDisplayUnit,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated $originalName: $existingQuantity $existingUnit + $newQuantity $newUnit = $displayQuantity $bestDisplayUnit'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Units or categories are incompatible - add as new item with note
          String note = '';
          if (existingUnit != newUnit && existingCategory != category) {
            note = 'Different unit and category from existing item';
          } else if (existingUnit != newUnit) {
            note = 'Different unit from existing item';
          } else {
            note = 'Different category from existing item';
          }
          
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('grocery_list')
              .add({
            'name': name,
            'originalName': originalName,
            'amount': newQuantity.toString(),
            'unit': newUnit,
            'category': category,
            'isChecked': false,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'note': note,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $originalName ($note)'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Item doesn't exist - add new item
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('grocery_list')
            .add({
          'name': name,
          'originalName': originalName,
          'amount': newQuantity.toString(),
          'unit': newUnit,
          'category': category,
          'isChecked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $originalName to grocery list'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Clear form
      _itemController.clear();
      _quantityController.clear();
      // Reset unit to default
      setState(() {
        _selectedUnit = 'units';
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Remove item from grocery list
  Future<void> _removeItem(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .doc(docId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Toggle item checked status
  Future<void> _toggleItemChecked(String docId, bool currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .doc(docId)
          .update({
        'isChecked': !currentStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Clear all checked items
  Future<void> _clearCheckedItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('grocery_list')
          .where('isChecked', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleared ${querySnapshot.docs.length} checked items'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear items: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Build grocery item card
  Widget _buildGroceryItem(DocumentSnapshot doc) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['originalName'] ?? data['name'] ?? 'Unknown';
    final String amount = data['amount']?.toString() ?? '1';
    final String unit = data['unit']?.toString() ?? '';
    final String category = data['category'] ?? 'Other';
    final bool isChecked = data['isChecked'] ?? false;
    final String recipeSource = data['recipeSource'] ?? '';
    final String note = data['note'] ?? '';

    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: (value) => _toggleItemChecked(doc.id, isChecked),
          activeColor: const Color(0xFF5C8A94),
        ),
        title: Text(
          name.capitalize(),
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (amount != '1' || unit.isNotEmpty)
              Text(
                '$amount ${unit.isNotEmpty ? unit : ''}'.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                  decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            if (recipeSource.isNotEmpty)
              Text(
                'From: $recipeSource',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF5C8A94),
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (note.isNotEmpty)
              Text(
                note,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getCategoryColor(category).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _translateCategoryName(category),
                style: TextStyle(
                  fontSize: 10,
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.grey[600],
            ),
            onPressed: () => _showItemMenu(doc, name),
          ),
        ),
      ),
    );
  }

  // Get color for category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fruits':
        return const Color(0xFF4CAF50);
      case 'Vegetable':
        return const Color(0xFF8BC34A);
      case 'Protein':
        return const Color(0xFFF44336);
      case 'Dairy':
        return const Color(0xFFFFC107);
      case 'Grain':
        return const Color(0xFF795548);
      case 'Beverage':
        return const Color(0xFF2196F3);
      case 'Snack':
        return const Color(0xFFFF9800);
      case 'Spice':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = ThemeProvider().darkModeEnabled;
        final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
        final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
        
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'Remove Item',
            style: TextStyle(color: textColor),
          ),
          content: Text(
            'Are you sure you want to remove "$itemName" from your grocery list?',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: const Color(0xFF5C8A94)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeItem(docId);
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build modern collapsible add item form
  Widget _buildAddItemForm() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF888888) : Colors.grey[600]!;
    final borderColor = isDarkMode ? const Color(0xFF404040) : Colors.grey[300]!;
    final accentColor = const Color(0xFF5C8A94);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add,
            color: accentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Add New Item',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.expand_more,
            color: accentColor,
            size: 18,
          ),
        ),
        children: [
          Divider(
            color: borderColor,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Item Name Field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      hintText: 'What do you need to buy?',
                      hintStyle: TextStyle(color: hintColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(
                        Icons.shopping_basket_outlined,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quantity and Unit Row
                Row(
                  children: [
                    // Quantity Field
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            hintText: '1',
                            hintStyle: TextStyle(color: hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: Icon(
                              Icons.numbers,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Unit Dropdown Field
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(
                              Icons.straighten_outlined,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor, fontSize: 16),
                          items: _unitOptions.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedUnit = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    dropdownColor: backgroundColor,
                    style: TextStyle(color: textColor, fontSize: 16),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          _translateCategoryName(category),
                          style: TextStyle(color: textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Add Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: accentColor.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add to Grocery List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    final groceryListTitle = TranslationHelper.t('Grocery List', 'گروسری لسٹ');
    final clearCheckedLabel = TranslationHelper.t('Clear Checked', 'چیک شدہ صاف کریں');

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0, // Adjust index based on your nav bar
        navContext: context,
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(groceryListTitle, style: TextStyle(color: textColor)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user?.uid)
                .collection('grocery_list')
                .where('isChecked', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final checkedCount = snapshot.data?.docs.length ?? 0;
              if (checkedCount == 0) return const SizedBox.shrink();
              
              return IconButton(
                icon: Badge(
                  label: Text(checkedCount.toString()),
                  child: const Icon(Icons.check_circle_outline),
                ),
                onPressed: _clearCheckedItems,
                tooltip: clearCheckedLabel,
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text(
                'Please log in to view your grocery list',
                style: TextStyle(color: textColor),
              ),
            )
          : Column(
              children: [
                // Add Item Form
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAddItemForm(),
                ),
                
                // Grocery List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('grocery_list')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: const Color(0xFF5C8A94)),
                        );
                      }

                      final items = snapshot.data?.docs ?? [];

                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: isDarkMode ? const Color(0xFF404040) : Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your grocery list is empty',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add items using the form above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildGroceryItem(items[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}