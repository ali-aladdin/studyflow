import 'package:flutter/material.dart';
import 'package:studyflow/pages/home_screen.dart';
import 'package:studyflow/pages/flashcards_screen.dart';
import 'package:studyflow/pages/notes_screen.dart';
import 'package:studyflow/pages/settings_screen.dart';
import 'package:studyflow/utilities/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages corresponding to each bottom navigation item.
  final List<Widget> _pages = const [
    HomeScreen(), // Group Chat Sessions page
    FlashcardsScreen(), // Flashcards page
    NotesScreen(), // Notes page
    SettingsScreen(), // Settings page
  ];

  // The Floating Action Button (FAB) action depends on the current page.
  void _onPlusPressed() {
    String action;
    switch (_selectedIndex) {
      case 0:
        action = 'Create/Join Group';
        break;
      case 1:
        action = 'Add Flashcard';
        break;
      case 2:
        action = 'Add Note';
        break;
      case 3:
        action = 'Edit Settings'; // example, adjust as needed
        break;
      default:
        action = 'Action';
        break;
    }
    // For now, just display a Snackbar indicating the action.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _onPlusPressed,
        backgroundColor: AppColors.secondaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
