import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/states/group_state.dart';

class GroupSettingsScreen extends StatefulWidget {
  // REMOVED: final List members;

  // NEW FIELD: groupId
  // The ID of the active group from Firestore.
  final String groupId;

  const GroupSettingsScreen(
      {super.key, required this.groupId}); // REQUIRE group ID

  @override
  _GroupSettingsScreenState createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _codeVisible = false;

  @override
  void initState() {
    super.initState();
    // No need to call initGroup here, ChatPage already initialized GroupState
    // with this groupId. This screen just watches that state instance.
  }

  // Modified to take GroupState as a parameter
  void _showEditNameDialog(GroupState groupState) {
    // Pre-fill with current name from state
    final controller = TextEditingController(text: groupState.groupName);
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
                  // Call updateGroupName on GroupState
                  groupState.updateGroupName(controller.text);
                  Navigator.of(context).pop();
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

  // Modified to take member's UID and GroupState as parameters
  void _showMemberOptions(String memberUserId, GroupState groupState) {
    final currentUserId = groupState.currentUserId;
    final isOwner = groupState.groupOwnerId == currentUserId;
    final isSelf = memberUserId == currentUserId;
    final canKick = isOwner && !isSelf;
    final canTransferOwnership = isOwner && !isSelf;

    // Get the username for the member's UID for display in the dialog title
    String memberUsername = groupState.getUsername(memberUserId);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: Text(memberUsername,
            style:
                const TextStyle(color: textColor)), // Display username in title
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              if (canTransferOwnership)
                TextButton(
                  onPressed: () {
                    groupState.transferOwnership(memberUserId); // Pass the UID
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
              if (canKick)
                TextButton(
                  onPressed: () {
                    groupState.kickMember(memberUserId); // Pass the UID
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

  // Helper to copy group code
  void _copyGroupCode(String code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group code copied to clipboard!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupState = context.watch<GroupState>();
    // Get list of member UIDs from state
    final memberUids = groupState.memberUids;
    final currentUserId = groupState.currentUserId;
    final isOwner = groupState.groupOwnerId == currentUserId;

    // Show loading indicator if group data isn't ready
    if (groupState.currentGroup == null) {
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
            //! TEST
            /*
            TextButton(
              onPressed: () => groupState.addUserToGroup(
                  groupState.currentGroup?.groupId ?? "fail",
                  "RjrRxn89FjO3cRKNMbAPTgpTrCN2"),
              child: Text("Add Member 1"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => groupState.addUserToGroup(
                  groupState.currentGroup?.groupId ?? "fail",
                  "7xQhvf1CsySp9wQWo0dwGVbKZsA3"),
              child: Text("Add Member 2"),
            ),
            const SizedBox(height: 16),
            */
            //! TEST
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
                title: Text(groupState.groupName ?? "Loading...",
                    style: const TextStyle(color: textColor)),
                trailing: isOwner // Only show edit icon to owner
                    ? IconButton(
                        icon: const Icon(Icons.edit, color: textColor),
                        onPressed: () =>
                            _showEditNameDialog(groupState), // Pass groupState
                      )
                    : null, // Hide icon if not owner
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
                  _codeVisible
                      ? groupState.groupCode ??
                          "Loading..." // Display code from state
                      : '••••••••',
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
                  onPressed: () {
                    if (groupState.groupCode != null) {
                      _copyGroupCode(groupState.groupCode!);
                    }
                  },
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
                  final memberUid = memberUids[idx]; // Get the member UID
                  final isMemberOwner = groupState.groupOwnerId == memberUid;
                  final isSelf = memberUid == currentUserId;

                  // Get the username for the member's UID using the state's helper
                  String memberUsername = groupState.getUsername(memberUid);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: elementColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      // Display member Username
                      title: Text(
                        memberUsername + (isMemberOwner ? ' (Owner)' : ''),
                        style: const TextStyle(color: textColor),
                      ),
                      trailing: Row(
                        // Use Row as the trailing widget
                        mainAxisSize: MainAxisSize
                            .min, // important to keep the row size to a minimum.
                        children: [
                          if (isSelf && !isOwner) //relocated
                            const Text('(You)',
                                style: TextStyle(
                                    color: textColor,
                                    fontStyle: FontStyle.italic)),
                          if (isOwner &&
                              !isSelf) // Only show options icon to owner (not on self) //relocated
                            IconButton(
                              icon:
                                  const Icon(Icons.more_vert, color: textColor),
                              // Pass the member's UID to the options dialog
                              onPressed: () =>
                                  _showMemberOptions(memberUid, groupState),
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

            // Delete Group button (only for owner)
            if (isOwner) // Only show delete button to owner
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
                            await groupState.deleteGroup();
                            // After deleting, pop both the settings screen and the chat screen
                            Navigator.of(context).pop(); // Pop settings
                            Navigator.of(context).pop(); // Pop chat
                            // The HomeScreen UI will automatically update
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
