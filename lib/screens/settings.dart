import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dishes.dart';
import 'inventory_screen.dart';
import 'expiring.dart';
import 'home.dart';
import 'languages.dart';
import 'navbar.dart';
import 'homepage.dart';
import 'account_screen.dart'; // Import ProfileCheck

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS (Consistent with account_screen.dart) ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5); 
const Color _kLogoutRed = Color(0xFFE57373); // Red color for logout button
// --------------------------------------------------------------------------


class Setting_menu extends StatefulWidget {
  const Setting_menu({super.key});
  @override
  _Setting_menuState createState() => _Setting_menuState();
}

class _Setting_menuState extends State<Setting_menu> {
  // State variables for toggles
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;

  // Helper method to navigate to a new screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Helper method for navigation where the old history isn't needed (like Home)
  void _navigateHome(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text(
                  'Logout',
                  style: TextStyle(color: _kLogoutRed),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      // If user confirms logout
      if (shouldLogout == true) {
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

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Navigate to homepage and clear all routes
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: _kScreenBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sleek Header Section (Consistent with account_screen.dart)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Functional)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
                    ),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 34), // Spacer
                  ]
                ),
              ),
              const Divider(color: _kSearchBorderColor, thickness: 1.5, height: 0),
                            
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card Section
                      _ProfileCard(
                        onTap: () => _navigateTo(context, const ProfileCheck()),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Settings Section Title
                      const Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 10),
                        child: Text(
                          "Preferences",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Language Tile
                      _SettingsTile(
                        label: "Language",
                        icon: Icons.language,
                        onTap: () => _navigateTo(context, const Lang()),
                      ),
                      
                      // Dark Mode Tile with Switch
                      _SettingsTile(
                        label: "Dark Mode",
                        icon: Icons.dark_mode,
                        trailing: Switch(
                          value: _darkModeEnabled,
                          onChanged: (bool newValue) {
                            setState(() {
                              _darkModeEnabled = newValue;
                            });
                          },
                          activeColor: _kButtonColor,
                        ),
                        onTap: () {
                          // Toggle on tap of the whole tile area
                          setState(() {
                            _darkModeEnabled = !_darkModeEnabled;
                          });
                        },
                      ),

                      // Notifications Tile with Switch
                      _SettingsTile(
                        label: "Notifications",
                        icon: Icons.notifications,
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (bool newValue) {
                            setState(() {
                              _notificationsEnabled = newValue;
                            });
                          },
                          activeColor: _kButtonColor,
                        ),
                        onTap: () {
                          // Toggle on tap of the whole tile area
                          setState(() {
                            _notificationsEnabled = !_notificationsEnabled;
                          });
                        },
                      ),

                      // The 'About' Tile has been REMOVED as requested.

                      const SizedBox(height: 30),
                      
                      // Account Section Title
                      const Padding(
                        padding: EdgeInsets.only(left: 10, bottom: 10),
                        child: Text(
                          "Account",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Logout Tile - Added with red color
                      _LogoutTile(
                        onTap: () => _logout(context),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Profile Card with User Info ---
// --------------------------------------------------------------------------
class _ProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kButtonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _kButtonColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _kButtonColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 15),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Name
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null 
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String displayName = 'User';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        displayName = userData?['displayName'] ?? user?.displayName ?? 'User';
                      }
                      
                      return Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    user?.email ?? 'No email',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Tap to view profile text
                  Text(
                    'Tap to view profile',
                    style: TextStyle(
                      color: _kButtonColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron Icon
            Icon(
              Icons.arrow_forward_ios,
              color: _kButtonColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Reusable Settings Tile (Unchanged design) ---
// --------------------------------------------------------------------------
class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSubtleGray,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(icon, color: _kButtonColor, size: 28),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
            // Show a chevron if it's a navigational tile and no custom trailing widget is provided
            if (trailing == null && onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Logout Tile with Red Styling ---
// --------------------------------------------------------------------------
class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kLogoutRed.withOpacity(0.1), // Light red background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _kLogoutRed.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(Icons.logout, color: _kLogoutRed, size: 28),
            const SizedBox(width: 20),
            Text(
              "Logout",
              style: TextStyle(
                color: _kLogoutRed,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: _kLogoutRed.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Bottom Navigation Bar (Consistent Implementation) ---
// --------------------------------------------------------------------------
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _NavBarItem({
    required this.icon,
    this.onTap,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 45,
        height: 45,
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  final Function(BuildContext, Widget) navigateTo;
  final Function(BuildContext, Widget) navigateHome;
  final VoidCallback navigateToProfile;
  final IconData activeIcon;

  const _BottomNavigationBar({
    required this.navigateTo,
    required this.navigateHome,
    required this.navigateToProfile,
    this.activeIcon = Icons.home, // Default to home if not specified
  });

  @override
  Widget build(BuildContext context) {
    // Define the list of navigation items
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home, 'onTap': () => navigateHome(context, const MainHomeScreen())},
      {'icon': Icons.search, 'onTap': () => navigateTo(context, const RecipeApp())},
      {'icon': Icons.add_circle, 'onTap': () => navigateTo(context, const InventoryCategoriesScreen())},
      {'icon': Icons.delete_outline, 'onTap': () => navigateTo(context, const ExpiringItemsScreen())},
      {'icon': Icons.person, 'onTap': navigateToProfile},
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: _kScreenBackgroundColor,
        border: Border(
          top: BorderSide(
            width: 1,
            color: _kSearchBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            bool isActive = item['icon'] == activeIcon;
            return _NavBarItem(
              icon: item['icon'] as IconData,
              color: isActive ? _kButtonColor : Colors.black,
              onTap: isActive ? null : item['onTap'] as VoidCallback,
            );
          }).toList(),
        ),
      ),
    );
  }
}