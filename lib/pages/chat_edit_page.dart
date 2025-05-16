import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/states/group_state.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _codeVisible = false; //? to toggle the group code display
  Logger logger = Logger();

  void _showEditNameDialog(BuildContext context, GroupState groupState) {
    final controller = TextEditingController(
        text: groupState.activeGroup?.groupName); //? current grp name
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Change Group Name',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: textColor),
          decoration: const InputDecoration(
            labelText: 'New Group Name',
            labelStyle: TextStyle(color: textColor),
            filled: true,
            fillColor: primaryColor,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: textColor),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const SizedBox(
                  width: 90,
                  height: 40,
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (groupState.activeGroupId != null) {
                    groupState.updateGroupName(
                        groupState.activeGroupId!, controller.text);
                    Navigator.of(context).pop();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const SizedBox(
                  width: 90,
                  height: 40,
                  child: Center(
                    child: Text(
                      'Save',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(
      BuildContext context, String memberUserId, GroupState groupState) {
    final currentUserId = groupState.currentUser?.uid;
    final activeGroup = groupState.activeGroup;
    final isOwner = activeGroup?.ownerId == currentUserId;
    final isSelf = memberUserId == currentUserId;
    final canKick = isOwner && !isSelf;
    final canTransferOwnership = isOwner && !isSelf;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: FutureBuilder<String>(
          future: groupState.getUserDisplayName(memberUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...',
                  style: TextStyle(color: textColor));
            } else if (snapshot.hasError) {
              print('Error getting username: ${snapshot.error}');
              return const Text('User', style: TextStyle(color: textColor));
            } else if (snapshot.hasData) {
              return Text(snapshot.data!,
                  style: const TextStyle(color: textColor));
            } else {
              return const Text('User', style: TextStyle(color: textColor));
            }
          },
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              if (canTransferOwnership && activeGroup?.groupId != null)
                TextButton(
                  onPressed: () {
                    groupState.transferOwnership(
                        activeGroup!.groupId, memberUserId);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: darkerSecondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Transfer Ownership',
                      style: TextStyle(color: textColor)),
                ),
              const SizedBox(height: 8),
              if (canKick && activeGroup?.groupId != null)
                TextButton(
                  onPressed: () {
                    groupState.kickMember(activeGroup!.groupId, memberUserId);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: darkerSecondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Kick', style: TextStyle(color: textColor)),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyGroupCode(BuildContext context, String? code) {
    if (code != null) {
      Clipboard.setData(ClipboardData(text: code)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group code copied to clipboard!')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = context.watch<GroupState>();
    final activeGroup = groupState.activeGroup;
    final currentUserId = groupState.currentUser?.uid;
    final memberUids = activeGroup?.members ?? [];
    final isOwner = activeGroup?.ownerId == currentUserId;

    if (activeGroup == null) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('Loading Settings...',
                  style: TextStyle(color: textColor)),
              backgroundColor: primaryColor),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'Group Settings',
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: 26, color: textColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 2.0,
          bottom: 12.0,
          left: 32.0,
          right: 28.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              textAlign: TextAlign.left,
              'Group Name',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                color: elementColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(activeGroup.groupName,
                    style: const TextStyle(color: textColor)),
                trailing: isOwner
                    ? IconButton(
                        icon: const Icon(Icons.edit, color: textColor),
                        onPressed: () =>
                            _showEditNameDialog(context, groupState),
                      )
                    : null, //? show icon only if the user is the owner
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              textAlign: TextAlign.left,
              'Group Code',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              decoration: BoxDecoration(
                color: elementColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  _codeVisible ? activeGroup.groupCode : '••••••••',
                  style: const TextStyle(color: textColor),
                ),
                trailing: IconButton(
                  icon: Icon(
                    _codeVisible ? Icons.visibility_off : Icons.visibility,
                    color: textColor,
                  ),
                  onPressed: () => setState(() => _codeVisible = !_codeVisible),
                ),
                leading: IconButton(
                  // Add copy button
                  icon: const Icon(Icons.copy, color: textColor),
                  onPressed: () =>
                      _copyGroupCode(context, activeGroup.groupCode),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Members List',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: memberUids.length,
                itemBuilder: (context, idx) {
                  final memberUid = memberUids[idx];
                  final isMemberOwner = activeGroup.ownerId == memberUid;
                  final isSelf = memberUid == currentUserId;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: elementColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: FutureBuilder<String>(
                        future: groupState.getUserDisplayName(memberUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading...',
                                style: TextStyle(color: textColor));
                          } else if (snapshot.hasError) {
                            logger
                                .e('Error getting username: ${snapshot.error}');
                            return const Text('User',
                                style: TextStyle(color: textColor));
                          } else if (snapshot.hasData) {
                            final memberUsername = snapshot.data!;
                            return Text(
                              memberUsername +
                                  (isMemberOwner ? ' (Owner)' : ''),
                              style: const TextStyle(color: textColor),
                            );
                          } else {
                            return const Text('User',
                                style: TextStyle(color: textColor));
                          }
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelf && !isOwner)
                            const Text('(You)',
                                style: TextStyle(
                                    color: textColor,
                                    fontStyle: FontStyle.italic)),
                          if (isOwner && !isSelf)
                            IconButton(
                              icon:
                                  const Icon(Icons.more_vert, color: textColor),
                              onPressed: () => _showMemberOptions(
                                  context, memberUid, groupState),
                            ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                    ),
                  );
                },
              ),
            ),
            if (isOwner && activeGroup.groupId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Delete Group',
                          style: TextStyle(
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () async {
                          final bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Group?'),
                              content: const Text(
                                  'Are you sure you want to delete this group? This action cannot be undone.'),
                              backgroundColor: secondaryColor,
                              titleTextStyle: const TextStyle(color: textColor),
                              contentTextStyle:
                                  const TextStyle(color: textColor),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: textColor)),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            await groupState.deleteGroup(activeGroup.groupId);
                            Navigator.of(context)
                                .pop(); //? remove settings page
                            Navigator.of(context)
                                .pop(); //? go back to the chat page (which will then likely go back to home due to activeGroup being null)
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
