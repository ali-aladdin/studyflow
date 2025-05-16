import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_screen.dart';
import 'package:studyflow_v2/states/group_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _createGroupNameController = TextEditingController();
  final _joinGroupCodeController = TextEditingController();
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final int codeLength = 10;

  String _generateRandomCode(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  @override
  void dispose() {
    _createGroupNameController.dispose();
    _joinGroupCodeController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog(BuildContext context, GroupState groupState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Create New Group',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: _createFormKey,
          child: TextFormField(
            controller: _createGroupNameController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Group Name',
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
                return 'Please enter a group name';
              }
              return null;
            },
          ),
        ),
        actions: [
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
              if (_createFormKey.currentState!.validate()) {
                final name = _createGroupNameController.text.trim();
                await groupState.createGroup(
                    name, _generateRandomCode(codeLength));
                _createGroupNameController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: darkerSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create',
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context, GroupState groupState) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Join Group',
          style: TextStyle(color: textColor),
        ),
        content: Form(
          key: _joinFormKey,
          child: TextFormField(
            controller: _joinGroupCodeController,
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
                  if (_joinFormKey.currentState!.validate()) {
                    final code = _joinGroupCodeController.text.trim();
                    await groupState.joinGroup(code);
                    _joinGroupCodeController.clear();
                    if (mounted) Navigator.pop(context);
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
    final groupState = context.watch<GroupState>();
    // Access the joinedGroups map directly from the GroupState
    final joinedGroups = groupState.joinedGroups;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: const Text(
          'Groups',
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: 26, color: textColor),
        ),
      ),
      body: joinedGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No joined groups yet.',
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                  // const SizedBox(height: 20),
                  // ElevatedButton(
                  //   onPressed: () =>
                  //       _showCreateGroupDialog(context, groupState),
                  //   style:
                  //       ElevatedButton.styleFrom(backgroundColor: elementColor),
                  //   child: const Text(
                  //     'Create New Group',
                  //     style: TextStyle(color: textColor),
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () => _showJoinGroupDialog(context, groupState),
                  //   style:
                  //       ElevatedButton.styleFrom(backgroundColor: elementColor),
                  //   child: const Text(
                  //     'Join Group',
                  //     style: TextStyle(color: textColor),
                  //   ),
                  // ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: joinedGroups.length,
              itemBuilder: (context, index) {
                final groupId = joinedGroups.keys.toList()[index];
                final group = joinedGroups[groupId]!;
                return Card(
                  color: elementColor,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      group.groupName,
                      style: const TextStyle(
                          color: textColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Code: ${group.groupCode}',
                      style: const TextStyle(color: textColor),
                    ),
                    onTap: () {
                      groupState.setActiveGroup(group.groupId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatPage(groupId: group.groupId)),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.exit_to_app, color: textColor),
                      onPressed: () async {
                        final bool? confirmLeave = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Leave Group?'),
                            content: Text(
                                'Are you sure you want to leave "${group.groupName}"?'),
                            backgroundColor: secondaryColor,
                            titleTextStyle: const TextStyle(color: textColor),
                            contentTextStyle: const TextStyle(color: textColor),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: textColor)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    groupState.leaveGroup(group.groupId),
                                child: const Text('Leave',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'create',
            backgroundColor: secondaryColor,
            onPressed: () => _showCreateGroupDialog(context, groupState),
            child: const Icon(Icons.add_circle_outline,
                size: 45, color: textColor),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'join',
            backgroundColor: secondaryColor,
            onPressed: () => _showJoinGroupDialog(context, groupState),
            child: const Icon(Icons.group_add, size: 35, color: textColor),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
