import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:logger/logger.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // from flutterfire configure

//! INDEXES to navigate more easily to certain code blocks
final StatelessWidget mainPage = MyApp(key: UniqueKey());
final StatefulWidget signInPage = SignInPage(key: UniqueKey());
final StatefulWidget signUpPage = SignUpPage(key: UniqueKey());
final StatefulWidget forgotPasswordPage = ForgotPasswordPage(key: UniqueKey());
final StatefulWidget homePage = HomePage(key: UniqueKey());
final StatelessWidget homeScreenPage = HomeScreen(key: UniqueKey());
final StatefulWidget notesPage = NotesScreen(key: UniqueKey());
final StatefulWidget flashcardsPage = FlashcardsScreen(key: UniqueKey());
final StatefulWidget groupChatPage = ChatPage(
    classGroupName: "nothing", classGroupCode: "nothing", key: UniqueKey());
final StatefulWidget settingsPage = SettingsScreen(key: UniqueKey());
//! END OF INDEXES

final logger = Logger(); //! To log better

//! Firebase instances
final users = FirebaseFirestore.instance.collection('users');

//* PREFERED LAYOUTS AND DESIGNS
/*



//! buttons
  ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SomeWhere()),
      );
    },
    style: ElevatedButton.styleFrom(
      foregroundColor: primaryColor,
      backgroundColor: secondaryColor,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text('Something'),
  ),

//! more buttons
  SizedBox(
    height: 35,
    width: 50,
    child: Container(
      height: 30,
      decoration: BoxDecoration(
        color: darkerSecondaryColor, // Your desired color
        borderRadius: BorderRadius.circular(
            8.0), // Optional rounded corners
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Join',
          style: TextStyle(
            fontSize: 10,
            color: textColor,
          ),
        ),
      ),
    ),
  ),  

//! search field
  child: TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintText: 'search for notes',
      prefixIcon: const Icon(Icons.search),
    ),
  ),


//! some font styles
  style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 26,
  ),

//! row or column with flexible
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Flexible(
        flex: 2,
        ...
      ),
      SizedBox(
        width: ...,
      ),
      Flexible(
        flex: 5,
        ...
      ),
    ],
  ),
*/

//* COMMONLY USED CODES
/*

  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => SomeWhere()),
  );


*/

//? -------------------------------------------
//? colors that will be used throughout the app
//? -------------------------------------------
const Color primaryColor = Color(0xffF0F4F7);
const Color secondaryColor = Color(0xffF4D869);
const Color darkerSecondaryColor = Color.fromARGB(255, 226, 197, 82);
const Color textColor = Color(0xff1E1E1E);
const Color elementColor = Color(0xffD9D9D9);
const Color warningErrorColor = Color.fromARGB(255, 240, 42, 42);
//! ---------------------
//! END OF COLORS SECTION
//! ---------------------

//? ---------------------------------------------
//? state class for global accessing of variables
//? and detecting changes in state
//? ---------------------------------------------
//* usage:
//* READ:  final dtype var = context.watch<varState>().var;
//* WRITE: context.read<varState>().methodName();
/*
 * and use this instead of initState()
 * @override
 * void didChangeDependencies() {
 *   super.didChangeDependencies();
 *   .. context.watch<varState>().var;
 *   .. context.watch<varState>().var;
 * }
*/

/*
 *
 */
class HomeState extends ChangeNotifier {
  bool _inGroup = false;

  bool get inGroup => _inGroup;

  void toggleIsSomething() {
    _inGroup = !_inGroup;
    notifyListeners();
  }
}

class GroupState extends ChangeNotifier {
  String? _groupName;
  String? _groupCode;
  final List<String> _messages = [];
  final List<String> _members = []; // Added _members variable

  String? get groupName => _groupName;
  String? get groupCode => _groupCode;
  List<String> get messages => _messages;
  List<String> get members => _members; // Added getter for _members

  void setName(String name) {
    _groupName = name;
  }

  void setCode(String code) {
    _groupCode = code;
  }

  void sendMessage(String msg) {
    _messages.add(msg);
    notifyListeners();
  }

  // You might want to add methods to manage the members list, e.g., addMember, removeMember
  void addMember(String member) {
    _members.add(member);
    notifyListeners();
  }

