// lang.dart
import 'package:flutter/material.dart';
import 'dishes.dart';
import 'inventory_screen.dart';
import 'expiring.dart';
import 'home.dart';

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS (Consistent with account_screen.dart) ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5); 
// --------------------------------------------------------------------------


class Lang extends StatefulWidget {
	const Lang({super.key});
	@override
		LangState createState() => LangState();
	}

class LangState extends State<Lang> {
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
											"Language",
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
											// Only English is available and selected (as requested)
											_LanguageSelectionTile(
												language: "English",
												isSelected: true,
												onTap: () {
													debugPrint('English is already selected and cannot be deselected.');
												},
											),
											// All other language options are removed
										],
									)
								),
							),
						],
					),
				),
			),
      // bottomNavigationBar: _BottomNavigationBar(
      //   navigateTo: _navigateTo,
      //   navigateHome: _navigateHome,
      //   // Active Profile Icon in the Nav Bar for this screen
      //   navigateToProfile: () => _navigateTo(context, const ProfileNSettings()),
      //   activeIcon: Icons.person,
      // ),
		);
	}
}

// --------------------------------------------------------------------------
// --- WIDGET: Language Selection Tile (New) ---
// --------------------------------------------------------------------------
class _LanguageSelectionTile extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageSelectionTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _kButtonColor : _kSubtleGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kButtonColor : _kSubtleGray,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _kButtonColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------------------------------
// --- WIDGET: Bottom Navigation Bar (Consistent Implementation) ---
// Note: Copied from abc.dart
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
    this.activeIcon = Icons.home,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home, 'onTap': () => navigateHome(context, const MainAppScreen())},
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