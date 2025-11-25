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
  final TextEditingController _unitController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedCategory = 'Other';
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Protein',
    'Dairy',
    'Grains',
    'Beverages',
    'Snacks',
    'Spices',
    'Other'
  ];

  String _translateCategoryName(String name) {
    switch (name.toLowerCase()) {
      case 'vegetables':
        return TranslationHelper.t('Vegetables', 'سبزی');
      case 'fruits':
        return TranslationHelper.t('Fruits', 'پھل');
      case 'protein':
        return TranslationHelper.t('Protein', 'پروٹین');
      case 'dairy':
        return TranslationHelper.t('Dairy', 'ڈیری');
      case 'grains':
        return TranslationHelper.t('Grains', 'اناج');
      case 'beverages':
        return TranslationHelper.t('Beverages', 'مشروب');
      case 'snacks':
        return TranslationHelper.t('Snacks', 'اسنیکس');
      case 'spices':
        return TranslationHelper.t('Spices', 'مصالحے');
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
    _unitController.dispose();
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
    
    // Define compatible unit groups
    const weightUnits = {'g', 'gram', 'grams', 'kg', 'kilogram', 'kilograms', 'oz', 'ounce', 'ounces', 'lb', 'pound', 'pounds'};
    const volumeUnits = {'ml', 'milliliter', 'milliliters', 'l', 'liter', 'liters', 'cup', 'cups', 'tsp', 'teaspoon', 'teaspoons', 'tbsp', 'tablespoon', 'tablespoons', 'fl oz', 'fluid ounce', 'fluid ounces'};
    const countUnits = {'', 'item', 'items', 'piece', 'pieces', 'unit', 'units', 'pcs', 'pc'};
    const lengthUnits = {'cm', 'centimeter', 'centimeters', 'm', 'meter', 'meters', 'inch', 'inches', 'in'};
    
    // Check if both units belong to the same category
    final isUnit1Weight = weightUnits.contains(normalized1);
    final isUnit2Weight = weightUnits.contains(normalized2);
    final isUnit1Volume = volumeUnits.contains(normalized1);
    final isUnit2Volume = volumeUnits.contains(normalized2);
    final isUnit1Count = countUnits.contains(normalized1);
    final isUnit2Count = countUnits.contains(normalized2);
    final isUnit1Length = lengthUnits.contains(normalized1);
    final isUnit2Length = lengthUnits.contains(normalized2);
    
    // Units are compatible if they belong to the same category
    return (isUnit1Weight && isUnit2Weight) ||
           (isUnit1Volume && isUnit2Volume) ||
           (isUnit1Count && isUnit2Count) ||
           (isUnit1Length && isUnit2Length);
  }

  // Add new item to grocery list with duplicate checking
  Future<void> _addItem() async {
    final user = _auth.currentUser;
    if (user == null || _itemController.text.trim().isEmpty) return;

    final String name = _itemController.text.trim().toLowerCase();
    final String originalName = _itemController.text.trim();
    final String quantity = _quantityController.text.trim().isEmpty ? '1' : _quantityController.text.trim();
    final String unit = _unitController.text.trim();
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
        // Item exists - update quantity instead of creating new one
        final existingDoc = existingItemsQuery.docs.first;
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final double existingAmount = _parseQuantity(existingData['amount'] ?? '1');
        final String existingUnit = (existingData['unit'] ?? '').toString().toLowerCase().trim();
        final String existingCategory = existingData['category'] ?? 'Other';
        
        // Check if units and categories are compatible for merging
        if (_areUnitsCompatible(existingUnit, unit) && existingCategory == category) {
          // Merge quantities - units and categories match
          final double newAmount = _parseQuantity(quantity);
          final double mergedAmount = existingAmount + newAmount;
          final String displayUnit = existingUnit.isNotEmpty ? existingUnit : unit;
          
          await existingDoc.reference.update({
            'amount': mergedAmount.toString(),
            'unit': displayUnit,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated quantity of $originalName to $mergedAmount $displayUnit'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Units or categories are incompatible - add as new item with note
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('grocery_list')
              .add({
            'name': name,
            'originalName': originalName,
            'amount': quantity,
            'unit': unit,
            'category': category,
            'isChecked': false,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'note': 'Different ${existingUnit != unit ? 'unit' : 'category'} from existing item',
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $originalName (different ${existingUnit != unit ? 'unit' : 'category'})'),
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
          'amount': quantity,
          'unit': unit,
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
      _unitController.clear();
      
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: isDarkMode ? const Color(0xFFE1E1E1) : Colors.grey[600],
          ),
          onPressed: () => _showDeleteDialog(doc.id, name),
        ),
      ),
    );
  }

  // Get color for category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fruits':
        return const Color(0xFF4CAF50);
      case 'Vegetables':
        return const Color(0xFF8BC34A);
      case 'Protein':
        return const Color(0xFFF44336);
      case 'Dairy':
        return const Color(0xFFFFC107);
      case 'Grains':
        return const Color(0xFF795548);
      case 'Beverages':
        return const Color(0xFF2196F3);
      case 'Snacks':
        return const Color(0xFFFF9800);
      case 'Spices':
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
                    
                    // Unit Field
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _unitController,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                            hintText: 'pieces, kg, cups...',
                            hintStyle: TextStyle(color: hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: Icon(
                              Icons.straighten_outlined,
                              color: accentColor,
                              size: 18,
                            ),
                          ),
                          style: TextStyle(color: textColor, fontSize: 16),
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
        currentIndex: 2, // Adjust index based on your nav bar
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