  void removeMember(String member) {
    _members.remove(member);
    notifyListeners();
  }
}

class NoteState extends ChangeNotifier {
  final List<Note> _notes = [
    Note(id: '1', title: 'Math Summary', content: 'Here are some formulas...'),
    Note(id: '2', title: 'Chemistry', content: 'Atomic structure and...'),
    Note(id: '3', title: 'History', content: 'World War II timeline...'),
  ];

  List<Note> get notes => _notes;

  void addNote(Note newNote) {
    _notes.add(newNote);
    notifyListeners();
  }

  void deleteNote(Note noteToDelete) {
    _notes.remove(noteToDelete);
    notifyListeners();
  }

  void editTitle(String id, String newTitle) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(title: newTitle);
      notifyListeners();
    }
  }

  void editContent(String id, String newContent) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(content: newContent);
      notifyListeners();
    }
  }
}

class FlashcardState extends ChangeNotifier {
  final List<Flashcard> _cards = [
    Flashcard(id: '1', title: 'Pythagorean Theorem', content: 'a² + b² = c²'),
    Flashcard(id: '2', title: 'Newton’s Second Law', content: 'F = m · a'),
    Flashcard(id: '3', title: 'Ohm’s Law', content: 'V = I · R'),
  ];

  List<Flashcard> get cards => _cards;

  void addCard(Flashcard newCard) {
    _cards.add(newCard);
    notifyListeners();
  }

  void deleteCard(Flashcard cardToDelete) {
    _cards.remove(cardToDelete);
    notifyListeners();
  }

  void editCardTitle(String id, String newTitle) {
    final index = _cards.indexWhere((card) => card.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(title: newTitle);
      notifyListeners();
    }
  }

  void editCardContent(String id, String newContent) {
    final index = _cards.indexWhere((card) => card.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(content: newContent);
      notifyListeners();
    }
  }
}
//! -------------------------------
//! END OF STATE MANAGEMENT SECTION
//! -------------------------------

//? ------------------------------------------
//? classes section that'll aid in development
//* this will be deprecated later when we have
//* an actual backend setup and ready
//? ------------------------------------------
class AppUser {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'createdAt': createdAt,
    };
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  bool pinned;
  Note(
      {required this.id,
      required this.title,
      required this.content,
      this.pinned = false});

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? pinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
    );
  }
}

class Flashcard {
  final String id;
  final String title;
  final String content;
  bool pinned;
  Flashcard({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
  });
  Flashcard copyWith({
    String? id,
    String? title,
    String? content,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
//! ----------------------
//! END OF CLASSES SECTION
//! ----------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeState>(
          create: (_) => HomeState(),
        ),
        ChangeNotifierProvider<NoteState>(
          create: (_) => NoteState(),
        ),
        ChangeNotifierProvider<FlashcardState>(
          create: (_) => FlashcardState(),
        ),
        ChangeNotifierProvider<GroupState>(
          create: (_) => GroupState(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: primaryColor,
            scaffoldBackgroundColor: primaryColor,
            appBarTheme: AppBarTheme(
              foregroundColor: textColor,
            )),
        home: SignUpPage(),
      ),
    );
  }
}
//! -----------
//! END OF MAIN
//! -----------

//? --------------------
//? authentication pages
//? --------------------
//? ------------------------------------------
//? splash screen, the first screen in our app
//? ------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 15),
            Text(
              'StudyFlow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: secondaryColor,
              strokeWidth: 6,
            ),
          ],
        ),
      ),
    );
  }
}
//! --------------------
//! END OF SPLASH SCREEN
//! --------------------

//? ------------
//? sign in page
//? ------------
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _userPassword = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/signinlogoandtext.png',
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                        color: textColor,
                      )),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _userPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                        color: textColor,
                      )),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: secondaryColor,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _userPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _userPassword = !_userPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        checkColor: primaryColor,
                        activeColor: secondaryColor,
                        side: BorderSide(
                          color: secondaryColor,
                          width: 2.0,
                        ),
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO
                      /*
                      if (_formKey.currentState!.validate()) {
                        // Handle sign up action
                      }
                      */

                      //! delete later
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//! -------------------
//! END OF SIGN IN PAGE
//! -------------------

