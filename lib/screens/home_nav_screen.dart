import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/app_theme.dart';
import 'add_subscription_screen.dart';
import 'dashboard_screen.dart';
import 'edit_subscription_screen.dart';
import 'profile_screen.dart';

/// App Host Screen with Fixed Bottom Navigation Bar (4 Main Pages)
/// 1. Dashboard
/// 2. Add Subscription
/// 3. Edit Subscription
/// 4. Profile
class HomeNavScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final bool isDarkMode;

  const HomeNavScreen({
    super.key,
    this.toggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  // Simple integer variable to keep track of active tab (lecturer style)
  int currentIndex = 0;
  Subscription? selectedSubscription;

  // Simple function to switch tabs using setState
  void changeTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  // Master/Detail: Navigate directly to Edit screen with selected subscription
  void openEditSubscription(Subscription sub) {
    setState(() {
      selectedSubscription = sub;
      currentIndex = 2; // Switch to Edit Subscription tab
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4 Main Screens of the application
    final List<Widget> screens = [
      DashboardScreen(
        onNavigateTab: changeTab,
        onEditSubscription: openEditSubscription,
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      AddSubscriptionScreen(
        onSubscriptionSaved: () => changeTab(0), // return to dashboard after saving
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      EditSubscriptionScreen(
        initialSubscriptionToEdit: selectedSubscription,
        onClearedSelection: () {
          setState(() {
            selectedSubscription = null;
          });
        },
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      ProfileScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Add Sub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note_rounded),
            label: 'Edit Sub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
