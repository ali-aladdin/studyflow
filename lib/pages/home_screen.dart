import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_screen.dart';
import 'package:studyflow_v2/states/group_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  final int CODE_LENGTH = 10;

  String _generateRandomCode(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<String?> getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data()?['username'] as String?;
    }
    return null;
  }

  // NEW METHOD: _showCreateGroupDialog
  // Shows a dialog to create a new group.
  void createGroup(BuildContext context, GroupState groupState) async {
    String? name = await getUsername() ?? 'placeholder username';
    String? code = _generateRandomCode(CODE_LENGTH);
    // Call createGroup and navigate on success
    String? groupId = await groupState.createGroup('$name\'s group', code);
    if (groupId != null) {
      // Navigate to ChatPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(groupId: groupId)),
      );
    } else {
      // Handle creation failure (e.g., show error message)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create group. Code might be taken.')),
      );
    }
  }

  // NEW METHOD: _showJoinGroupDialog
  // Shows a dialog to join an existing group.
  void _showJoinGroupDialog(BuildContext context, GroupState groupState) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Join Group',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Group Code',
              labelStyle: const TextStyle(color: textColor),
              filled: true,
              fillColor: primaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a group code';
              }
              return null;
            },
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
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final code = codeController.text.trim();
                    String? groupId = await groupState.joinGroup(code);
                    if (groupId != null) {
                      Navigator.pop(context); // Dismiss dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(groupId: groupId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to join group. Invalid code or already a member.',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the GroupState to react to group changes
    final groupState = context.watch<GroupState>();
    final isInGroup = groupState.isInGroup;
    final activeGroupId = groupState.activeGroupId; // Get the active group ID

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: const Text(
          'Home',
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 26,
              color: textColor // Use textColor
              ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isInGroup) ...[
              // --- User is in a group ---
              Text(
                  'You are in: ${groupState.groupName ?? 'Loading...'}', // Display current group name
                  style: const TextStyle(fontSize: 18, color: textColor)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (activeGroupId != null) {
                    // Navigate back to the active chat page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatPage(groupId: activeGroupId)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: elementColor), // Use elementColor
                child: const Text('Return to Group Chat',
                    style: TextStyle(color: textColor)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Show confirmation dialog before leaving
                  final bool? confirmLeave = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Leave Group?'),
                      content: const Text(
                          'Are you sure you want to leave this group?'),
                      backgroundColor: secondaryColor,
                      titleTextStyle: const TextStyle(color: textColor),
                      contentTextStyle: const TextStyle(color: textColor),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel',
                              style: TextStyle(color: textColor)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Leave',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmLeave == true) {
                    try {
                      await groupState.leaveCurrentGroup();
                      // After leaving, the HomeScreen UI will automatically update
                      // because we are watching groupState.isInGroup
                    } catch (e) {
                      // Handle error if owner cannot leave
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red), // Use red color
                child: const Text('Leave Group',
                    style: TextStyle(color: textColor)),
              ),
            ] else ...[
              // --- User is NOT in a group ---
              const Text('You are not in a group.',
                  style: TextStyle(fontSize: 18, color: textColor)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => createGroup(
                    context, groupState), // Pass context and groupState
                style: ElevatedButton.styleFrom(backgroundColor: elementColor),
                child: const Text('Create New Group',
                    style: TextStyle(color: textColor)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showJoinGroupDialog(
                    context, groupState), // Pass context and groupState
                style: ElevatedButton.styleFrom(backgroundColor: elementColor),
                child: const Text('Join Group',
                    style: TextStyle(color: textColor)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
