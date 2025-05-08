import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/forgot_password_page.dart';
import 'package:studyflow_v2/pages/home_page.dart';
import 'package:studyflow_v2/pages/signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _userPassword = true;
  // bool _rememberMe = false; // Removed
  String _usernameError = '';
  String _passwordError = '';
  Logger logger = Logger();

  Future<void> signInWithUsername(BuildContext context) async {
    setState(() {
      _usernameError = '';
      _passwordError = '';
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersRef
          .where('username', isEqualTo: _usernameController.text)
          .get();

      if (querySnapshot.docs.isEmpty) {
        logger.i('Error: User not found');
        setState(() {
          _usernameError = 'Username not found.';
        });
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'];
      final uid = userData['uid']; // Get the uid here

      // 2. Sign in with email and password using Firebase Authentication
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          setState(() {
            _passwordError = 'Invalid password.';
          });
          return;
        } else {
          setState(() {
            _passwordError = 'Error signing in.'; // generic
          });
          logger.e("FirebaseAuthException: ${e.message}");
          return; // Exit, so we don't proceed to the next step.
        }
      }

      // 3.  Retrieve the user data, since we now have the uid
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        logger.i('Signed in successfully!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        logger.i('Error: User data not found in Firestore');
        setState(() {
          _usernameError =
              'Error retrieving user data.'; // Or a more specific message.
        });
        return;
      }
    } catch (e) {
      // Handle other errors (e.g., Firestore error)
      logger.i('Error retrieving user data: $e');
      setState(() {
        _usernameError = 'An error occurred.';
      });
      return;
    }
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
                    'assets/signinlogoandtext.png',
                    height: MediaQuery.of(context).size.height *
                        0.2, // Responsive height
                    width: MediaQuery.of(context).size.width *
                        0.4, // Responsive width
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.03), // Responsive spacing
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : secondaryColor,
                        ),
                      ),
                      errorText:
                          _usernameError.isNotEmpty ? _usernameError : null,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.02), // Responsive spacing
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
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : secondaryColor,
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
                      errorText:
                          _passwordError.isNotEmpty ? _passwordError : null,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Space between forgot password
                    children: [
                      // Removed Remember Me Checkbox
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
                            fontSize: 16,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.02), // Responsive spacing
                  ElevatedButton(
                    onPressed: () => signInWithUsername(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: secondaryColor,
                      minimumSize: Size(
                        double.infinity,
                        MediaQuery.of(context).size.height *
                            0.06, // Responsive height
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.02), // Responsive spacing
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
