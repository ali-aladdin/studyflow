import 'package:flutter/material.dart';
import 'package:studyflow/utilities/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'User Settings',
          style: TextStyle(
            color: AppColors.textColor,
          ),
        ),
      ),
    );
  }
}
