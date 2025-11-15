import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// The primary color derived from the selected 'Vegetable' pill in the screenshot
const Color primaryColor = Color(0xFF5B8A8A);
const Color backgroundColor = Color(0xFFFFFFFF);
// The light gray background color for input fields and unselected pills
const Color cardColor = Color(0xFFF0F0F0);

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // State variable to hold the currently selected category (null if none selected)
  String? _selectedCategory;
  
  // State variable to hold the currently selected quantity unit
  String _selectedUnit = 'units';
  
  // Text editing controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _categoryOptions = [
    'Fruit',
    'Protein',
    'Vegetable',
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
    'liters'
  ];

  // Save item to Firebase
  Future<void> _saveItemToInventory() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog('Authentication Error', 'Please log in to add items.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Missing Information', 'Item name is required.');
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Prepare item data
      final itemData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'quantity': _quantityController.text.trim().isNotEmpty 
            ? _quantityController.text.trim() 
            : null,
        'unit': _selectedUnit,
        'purchaseDate': _purchaseDateController.text.trim().isNotEmpty
            ? _purchaseDateController.text.trim()
            : null,
        'expiryDate': _expiryDateController.text.trim().isNotEmpty
            ? _expiryDateController.text.trim()
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid, // Store user ID for security rules
      };

      // Remove null values from the map
      itemData.removeWhere((key, value) => value == null);

      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .add(itemData);

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message and go back
      _showSuccessDialog();
      
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorDialog('Error', 'Failed to save item: $e');
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Item added to inventory successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to consistently style section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper widget for standard text inputs (Name, Date, Notes)
  Widget _buildCustomTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            // Styling for the rounded border that matches the design
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              // Highlight the border when focused
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // Section for category selection (using InkWell and Container for custom styling)
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Category'),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _categoryOptions.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () {
                // Allows only one category to be selected at a time
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Section for Quantity (Number input + Unit Dropdown)
  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quantity'),
        Row(
          children: [
            // Quantity number input
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: primaryColor, width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Unit dropdown
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _unitOptions.map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(
                        unit,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
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
                  style: const TextStyle(fontSize: 16),
                  isExpanded: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Category Selection
              _buildCategorySection(),
              const SizedBox(height: 30),

              // 2. Name (Required field)
              _buildCustomTextField(
                label: 'Name',
                hintText: 'eg. Apple',
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 30),

              // 3. Quantity (Number input + Unit Dropdown)
              _buildQuantitySection(),
              const SizedBox(height: 30),

              // 4. Purchase Date
              _buildCustomTextField(
                label: 'Purchase Date',
                hintText: 'YY-MM-DD',
                controller: _purchaseDateController,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 30),

              // 5. Expiry Date
              _buildCustomTextField(
                label: 'Expiry Date',
                hintText: 'YY-MM-DD',
                controller: _expiryDateController,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 30),

              // 6. Notes
              _buildCustomTextField(
                label: 'Notes',
                hintText: '...',
                controller: _notesController,
                maxLines: 5,
              ),
              const SizedBox(height: 40),

              // 7. Add Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _saveItemToInventory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchaseDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}