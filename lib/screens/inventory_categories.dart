import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_screen.dart';

// --- Data Models ---
class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final String? purchaseDate;
  final String? expiryDate;
  final DateTime createdAt;
  final String userId;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.purchaseDate,
    this.expiryDate,
    required this.createdAt,
    required this.userId,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] is String) 
          ? int.tryParse(data['quantity']) ?? 0 
          : (data['quantity'] ?? 0).toInt(),
      unit: data['unit'] ?? 'pieces',
      category: data['category'] ?? 'Uncategorized',
      purchaseDate: data['purchaseDate'],
      expiryDate: data['expiryDate'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Helper method to calculate days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference;
    } catch (e) {
      return null;
    }
  }

  // Helper method to get expiry display text
  String get expiryDisplay {
    final days = daysUntilExpiry;
    if (days == null) return 'No expiry';
    if (days < 0) return 'Expired ${days.abs()} days ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day';
    return '$days days';
  }

  // Helper method to get background color based on category
  Color get backgroundColor {
    switch (category.toLowerCase()) {
      case 'fruit':
        return const Color(0xFF5C8A94);
      case 'vegetable':
        return const Color(0xFF5C8A94);
      case 'meat':
        return const Color(0xFF5C8A94);
      case 'dairy':
        return const Color(0xFF5C8A94);
      case 'grains':
        return const Color(0xFF5C8A94);
      case 'beverages':
        return const Color(0xFF5C8A94);
      default:
        return const Color(0xFF5C8A94);
    }
  }
}

// --- Main Inventory Screen Widget ---
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late Stream<QuerySnapshot> _inventoryStream;
  Color? _categoryColor;

  @override
  void initState() {
    super.initState();
    _inventoryStream = _getCategoryItems();
    _categoryColor = _getCategoryColor(widget.category);
  }

  Stream<QuerySnapshot> _getCategoryItems() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .where('category', isEqualTo: widget.category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return const Color(0xFF5C8A94);
      case 'vegetable':
        return const Color(0xFF5C8A94);
      case 'meat':
        return const Color(0xFF5C8A94);
      case 'dairy':
        return const Color(0xFF5C8A94);
      case 'grains':
        return const Color(0xFF5C8A94);
      case 'beverages':
        return const Color(0xFF5C8A94);
      default:
        return const Color(0xFF5C8A94);
    }
  }

  // Delete item function
  Future<void> _deleteItem(InventoryItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(item.id)
          .delete();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ${item.name}: $e'),
            backgroundColor: Color.fromARGB(255, 144, 11, 9),
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(item);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color.fromARGB(255, 144, 11, 9)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper function for navigating to AddItemScreen
  void _navigateToAddItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
  }

  // Widget for a single list item
  Widget _buildInventoryItem(BuildContext context, InventoryItem item) {
    Color expiryColor = Colors.grey;
    if (item.daysUntilExpiry != null) {
      if (item.daysUntilExpiry! < 0) {
        expiryColor = Colors.red;
      } else if (item.daysUntilExpiry! <= 3) {
        expiryColor = Colors.orange;
      } else if (item.daysUntilExpiry! <= 7) {
        expiryColor = Colors.yellow[700]!;
      } else {
        expiryColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 144, 11, 9)),
                          onPressed: () => _showDeleteDialog(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 34,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Quantity: ${item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        // const SizedBox(width: 10),
                        // Text(
                        //   'Expires: ${item.expiryDisplay}',
                        //   style: TextStyle(
                        //     fontSize: 14,
                        //     color: expiryColor,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                    // const SizedBox(height: 4),
                    // Text(
                    //   'Category: ${item.category}',
                    //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the Search Bar with Navigation
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 24.0),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToAddItem(context),
              child: Text(
                'Search Item in ${widget.category}',
                style: TextStyle(color: Colors.grey[600], fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 28.0,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Plus Button (Navigates to AddItemScreen)
                  IconButton(
                    icon: const Icon(Icons.add, size: 32.0, color: Colors.black),
                    onPressed: () => _navigateToAddItem(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar(context)),
                  const SizedBox(width: 8.0),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Curved Background and List
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _inventoryStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 64, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Text(
                                'No items found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add some ${widget.category.toLowerCase()} to your inventory',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _navigateToAddItem(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _categoryColor,
                                ),
                                child: const Text('Add Item'),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = snapshot.data!.docs
                          .map((doc) => InventoryItem.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildInventoryItem(context, items[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Updated Detail Screen with Delete Option ---
class ItemDetailScreen extends StatelessWidget {
  final InventoryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 144, 11, 9)),
            onPressed: () => _showDeleteDialog(context, item),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.inventory_2, size: 40, color: item.backgroundColor),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.category),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Quantity', '${item.quantity} ${item.unit}'),
                    _buildDetailRow('Purchase Date', item.purchaseDate ?? 'Not set'),
                    _buildDetailRow('Expiry Date', item.expiryDate ?? 'Not set'),
                    _buildDetailRow('Expires In', item.expiryDisplay),
                    _buildDetailRow('Added On', 
                      '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(context, item);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color.fromARGB(255, 144, 11, 9)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, InventoryItem item) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(item.id)
          .delete();
      
      Navigator.of(context).pop(); // Go back to previous screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting ${item.name}: $e'),
          backgroundColor: Color.fromARGB(255, 144, 11, 9),
        ),
      );
    }
  }
}

// --- Usage Example ---
class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Manager',
      debugShowCheckedModeBanner: false,
      home: InventoryScreen(
        category: 'Fruit', // Only parameter needed - the rest is automatic
      ),
    );
  }
}