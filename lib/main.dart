import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studyflow/pages/splash_screen.dart';
import 'package:studyflow/utilities/colors.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
      ),
      home: SplashScreen(),
    );
  }
}