//? --------------------
//? forgot password page
//? --------------------
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final bool _isSending = false;

  //! FOR LATER USE
  /*
  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent—check your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => {},
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Email'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
//! ---------------------------
//! END OF FORGOT PASSWORD PAGE
//! ---------------------------

//? ------------
//? sign up page
//? ------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _userPassword = true;

  Future<void> handleSignUp() async {
    // try {
    //   final users = FirebaseFirestore.instance.collection('users');
    //   final query = await users
    //       .where('username', isEqualTo: _usernameController.text)
    //       .get();
    //   if (query.docs.isEmpty) {
    //     logger.i("No similar username");
    //   }
    // } catch (e, stackTrace) {
    //   logger.e("Firestore error: $e and $stackTrace");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/signuplogoandtext.png',
                    width: 190,
                    height: 190,
                  ),
                  const SizedBox(height: 24),
                  // Email Input Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Username Input Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password Input Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _userPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: textColor,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: textColor,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: secondaryColor,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _userPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _userPassword = !_userPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: handleSignUp,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  // Already Registered Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already registered?',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignInPage()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//! -------------------
//! END OF SIGN UP PAGE
//! -------------------
//! ---------------------------
//! END OF AUTHENTICATION PAGES
//! ---------------------------

//? ----------------------------------------------
//? the home page that the app will revolve around
//? ----------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

bool inGroup = false;

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController __groupCodeInput = TextEditingController();

  //! UTILITY FUNCTIONS
  List<String> adjectives = [
    "Bold",
    "Fearless",
    "United",
    "Strong",
    "Luminous",
    "Epic"
  ];
  List<String> nouns = [
    "Warriors",
    "Explorers",
    "Dreamers",
    "Innovators",
    "Pioneers",
    "Voyagers"
  ];

  String generateRandom_GroupName() {
    Random random = Random();
    String adjective = adjectives[random.nextInt(adjectives.length)];
    String noun = nouns[random.nextInt(nouns.length)];

    return "$adjective$noun";
  }

  String generateRandom_GroupCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    return code;
  }

  //! END OF UTILITY FUNCTIONS

  // Dialog to create/join group:
  void _showGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
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
                        classGroupName: generateRandom_GroupName(),
                        classGroupCode: generateRandom_GroupCode(),
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
                      controller: __groupCodeInput,
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

  void _onPlusPressed() {
    switch (_selectedIndex) {
      case 0: // Home
        _showGroupDialog();
        break;
      case 1: // Notes
        break;
      case 3: // Flashcards
        break;
      default:
        // unexisting index
        return;
    }
  }

  void _onItemTapped(int index) {
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
        showUnselectedLabels: false,
        iconSize: 35,
        backgroundColor: secondaryColor,
        selectedItemColor: textColor,
        currentIndex: _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1,
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
              Icons.add_circle_outline,
              size: 50,
              color: textColor,
            ),
            label: 'Add',
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
//! ----------------
//! END OF HOME PAGE
//! ----------------

//? ----------------------------------------------------------
//? the home screen that's the first item in the bottom navbar
//? ----------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool inGroup = context.watch<HomeState>().inGroup;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
      ),
      body: Center(
        child: inGroup ? Text('In Group') : Text('Not In Group'),
      ),
    );
  }
}
//! ------------------
//! END OF HOME SCREEN
//! ------------------

//? -------------------------------------------------------------
//? the notes section that's the second item in the bottom navbar
//? -------------------------------------------------------------
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // replace with your real data fetch
  // final List<Note> _notes = [
  //   Note(id: '1', title: 'Math Summary', content: 'Here are some formulas...'),
  //   Note(id: '2', title: 'Chemistry', content: 'Atomic structure and...'),
  //   Note(id: '3', title: 'History', content: 'World War II timeline...'),
  // ];

  @override
  Widget build(BuildContext context) {
    // Make a copy and sort so pinned are first
    final notes = List<Note>.from(context.watch<NoteState>().notes)
      ..sort((a, b) {
        if (a.pinned == b.pinned) return 0;
        return a.pinned ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: elementColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'search for notes',
                hintStyle: TextStyle(
                  color: textColor,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final preview = note.content.length > 50
              ? '${note.content.substring(0, 50)}…'
              : note.content;

          return Card(
            color: elementColor,
            margin: EdgeInsets.all(8.0), // Margin around the Card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
            ),
            child: ListTile(
              title: Text(
                note.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                preview,
                style: TextStyle(
                  color: textColor,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      note.pinned ? Icons.favorite : Icons.favorite_border,
                      color: note.pinned ? Colors.red : textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        note.pinned = !note.pinned;
                        // TODO: persist pin state back to Firestore
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: textColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteEditPage(note: note),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoteEditPage extends StatelessWidget {
  final Note note;
  const NoteEditPage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: const Text(
          'Edit Note',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // saveNote(); // TODO
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: textColor,
            ),
            onPressed: () {
              // TODO: delete note
              Navigator.of(context).pop();
            },
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    flex: 2,
                    child: Text(
                      "Note Title",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    flex: 5,
                    child: TextFormField(
                      controller: titleController,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: darkerSecondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Expanded(
          child: TextFormField(
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            controller: contentController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//! --------------------
//! END OF NOTES SECTION
//! --------------------

//? -----------------------------------------------------------------
//? the flashcards section that's the third item in the bottom navbar
//? -----------------------------------------------------------------
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  // replace with your real data fetch

  @override
  Widget build(BuildContext context) {
    // Copy and sort so pinned first
    final cards = List<Flashcard>.from(context.watch<FlashcardState>().cards)
      ..sort((a, b) {
        if (a.pinned == b.pinned) return 0;
        return a.pinned ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Flashcards',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: elementColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'search for flashcards',
                hintStyle: TextStyle(
                  color: textColor,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Card(
              color: elementColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(card.title),
                      content: Text(card.content),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            card.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              card.pinned
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: card.pinned ? Colors.red : textColor,
                            ),
                            onPressed: () {
                              setState(() {
                                card.pinned = !card.pinned;
                                // TODO: persist pin state back to Firestore
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: textColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FlashcardEditPage(card: card),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FlashcardEditPage extends StatelessWidget {
  final Flashcard card;
  const FlashcardEditPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: card.title);
    final contentController = TextEditingController(text: card.content);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: const Text(
          'Edit Flashcard',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // saveNote(); // TODO
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: textColor,
            ),
            onPressed: () {
              // TODO: delete note
              Navigator.of(context).pop();
            },
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    flex: 2,
                    child: Text(
                      "Flashcard Title",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Flexible(
                    flex: 5,
                    child: TextFormField(
                      controller: titleController,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: darkerSecondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Expanded(
          child: TextFormField(
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            controller: contentController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//! -------------------------
//! END OF FLASHCARDS SECTION
//! -------------------------

//? -------------------------------------------------------------
//? the settings screen that's the last item in the bottom navbar
//? -------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // dummy data
  String _username = 'CurrentUser';
  String _email = 'user@example.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'User Settings',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          // Username tile
          Container(
            decoration: BoxDecoration(
              color: elementColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                _username,
                style: TextStyle(color: textColor),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: textColor,
                ),
                onPressed: () => _showEditUsernameDialog(context),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),

          SizedBox(
            height: 15,
          ),

          // Email tile
          Container(
            decoration: BoxDecoration(
              color: elementColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                _email,
                style: TextStyle(color: textColor),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: textColor,
                ),
                onPressed: () => _showEditEmailDialog(context),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),

          SizedBox(
            height: 15,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 175, // Adjust this value to your desired width
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Change Password',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showChangePasswordDialog(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 15,
          ),

          // Logout
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110, // Adjust this value to your desired width
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showLogoutConfirmation(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 15,
          ),

          // About Us
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110, // Adjust this value to your desired width
              child: Container(
                decoration: BoxDecoration(
                  color: elementColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'About Us',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    );
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 15,
          ),

          // Delete Account
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150, // Adjust this value to your desired width
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showDeleteAccountDialog(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Edit Username',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textColor),
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: textColor),
            filled: true,
            fillColor: primaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: validate & save new username
                  _username = controller.text.trim();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username updated')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    final passController = TextEditingController();
    final emailController = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Change Email Address',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'Current Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: verify password, save new email
                  _email = emailController.text.trim();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email updated')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Change Password',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'Old Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'New Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'Confirm New Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: reauthenticate & update password
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Log Out',
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: sign out
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/signin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. Please enter your password to confirm.',
              style: TextStyle(color: warningErrorColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: delete account
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/signin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
      ),
      body: const Center(child: Text('content to be added later...')),
    );
  }
}
//! ----------------------
//! END OF SETTINGS SCREEN
//! ----------------------

//? --------------------------
//? the main group chat screen
//? --------------------------
class ChatPage extends StatefulWidget {
  final String classGroupName;
  final String classGroupCode;
  const ChatPage({
    super.key,
    required this.classGroupName,
    required this.classGroupCode,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  // final List<String> _messages = []; // replace with your data source

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<GroupState>().setName(widget.classGroupName);
    context.read<GroupState>().setCode(widget.classGroupCode);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => context.read<GroupState>().sendMessage(text));
    _controller.clear();
    // TODO: figure the backend part later
  }

  void _openGroupSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GroupSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: GestureDetector(
          onTap: _openGroupSettings,
          child: Text(
            context.watch<GroupState>().groupName ?? 'Null String',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: context.watch<GroupState>().messages.length,
              itemBuilder: (context, i) => Align(
                alignment:
                    i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: i.isEven ? elementColor : secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(context.watch<GroupState>().messages[i]),
                ),
              ),
            ),
          ),

          // Input bar
          Container(
            color: elementColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type your message',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
//! ----------------------
//! END OF GROUP CHAT PAGE
//! ----------------------

//? ----------------------------
//? the group chat settings page
//? ----------------------------
class GroupSettingsScreen extends StatefulWidget {
  //final List<String> members; // list of usernames

  const GroupSettingsScreen({super.key});

  @override
  _GroupSettingsScreenState createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _codeVisible = false;

  @override
  void initState() {
    super.initState();
  }

  void _showEditNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Change Group Name',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textColor),
          decoration: const InputDecoration(
            labelText: 'New Group Name',
            labelStyle: TextStyle(color: textColor),
            filled: true,
            fillColor: primaryColor,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textColor),
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 90,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: darkerSecondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Save',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(String member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(member),
        actions: [
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Transfer Ownership',
                style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mute', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Kick', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ban', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'Group Settings',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 26),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 2.0,
          bottom: 12.0,
          left: 32.0,
          right: 28.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              textAlign: TextAlign.left,
              'Group Name',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(
              height: 5,
            ),

            Container(
              decoration: BoxDecoration(
                color: elementColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                    context.watch<GroupState>().groupName ?? "Null Name",
                    style: TextStyle(color: textColor)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: textColor),
                  onPressed: _showEditNameDialog,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),

            SizedBox(
              height: 32,
            ),

            // Group code tile
            Container(
              decoration: BoxDecoration(
                color: elementColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  _codeVisible
                      ? context.read<GroupState>().groupCode ?? "Null Code"
                      : '••••••••',
                  style: TextStyle(color: textColor),
                ),
                trailing: IconButton(
                  icon: Icon(
                    _codeVisible ? Icons.visibility_off : Icons.visibility,
                    color: textColor,
                  ),
                  onPressed: () => setState(() => _codeVisible = !_codeVisible),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),

            SizedBox(
              height: 24,
            ),

            // Members header
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Members List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // Members list
            Expanded(
              child: ListView.builder(
                itemCount: context.watch<GroupState>().members.length,
                itemBuilder: (context, idx) {
                  final member = context.watch<GroupState>().members[idx];
                  return Container(
                    decoration: BoxDecoration(
                      color: elementColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.more_vert, color: textColor),
                        onPressed: () => _showMemberOptions(member),
                      ),
                      title: Text(member, style: TextStyle(color: textColor)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                    ),
                  );
                },
              ),
            ),

            // Delete Group button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 150, // Adjust this value to your desired width
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: const Text(
                        'Delete',
                        style: TextStyle(
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
//! -------------------------------
//! END OF GROUP CHAT SETTINGS PAGE
//! -------------------------------
