import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_screen.dart';
import 'package:studyflow_v2/states/group_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // NEW METHOD: _showCreateGroupDialog
  // Shows a dialog to create a new group.
  void _showCreateGroupDialog(BuildContext context, GroupState groupState) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        backgroundColor: secondaryColor,
        titleTextStyle: const TextStyle(color: textColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: textColor)),
              style: const TextStyle(color: textColor),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                  labelText: 'Group Code',
                  labelStyle: TextStyle(color: textColor)),
              style: const TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isNotEmpty && code.isNotEmpty) {
                // Call createGroup and navigate on success
                String? groupId = await groupState.createGroup(name, code);
                if (groupId != null) {
                  Navigator.of(context).pop(); // Dismiss dialog
                  // Navigate to ChatPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatPage(groupId: groupId)),
                  );
                } else {
                  // Handle creation failure (e.g., show error message)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Failed to create group. Code might be taken.')),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  // NEW METHOD: _showJoinGroupDialog
  // Shows a dialog to join an existing group.
  void _showJoinGroupDialog(BuildContext context, GroupState groupState) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Group'),
        backgroundColor: secondaryColor,
        titleTextStyle: const TextStyle(color: textColor),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
              labelText: 'Group Code', labelStyle: TextStyle(color: textColor)),
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                // Call joinGroup and navigate on success
                String? groupId = await groupState.joinGroup(code);
                if (groupId != null) {
                  Navigator.of(context).pop(); // Dismiss dialog
                  // Navigate to ChatPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatPage(groupId: groupId)),
                  );
                } else {
                  // Handle join failure (e.g., show error message)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Failed to join group. Invalid code or already a member.')),
                  );
                }
              }
            },
            child: const Text('Join', style: TextStyle(color: textColor)),
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
                onPressed: () => _showCreateGroupDialog(
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
