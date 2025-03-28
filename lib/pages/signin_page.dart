// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
// import 'package:your_app/forgot_password_page.dart';
// import 'package:your_app/sign_up_page.dart';
// import 'package:your_app/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  String _username = '';
  // ignore: unused_field
  String _password = '';
  bool _rememberMe = false;

  void _signIn() async {
    /* uncomment to go to home page
    if (_formKey.currentState!.validate()) {
      // Start the authentication process
      // ...
      // If successful, navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onSaved: (value) => _username = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value!;
                      });
                    },
                  ),
                  Text('Remember Me'),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                child: Text('Login'),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  /* uncomment to go to forgot password page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                  );
                  */
                },
                child: Text('Forgot Password'),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  /* uncomment to go to sign up page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                  */
                },
                child: Text('Create an Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
