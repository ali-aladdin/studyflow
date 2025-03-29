import 'package:flutter/material.dart';
import 'package:studyflow/utilities/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.secondaryColor,
        title: const Text(
          'Home',
          style: TextStyle(
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
