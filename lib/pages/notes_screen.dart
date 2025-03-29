import 'package:flutter/material.dart';
import 'package:studyflow/utilities/colors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.secondaryColor,
        title: const Text(
          'Notes',
          style: TextStyle(
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
