import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/signin_page.dart';

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
  String _emailError = '';
  String _usernameError = '';
  String _passwordError = '';
  Logger logger = Logger();

  void resetControllers() {
    _emailController.text = '';
    _usernameController.text = '';
    _passwordController.text = '';
  }

  Future<void> signUpWithEmailUsernameAndPassword(BuildContext context) async {
    setState(() {
      _emailError = '';
      _usernameError = '';
      _passwordError = '';
    });
    try {
      if (_formKey.currentState!.validate()) {
        // 1. Create user with email and password using Firebase Authentication
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // 2. Get the user's UID
        final uid = userCredential.user!.uid;

        // 3. Store additional user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailController.text,
          'username': _usernameController.text,
          'uid': uid, // Store the UID for easy access later
        });
        logger.i('Signed up successfully!');
        resetControllers();
        //pop to signin
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors (e.g., email already in use)
      logger.i('Error signing up: ${e.message}');
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = 'Email address is already in use.';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Invalid email address.';
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _passwordError = 'Password is too weak.';
        });
      } else {
        setState(() {
          _emailError = 'Error signing up.';
        });
      }
      resetControllers(); // Important: rethrow the error to be handled by the caller
    } catch (e) {
      // Handle other errors (e.g., Firestore error)
      logger.i('Error creating user in Firestore: $e');
      setState(() {
        _emailError = 'Error creating user.';
      });
      resetControllers();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    'assets/signuplogoandtext.png', // Make sure this path is correct
                    width: 190,
                    height: 190,
                  ),
                  const SizedBox(height: 24),
                  // Email Input Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _emailError.isNotEmpty
                              ? Colors.red
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _emailError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
                        ),
                      ),
                      errorText: _emailError.isNotEmpty
                          ? _emailError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
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
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
                        ),
                      ),
                      errorText: _usernameError.isNotEmpty
                          ? _usernameError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
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
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
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
                      errorText: _passwordError.isNotEmpty
                          ? _passwordError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
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
                    onPressed: () =>
                        signUpWithEmailUsernameAndPassword(context),
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
