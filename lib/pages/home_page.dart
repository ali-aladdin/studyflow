import 'package:flutter/material.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/flashcard_screen.dart';
import 'package:studyflow_v2/pages/home_screen.dart';
import 'package:studyflow_v2/pages/note_screen.dart';
import 'package:studyflow_v2/pages/user_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

bool inGroup = false;

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.detached) {
  //     //? app is terminating
  //     _handleAppExit();
  //   }
  // }

  // void _handleAppExit() {
  //   FirebaseAuth.instance.authStateChanges().listen((user) {
  //     //? then update to the new user (or null)
  //     Provider.of<GroupState>(context, listen: false).updateCurrentUser(user);
  //   });
  // }

  final List<Widget> _pages = [
    const HomeScreen(),
    const NotesScreen(),
    const FlashcardsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        iconSize: 35,
        backgroundColor: secondaryColor,
        selectedItemColor: textColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_filled,
              color: textColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_book_rounded,
              color: textColor,
            ),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.credit_card,
              color: textColor,
            ),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
              color: textColor,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
