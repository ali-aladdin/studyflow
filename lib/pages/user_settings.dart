import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/aboutus_page.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/pages/signin_page.dart';

final logger = Logger();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = '';
  String _email = '';
  final User? _user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) {
      logger.e('User not logged in');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'] ?? '';
          _email = _user.email ?? '';
        });
      } else {
        logger.e('User document does not exist');
      }
    } catch (e) {
      logger.e('Error loading user data: $e');
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (_user == null) {
      logger.e('User not logged in');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'username': newUsername});
      setState(() {
        _username = newUsername;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (e) {
      logger.e('Error updating username: $e');
      _showErrorSnackBar('Failed to update username');
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    if (_user == null) {
      logger.e('User not logged in');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
      }
      return;
    }

    try {
      await _user.verifyBeforeUpdateEmail(newEmail);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'email': newEmail});
      if (mounted) {
        setState(() {
          _email = newEmail;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated')),
        );
      }
    } on FirebaseAuthException catch (e) {
      logger.e('FirebaseAuthException updating email: $e');
      String errorMessage = 'Failed to update email: ';
      switch (e.code) {
        case 'invalid-email':
          errorMessage += 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          errorMessage += 'The user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage +=
              'There is no user record corresponding to this identifier.';
          break;
        case 'operation-not-allowed':
          errorMessage += 'This operation is not allowed.';
          break;
        case 'requires-recent-login':
          errorMessage +=
              'This operation is sensitive and requires recent authentication. Log in again before retrying.';
          break;
        default:
          errorMessage += 'An unknown error occurred.';
      }
      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      logger.e('Error updating email: $e');
      if (mounted) {
        _showErrorSnackBar(
            'Failed to update email. An unexpected error occurred: $e');
      }
    }
  }

  Future<void> _changePassword(String newPassword) async {
    if (_user == null) {
      logger.e('User not logged in');
      return;
    }
    try {
      await _user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed')),
      );
    } catch (e) {
      logger.e('Error changing password: $e');
      _showErrorSnackBar(
          'Failed to change password.  Please check your current password.');
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          // Use pushReplacement here
          context,
          MaterialPageRoute(builder: (context) => SignInPage()),
        );
      }
    } catch (e) {
      logger.e('Error signing out: $e');
      _showErrorSnackBar('Failed to sign out.');
    }
  }

  Future<void> _deleteAccount() async {
    if (_user == null) {
      logger.e('User not logged in');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .delete();
      await _user.delete();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignInPage()),
        );
      }
    } catch (e) {
      logger.e('Error deleting account: $e');
      _showErrorSnackBar('Failed to delete account.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'User Settings',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Container(
            decoration: BoxDecoration(
              color: elementColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                _username,
                style: TextStyle(color: textColor),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: textColor,
                ),
                onPressed: () => _showEditUsernameDialog(context),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            decoration: BoxDecoration(
              color: elementColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                _email,
                style: TextStyle(color: textColor),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: textColor,
                ),
                onPressed: () => _showEditEmailDialog(context),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 175,
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Change Password',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showChangePasswordDialog(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110,
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showLogoutConfirmation(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110,
              child: Container(
                decoration: BoxDecoration(
                  color: elementColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'About Us',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    );
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => _showDeleteAccountDialog(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Edit Username',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textColor),
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: textColor),
            filled: true,
            fillColor: primaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  final newUsername = controller.text.trim();
                  if (newUsername.isNotEmpty) {
                    _updateUsername(newUsername);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(BuildContext context) {
    final emailController = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Edit Email',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new email address';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateEmail(emailController.text.trim());
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmNewPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Change Password',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassCtrl,
                obscureText: true,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: textColor),
                  labelText: 'Old Password',
                  filled: true,
                  fillColor: primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: textColor),
                  labelText: 'New Password',
                  filled: true,
                  fillColor: primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmNewPassCtrl,
                obscureText: true,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: textColor),
                  labelText: 'Confirm New Password',
                  filled: true,
                  fillColor: primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != newPassCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _changePassword(newPassCtrl.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Log Out',
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  _signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. Please enter your password to confirm.',
                style: TextStyle(color: warningErrorColor),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: textColor),
                  labelText: 'Password',
                  filled: true,
                  fillColor: primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final AuthCredential credential =
                          EmailAuthProvider.credential(
                        email: user.email!,
                        password: passController.text.trim(),
                      );
                      user.reauthenticateWithCredential(credential).then((_) {
                        _deleteAccount();
                      }).catchError((error) {
                        logger.e("Error reauthenticating user: $error");
                        _showErrorSnackBar(
                            "Incorrect password.  Please try again.");
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
