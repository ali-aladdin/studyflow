import 'package:flutter/material.dart';
import 'package:studyflow_v2/misc/colors.dart';

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
