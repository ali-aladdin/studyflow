import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/misc/colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;
  String _emailError = '';
  Logger logger = Logger();

  Future<void> sendResetPasswordEmail() async {
    setState(() {
      _isSending = true;
      _emailError = '';
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      logger.i("Email Sent Successfully");
      Navigator.pop(context); //? go back to sign in
    } on FirebaseAuthException catch (e) {
      _emailError = 'Failed to send reset email.';
      if (e.code == 'invalid-email') {
        _emailError = 'Invalid email address.';
      } else if (e.code == 'user-not-found') {
        _emailError = 'No user found with this email.';
      }
      logger.i(_emailError);
      logger.i('Error sending password reset email: ${e.message}');
    } catch (e) {
      //* Handle other errors
      logger.i("An unexpected error has occurred.");
      logger.i('Error sending password reset email: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: textColor),
                errorText: _emailError.isNotEmpty ? _emailError : null,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: textColor),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: textColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sendResetPasswordEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkerSecondaryColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: secondaryColor,
                      ),
                    )
                  : const Text(
                      'Send Email',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: textColor,
              ),
              child: const Text(
                'Go Back to Sign In',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
