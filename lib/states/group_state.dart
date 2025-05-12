import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/classes/group.dart';
import 'package:studyflow_v2/classes/message.dart';

class GroupState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser = FirebaseAuth.instance.currentUser;

  //! TEST
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add FirebaseAuth instance
  final Logger _logger = Logger();
  //! TEST

  // NEW FIELD: _activeGroupId
  // Stores the ID of the group the user is currently viewing.
  String? _activeGroupId;

  // NEW FIELD: _currentGroup
  // Stores the data for the currently active group fetched from Firestore.
  Group? _currentGroup;

  // NEW FIELD: _messages
  // List of message objects fetched from Firestore stream.
  final List<Message> _messages = [];

  // NEW FIELDS: StreamSubscriptions
  // Manage active listeners to Firestore streams.
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _groupSubscription;

  // NEW FIELD: _userUsernameCache
  // Cache for UID -> Username mapping to avoid repeated Firestore reads.
  final Map<String, String> _userUsernameCache = {};

  // --- Getters (Updated to reflect Firestore data) ---

  // NEW GETTER: isInGroup
  // Checks if an active group ID is set.
  bool get isInGroup => _activeGroupId != null;

  // NEW GETTER: activeGroupId
  // Returns the ID of the current group.
  String? get activeGroupId => _activeGroupId;

  // NEW GETTER: currentGroup
  // Returns the current Group object.
  Group? get currentGroup => _currentGroup;

  // NEW GETTER: messages
  // Returns the list of streamed messages.
  List<Message> get messages => _messages;

  // NEW GETTER: memberUids
  // Returns the list of member UIDs from the current group.
  List<String> get memberUids => _currentGroup?.members ?? [];

  // NEW GETTER: groupName
  // Returns the name of the current group.
  String? get groupName => _currentGroup?.groupName;

  // NEW GETTER: groupCode
  // Returns the code of the current group.
  String? get groupCode => _currentGroup?.groupCode;

  // NEW GETTER: groupOwnerId
  // Returns the UID of the group owner.
  String? get groupOwnerId => _currentGroup?.ownerId;

  // NEW GETTER: currentUserId
  // Returns the UID of the currently logged-in user.
  String? get currentUserId => _currentUser?.uid;

  // NEW METHOD: getUsername
  // Looks up and returns the username for a given UID from the cache.
  String getUsername(String uid) {
    return _userUsernameCache[uid] ??
        'Loading...'; // Return cached username or placeholder
  }

  // --- State Management & Firestore Streams ---

  // NEW METHOD: initGroup
  // Starts listening to Firestore streams for messages and group data for the given group ID.
  void initGroup(String groupId) {
    if (_activeGroupId == groupId) return; // Already in this group

    _activeGroupId = groupId;
    _messages.clear(); // Clear old messages
    _currentGroup = null; // Clear old group data
    _userUsernameCache.clear(); // Clear old username cache

    // Start streaming group details (name, code, members, owner)
    _groupSubscription =
        _firestore.collection('groups').doc(_activeGroupId).snapshots().listen(
      (snapshot) async {
        if (snapshot.exists) {
          _currentGroup = Group.fromFirestore(snapshot);
          // Collect UIDs from members and owner
          Set<String> uidsToFetch = Set.from(_currentGroup!.members);
          uidsToFetch.add(_currentGroup!.ownerId);

          // Fetch usernames for these UIDs
          await _fetchUsernamesForUids(uidsToFetch.toList());
          notifyListeners();
        } else {
          // Group likely deleted externally, handle leaving
          if (kDebugMode) print("Group does not exist. Leaving group.");
          leaveGroup(); // Use the internal leave method
        }
      },
      onError: (error) {
        if (kDebugMode) print("Error streaming group data: $error");
        // Handle errors (e.g., show a message to the user)
        leaveGroup(); // Leave group on error
      },
    );

    // Start streaming messages
    _messagesSubscription = _firestore
        .collection('groups')
        .doc(_activeGroupId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Order by time
        .snapshots()
        .listen(
      (snapshot) async {
        _messages.clear(); // Clear list before adding new data
        List<String> senderUidsToFetch = [];
        for (var doc in snapshot.docs) {
          Message msg = Message.fromFirestore(doc);
          _messages.add(msg);
          // Collect sender UIDs to fetch usernames if not already cached
          if (!_userUsernameCache.containsKey(msg.senderId)) {
            senderUidsToFetch.add(msg.senderId);
          }
        }

        // Fetch usernames for any new senders
        if (senderUidsToFetch.isNotEmpty) {
          await _fetchUsernamesForUids(senderUidsToFetch);
        }

        // Sort messages to show newest at the bottom after fetching usernames
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) print("Error streaming messages: $error");
        // Handle errors
        leaveGroup(); // Leave group on error
      },
    );

    notifyListeners(); // Notify that group initialization is starting
  }

  // NEW METHOD: _fetchUsernamesForUids
  // Fetches usernames from the 'users' collection for a list of UIDs.
  Future<void> _fetchUsernamesForUids(List<String> uids) async {
    if (uids.isEmpty) return;

    // Remove duplicates and filter out UIDs we already have cached
    Set<String> uniqueUidsToFetch = uids
        .where((uid) => uid.isNotEmpty && !_userUsernameCache.containsKey(uid))
        .toSet();

    if (uniqueUidsToFetch.isEmpty) return;

    try {
      // Batch queries if more than 10 UIDs (Firestore limit for 'whereIn')
      List<String> uidBatch = uniqueUidsToFetch.toList();
      while (uidBatch.isNotEmpty) {
        List<String> currentBatch = uidBatch.take(10).toList();
        uidBatch = uidBatch.skip(10).toList();

        // Query the 'users' collection by the 'uid' FIELD
        QuerySnapshot userSnapshot = await _firestore
            .collection('users')
            .where('uid',
                whereIn:
                    currentBatch) // Assuming 'users' docs have a 'uid' field
            .get();

        for (var doc in userSnapshot.docs) {
          Map data = doc.data() as Map<String, dynamic>;
          String? fetchedUid = data['uid'];
          String? fetchedUsername =
              data['username']; // Assuming 'users' docs have a 'username' field
          if (fetchedUid != null && fetchedUsername != null) {
            _userUsernameCache[fetchedUid] = fetchedUsername;
          } else {
            // Handle cases where uid or username fields might be missing
            if (kDebugMode) {
              print("User doc missing uid or username: ${doc.id}");
            }
            // Optionally add a placeholder
          }
        }
        notifyListeners(); // Notify after processing each batch
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching usernames by uid field: $e");
      // Optionally set temporary placeholders for UIDs that failed lookup
      for (var uid in uniqueUidsToFetch) {
        if (!_userUsernameCache.containsKey(uid)) {
          _userUsernameCache[uid] = 'User N/A';
        }
      }
      notifyListeners();
    }
  }

  // NEW METHOD: leaveGroup
  // Stops streams and clears state when leaving a group.
  void leaveGroup() {
    _messagesSubscription?.cancel();
    _groupSubscription?.cancel();
    _messages.clear();
    _currentGroup = null;
    _activeGroupId = null;
    _userUsernameCache.clear(); // Clear cache
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _groupSubscription?.cancel();
    super.dispose();
  }

  // NEW METHOD: updateCurrentUser
  // Updates the current user reference and fetches their username.
  void updateCurrentUser(User? user) {
    _currentUser = user;
    if (_currentUser != null) {
      _fetchUsernamesForUids(
          [_currentUser!.uid]); // Fetch current user's username
    }

    // If user logs out while in a group, leave the group
    if (_currentUser == null && isInGroup) {
      if (kDebugMode) print("User logged out while in group, leaving group.");
      leaveGroup();
    }
    notifyListeners();
  }

  // --- Firestore Actions (Updated to use UIDs and Group ID) ---

  // NEW METHOD: sendMessage
  // Sends a message to the active group in Firestore.
  Future<void> sendMessage(String text) async {
    if (_activeGroupId == null || _currentUser == null) {
      if (kDebugMode) {
        print("Cannot send message: Not in a group or user not logged in.");
      }
      return;
    }
    if (text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('groups')
          .doc(_activeGroupId)
          .collection('messages')
          .add({
        'senderId': _currentUser!.uid, // Store sender's UID
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Messages will be added to the list via the stream
    } catch (e) {
      if (kDebugMode) print("Error sending message: $e");
      // Handle error
    }
  }

  Future<void> sendMessageByBot(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('groups')
          .doc(_activeGroupId)
          .collection('messages')
          .add({
        'senderId': 'chatbot', // Store sender's UID
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Messages will be added to the list via the stream
    } catch (e) {
      if (kDebugMode) print("Error sending message: $e");
      // Handle error
    }
  }

  // NEW METHOD: updateGroupName
  // Updates the name of the active group in Firestore.
  Future<void> updateGroupName(String newName) async {
    if (_activeGroupId == null || _currentUser == null) return;
    if (_currentGroup?.ownerId != _currentUser?.uid) {
      if (kDebugMode) print("Only the owner can change the group name.");
      return;
    }
    if (newName.trim().isEmpty) return;

    try {
      await _firestore
          .collection('groups')
          .doc(_activeGroupId)
          .update({'groupName': newName.trim()});
      // Stream listener updates _currentGroup
    } catch (e) {
      if (kDebugMode) print("Error updating group name: $e");
    }
  }

  // NEW METHOD: deleteGroup
  // Deletes the active group from Firestore.
  Future<void> deleteGroup() async {
    if (_activeGroupId == null || _currentUser == null) return;
    if (_currentGroup?.ownerId != _currentUser?.uid) {
      if (kDebugMode) print("Only the owner can delete the group.");
      return;
    }

    try {
      // Consider Cloud Functions for recursive deletion of subcollections
      await _firestore.collection('groups').doc(_activeGroupId).delete();
      leaveGroup(); // Leave state after successful deletion
      // UI layer should navigate away after calling this
    } catch (e) {
      if (kDebugMode) print("Error deleting group: $e");
    }
  }

  // NEW METHOD: kickMember
  // Removes a member from the active group (param is UID).
  Future<void> kickMember(String userIdToKick) async {
    if (_activeGroupId == null || _currentUser == null) return;
    if (_currentGroup?.ownerId != _currentUser?.uid) {
      if (kDebugMode) print("Only the owner can kick members.");
      return;
    }
    if (_currentGroup!.ownerId == userIdToKick) {
      if (kDebugMode) print("Cannot kick the owner.");
      return;
    }
    if (!_currentGroup!.members.contains(userIdToKick)) {
      if (kDebugMode) print("User is not a member of this group.");
      return;
    }

    try {
      await _firestore.collection('groups').doc(_activeGroupId).update({
        'members': FieldValue.arrayRemove([userIdToKick]), // Remove by UID
      });
      // Stream listener updates _currentGroup
    } catch (e) {
      if (kDebugMode) print("Error kicking member: $e");
    }
  }

  // NEW METHOD: transferOwnership
  // Transfers ownership of the active group (param is new owner UID).
  Future<void> transferOwnership(String newOwnerId) async {
    if (_activeGroupId == null || _currentUser == null) return;
    if (_currentGroup?.ownerId != _currentUser?.uid) {
      if (kDebugMode) print("Only the current owner can transfer ownership.");
      return;
    }
    if (_currentGroup!.ownerId == newOwnerId) {
      if (kDebugMode) print("New owner is already the current owner.");
      return;
    }
    if (!_currentGroup!.members.contains(newOwnerId)) {
      if (kDebugMode) print("New owner is not a member of this group.");
      return;
    }

    try {
      await _firestore.collection('groups').doc(_activeGroupId).update({
        'ownerId': newOwnerId, // Update with new owner UID
      });
      // Stream listener updates _currentGroup
    } catch (e) {
      if (kDebugMode) print("Error transferring ownership: $e");
    }
  }

  // NEW METHOD: createGroup
  // Creates a new group in Firestore.
  // Needs owner's UID. Username is fetched later for display.
  Future<String?> createGroup(String name, String code) async {
    if (_currentUser == null) {
      if (kDebugMode) print("User not logged in.");
      return null;
    }
    final ownerId = _currentUser!.uid;

    if (name.trim().isEmpty || code.trim().isEmpty) {
      if (kDebugMode) print("Group name and code cannot be empty.");
      return null;
    }

    try {
      // Optional: Add logic here to check if group code is already in use
      // This might involve a query and handling the result before creating.

      DocumentReference docRef = await _firestore.collection('groups').add({
        'ownerId': ownerId, // Store UID
        'groupName': name.trim(),
        'groupCode': code.trim(),
        'members': [ownerId], // Add owner's UID as the first member
      });

      // Fetch and cache owner's username immediately if not already known
      await _fetchUsernamesForUids([ownerId]);

      // Initialize state for the newly created group
      initGroup(docRef.id);
      return docRef.id; // Return the new group ID
    } catch (e) {
      if (kDebugMode) print("Error creating group: $e");
      // Handle error
      return null;
    }
  }

  // NEW METHOD: joinGroup
  // Joins an existing group using its code.
  // Needs joining user's UID. Username is fetched later.
  Future<String?> joinGroup(String code) async {
    if (_currentUser == null) {
      if (kDebugMode) print("User not logged in.");
      return null;
    }
    final userId = _currentUser!.uid;

    if (code.trim().isEmpty) {
      if (kDebugMode) print("Group code cannot be empty.");
      return null;
    }

    try {
      // Find the group by code
      QuerySnapshot snapshot = await _firestore
          .collection('groups')
          .where('groupCode', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) print("Group not found with code: $code");
        return null; // Group not found
      }

      DocumentSnapshot groupDoc = snapshot.docs.first;
      Group groupToJoin = Group.fromFirestore(groupDoc);

      // Check if user is already a member
      if (groupToJoin.members.contains(userId)) {
        if (kDebugMode) print("User is already a member of this group.");
        initGroup(groupDoc.id); // Just initialize state if already a member
        return groupDoc.id;
      }

      // Add the user to the members list
      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion(
            [userId]), // Use arrayUnion to avoid duplicates
      });

      // Fetch and cache joined user's username
      await _fetchUsernamesForUids([userId]);

      // Initialize the state for the joined group
      initGroup(groupDoc.id);
      return groupDoc.id; // Return the joined group ID
    } catch (e) {
      if (kDebugMode) print("Error joining group: $e");
      // Handle error
      return null;
    }
  }

  // NEW METHOD: leaveCurrentGroup
  // Removes the current user from the active group.
  Future<void> leaveCurrentGroup() async {
    if (_activeGroupId == null || _currentUser == null) return;

    try {
      // Check if the current user is the owner
      if (_currentGroup?.ownerId == _currentUser?.uid) {
        // Owner is leaving - need to handle ownership transfer or group deletion
        if ((_currentGroup?.members.length ?? 0) > 1) {
          throw Exception("Owner must transfer ownership before leaving.");
        } else {
          // Owner is the only member, can delete the group
          if (kDebugMode) print("Owner is the only member, deleting group.");
          await deleteGroup(); // Delete the group if owner is the last member
          // deleteGroup handles state cleanup
          return;
        }
      }

      // If not the owner, just remove the member
      await _firestore.collection('groups').doc(_activeGroupId).update({
        'members': FieldValue.arrayRemove([_currentUser!.uid]), // Remove by UID
      });

      // Leave the group state
      leaveGroup();
      // UI layer should navigate away after calling this
    } catch (e) {
      if (kDebugMode) print("Error leaving group: $e");
      rethrow; // Rethrow error so UI can catch the owner case
    }
  }

  //! TEST

  Future<void> addUserToGroup(String groupId, String userId) async {
    try {
      // 1.  Add the user's UID to the group's members list in Firestore.
      final groupRef = _firestore.collection('groups').doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId])
      });

      // 2. Optionally, update the local state (if you're managing members locally).
      //    This depends on how your GroupState class is structured.  For example:
      if (currentGroup != null) {
        currentGroup!.members.add(userId); // Assuming you have a members list
        notifyListeners();
      }
      _logger.i('User $userId added to group $groupId');
    } catch (e) {
      _logger.e('Error adding user to group: $e');
      //  Consider showing a user-friendly message using a SnackBar or a dialog.
      notifyListeners(); // Ensure listeners are notified on error, too.
      rethrow; // rethrow the error so that the caller can handle it as well
    }
  }

  //method to get user id from email
  Future<String?> getUserIdFromEmail(String email) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      _logger.e("Error getting user ID from email: $e");
      return null;
    }
  }
}
