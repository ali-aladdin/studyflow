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

  final List<Widget> _pages = const [
    HomeScreen(), // Home page (Group Chat Sessions)
    NotesScreen(), // Notes page
    FlashcardsScreen(), // Flashcards page
    SettingsScreen(), // Settings page
  ];

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
        action = 'Edit Settings';
        break;
      default:
        action = 'Action';
        break;
    }
    // For demonstration, we'll show a Snackbar indicating the action.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action)),
    );
  }

  // When a non-add nav bar item is tapped, update the page.
  void _onItemTapped(int index) {
    // The Add button is at index 2. For other indexes, adjust the mapping:
    // If tapped index is less than 2, it maps directly.
    // If tapped index is greater than 2, subtract 1 because our _pages list is of length 4.
    if (index == 2) {
      _onPlusPressed();
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index < 2 ? index : index - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        iconSize: 35,
        backgroundColor: AppColors.secondaryColor,
        selectedItemColor: AppColors.textColor,
        unselectedItemColor: AppColors.primaryColor,
        currentIndex: _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
              size: 50,
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
