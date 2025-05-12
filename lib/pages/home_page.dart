import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_screen.dart';
import 'package:studyflow_v2/pages/flashcard_screen.dart';
import 'package:studyflow_v2/pages/home_screen.dart';
import 'package:studyflow_v2/pages/note_screen.dart';
import 'package:studyflow_v2/pages/user_settings.dart';
import 'package:studyflow_v2/states/group_state.dart';
import 'package:studyflow_v2/states/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

bool inGroup = false;

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is terminating
      _handleAppExit();
    }
  }

  void _handleAppExit() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // clear any previous group state
      Provider.of<GroupState>(context, listen: false).leaveGroup();

      // then update to the new user (or null)
      Provider.of<GroupState>(context, listen: false).updateCurrentUser(user);
    });
  }

  // Dialog to create/join group:
  void _showGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkerSecondaryColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkerSecondaryColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<HomeState>().toggleIsSomething();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        groupId: "123123123",
                      ),
                    ),
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'Create New Group',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: primaryColor,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: primaryColor,
                          ),
                        ),
                        labelText: 'Enter group code',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: darkerSecondaryColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'Join',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Pages with injected onFab behavior:
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
