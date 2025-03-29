import 'package:flutter/material.dart';
import 'package:studyflow/utilities/colors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Notes'),
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.primaryColor,
        toolbarHeight: 60.0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(45.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              controller: _searchText,
              decoration: const InputDecoration(
                labelText: 'Search for notes',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: AppColors.textColor,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                  ),
                ),
                filled: true,
                fillColor: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
