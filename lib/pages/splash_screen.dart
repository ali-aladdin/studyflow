// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:studyflow/pages/signin_page.dart';
import 'package:studyflow/utilities/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
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
                color: AppColors.textColor,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: AppColors.secondaryColor,
              strokeWidth: 6,
            ),
          ],
        ),
      ),
    );
  }
}
