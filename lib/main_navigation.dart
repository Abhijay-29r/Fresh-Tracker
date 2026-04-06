import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'shopping_list_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // The two screens we want to switch between
  final List<Widget> _screens = [
    const HomeScreen(),
    const ShoppingListScreen(),
    const HistoryScreen(),
    const StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green,
        type: BottomNavigationBarType
            .fixed, // Ensure icons stay put with 3+ items
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Pantry'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Stats'), // 3. Add the item
        ],
      ),
    );
  }
}
