import 'package:flutter/material.dart';
import 'package:studyflow_v2/misc/colors.dart'; // Assuming these color definitions

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor:
            secondaryColor, // Use secondaryColor from your colors.dart
        title: const Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
            color: textColor, // Use textColor from your colors.dart
          ),
        ),
      ),
      body: Container(
        color: primaryColor, // Use primaryColor as the background
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // App Title
              const Text(
                'StudyFlow',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Use textColor
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Empowering Students to Succeed',
                style: TextStyle(
                  fontSize: 18.0,
                  color: textColor, // Use textColor
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // Our Mission Section
              Container(
                padding: const EdgeInsets.all(16.0),
                // Removed color: Colors.yellow, and using the defined color instead
                decoration: BoxDecoration(
                  color:
                      elementColor, // Use elementColor for the section background
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Use textColor
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'StudyFlow helps students collaborate, learn, and achieve their academic goals.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: textColor, // Use textColor
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Meet the Team Section
              const Text(
                'Meet the Team',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Use textColor
                ),
              ),
              const SizedBox(height: 16.0),
              Wrap(
                // Use Wrap for better layout on smaller screens
                alignment: WrapAlignment.center,
                spacing: 16.0, // Add spacing between team members
                children: <Widget>[
                  _buildTeamMember('Ali Aladdin', 'Dev'),
                  _buildTeamMember('Emad Diab', 'Dev'),
                ],
              ),
              const SizedBox(height: 24.0),

              // Contact Us Section
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Use textColor
                ),
              ),
              const SizedBox(height: 16.0),
              _buildContactInfo('support@studyflow.app'),
              _buildContactInfo(
                  '@StudyFlowApp'), //  Made both contact info use the helper
              const SizedBox(height: 24.0),

              // Powered by Firebase
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Powered by ',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: textColor, // Use textColor
                    ),
                  ),
                  //  Added a sized box to control the size of the image.
                  SizedBox(
                    height: 24, // Adjust as needed
                    child: Image.asset(
                      'assets/firebase_logo.png', //  Path to your Firebase logo,  Add this to your assets
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for building team member info
  static Widget _buildTeamMember(String name, String role) {
    return Column(
      children: <Widget>[
        const Icon(
          // Using a user icon
          Icons.person,
          size: 48.0,
          color: textColor, // Use textColor
        ),
        const SizedBox(height: 8.0),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: textColor, // Use textColor
          ),
        ),
        Text(
          role,
          style: const TextStyle(
            fontSize: 14.0,
            color: textColor, // Use textColor
          ),
        ),
      ],
    );
  }

  //Helper method for building contact info
  static Widget _buildContactInfo(String contact) {
    IconData icon;
    if (contact.contains('@')) {
      icon = Icons.mail;
    } else {
      icon = Icons.account_circle; //  Using a generic icon
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: textColor, // Use textColor
        ),
        const SizedBox(width: 8.0),
        Text(
          contact,
          style: const TextStyle(
            fontSize: 16.0,
            color: textColor, // Use textColor
          ),
        ),
      ],
    );
  }
}
