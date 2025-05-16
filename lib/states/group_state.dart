import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/classes/group.dart';
import 'package:studyflow_v2/classes/message.dart';

class GroupState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  final Map<String, Group> _joinedGroups = {};
  final Map<String, List<Message>> _groupMessages = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final Map<String, StreamSubscription> _groupSubscriptions = {};
  final Map<String, String> _userDisplayNames = {};
  Logger logger = Logger();

  String? _activeGroupId;
  StreamSubscription? _authStateSubscription;

  GroupState() {
    _listenToAuthChanges();
    _init();
  }

  Future<void> _init() async {
    _currentUser = _auth.currentUser;
    await loadUserGroups();
  }

  void _listenToAuthChanges() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // User has logged out
        _currentUser = null;
        _joinedGroups.clear();
        _groupMessages.clear();
        _messageSubscriptions.values.forEach((sub) => sub.cancel());
        _messageSubscriptions.clear();
        _groupSubscriptions.values.forEach((sub) => sub.cancel());
        _groupSubscriptions.clear();
        _userDisplayNames.clear();
        _activeGroupId = null;
        logger.i('User logged out. GroupState reset.');
        notifyListeners();
      } else if (_currentUser?.uid != user.uid) {
        // New user logged in or session restored
        _currentUser = user;
        logger.i('Auth state changed. Current user: ${_currentUser?.uid}');
        loadUserGroups(); // Reload groups for the new user
      }
    });
  }

  Future<void> loadUserGroups() async {
    final userId = _currentUser?.uid;
    if (userId == null) {
      _joinedGroups.clear();
      notifyListeners();
      return;
    }

    // Fetch groups where the current user's ID is in the members array
    final query = await _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    _joinedGroups.clear(); // Clear existing groups to avoid duplicates
    for (var doc in query.docs) {
      final group = Group.fromFirestore(doc);
      _joinedGroups[doc.id] = group;
      _listenToGroup(doc.id);
      _listenToMessages(doc.id);
      // Prefetch display names for members of this group
      for (final memberId in group.members) {
        _fetchUserDisplayName(memberId);
      }
    }

    notifyListeners();
  }

  Map<String, Group> get joinedGroups => _joinedGroups;
  User? get currentUser => _currentUser;
  String? get activeGroupId => _activeGroupId;
  Group? get activeGroup =>
      _activeGroupId != null ? _joinedGroups[_activeGroupId] : null;
  List<Message> get activeGroupMessages =>
      _activeGroupId != null ? _groupMessages[_activeGroupId] ?? [] : [];

  void setActiveGroup(String groupId) {
    if (_joinedGroups.containsKey(groupId)) {
      _activeGroupId = groupId;
      // Ensure display names for members of the active group are fetched
      final group = _joinedGroups[groupId];
      if (group != null) {
        for (final memberId in group.members) {
          _fetchUserDisplayName(memberId);
        }
      }
      notifyListeners();
    }
  }

  Future<void> createGroup(String groupName, String groupCode) async {
    final userId = _currentUser?.uid;
    if (userId == null) return;

    final groupRef = await _firestore.collection('groups').add({
      'ownerId': userId,
      'groupName': groupName,
      'groupCode': groupCode,
      'members': [userId],
    });

    final newGroup = Group(
      groupId: groupRef.id,
      ownerId: userId,
      groupName: groupName,
      groupCode: groupCode,
      members: [userId],
    );

    _joinedGroups[groupRef.id] = newGroup;
    _listenToGroup(groupRef.id);
    _listenToMessages(groupRef.id);
    _activeGroupId = groupRef.id;
    _fetchUserDisplayName(userId); // Fetch display name for the creator
    notifyListeners();

    // Update the user's joinedGroups list in the 'users' collection
    await _updateUserJoinedGroups(userId, groupRef.id);
  }

  Future<void> _updateUserJoinedGroups(String userId, String groupId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'joinedGroups': FieldValue.arrayUnion([groupId]),
      });
    } catch (e) {
      logger.e("Error updating user's joinedGroups: $e");
    }
  }

  Future<void> updateGroupName(String groupId, String newName) async {
    if (!_joinedGroups.containsKey(groupId)) return;
    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({'groupName': newName});
    _joinedGroups[groupId] =
        _joinedGroups[groupId]!.copyWith(groupName: newName);
    notifyListeners();
  }

  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    if (!_joinedGroups.containsKey(groupId)) return;
    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({'ownerId': newOwnerId});
    _joinedGroups[groupId] =
        _joinedGroups[groupId]!.copyWith(ownerId: newOwnerId);
    notifyListeners();
  }

  Future<void> kickMember(String groupId, String memberId) async {
    if (!_joinedGroups.containsKey(groupId)) return;
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
    _joinedGroups[groupId]!.members.remove(memberId);
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    if (!_joinedGroups.containsKey(groupId)) return;
    // Stop listening to messages and group updates
    _messageSubscriptions[groupId]?.cancel();
    _groupSubscriptions[groupId]?.cancel();
    _messageSubscriptions.remove(groupId);
    _groupSubscriptions.remove(groupId);

    // Remove the group ID from the joinedGroups of all members
    final groupSnapshot =
        await _firestore.collection('groups').doc(groupId).get();
    if (groupSnapshot.exists && groupSnapshot.data()?['members'] != null) {
      final List<String> members =
          List<String>.from(groupSnapshot.data()!['members']);
      for (final memberId in members) {
        await _firestore.collection('users').doc(memberId).update({
          'joinedGroups': FieldValue.arrayRemove([groupId]),
        });
      }
    }

    _joinedGroups.remove(groupId);
    if (_activeGroupId == groupId) {
      _activeGroupId =
          _joinedGroups.isNotEmpty ? _joinedGroups.keys.first : null;
    }
    // Delete the group document
    await _firestore.collection('groups').doc(groupId).delete();
    // Optionally, delete all messages within the group as well
    final messagesQuery = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .get();
    for (final doc in messagesQuery.docs) {
      await doc.reference.delete();
    }
    notifyListeners();
  }

  Future<String> _fetchUserDisplayName(String userId) async {
    logger.i('Fetching display name for user ID: $userId');
    if (_userDisplayNames.containsKey(userId)) {
      logger.i('Display name found in cache: ${_userDisplayNames[userId]}');
      return _userDisplayNames[userId]!;
    }
    try {
      logger.i('Fetching display name from Firestore for user ID: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      logger.i('User document exists: ${userDoc.exists}');
      logger.i('User document data: ${userDoc.data()}');
      if (userDoc.exists && userDoc.data()?['username'] != null) {
        _userDisplayNames[userId] = userDoc.data()!['username'] as String;
        logger
            .i('Display name fetched and cached: ${_userDisplayNames[userId]}');
        return _userDisplayNames[userId]!;
      }
      logger.i('Username not found in Firestore, returning default "User"');
      return 'User'; // Default name if not found
    } catch (e) {
      logger.i('Error fetching display name for $userId: $e');
      return 'User';
    }
  }

  Future<String> getUserDisplayName(String userId) async {
    if (_userDisplayNames.containsKey(userId)) {
      return _userDisplayNames[userId]!;
    }
    return _fetchUserDisplayName(userId);
  }

  String getUserDisplayNameNonFuture(String uid) {
    if (uid == 'chatbot') {
      return 'Bot';
    }
    return _userDisplayNames[uid] ?? 'Loading...';
  }

  void _listenToGroup(String groupId) {
    final subscription =
        _firestore.collection('groups').doc(groupId).snapshots().listen((doc) {
      if (doc.exists) {
        final updatedGroup = Group.fromFirestore(doc);
        _joinedGroups[groupId] = updatedGroup;
        // Ensure display names are fetched for new members
        for (final memberId in updatedGroup.members) {
          _fetchUserDisplayName(memberId);
        }
        notifyListeners();
      } else {
        // Group document was deleted
        _joinedGroups.remove(groupId);
        _messageSubscriptions[groupId]?.cancel();
        _groupSubscriptions[groupId]?.cancel();
        _messageSubscriptions.remove(groupId);
        _groupSubscriptions.remove(groupId);
        if (_activeGroupId == groupId) {
          _activeGroupId =
              _joinedGroups.isNotEmpty ? _joinedGroups.keys.first : null;
        }
        notifyListeners();
      }
    });

    _groupSubscriptions[groupId]?.cancel();
    _groupSubscriptions[groupId] = subscription;
  }

  void _listenToMessages(String groupId) {
    final subscription = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _groupMessages[groupId] =
          snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
      notifyListeners();
    });

    _messageSubscriptions[groupId]?.cancel();
    _messageSubscriptions[groupId] = subscription;
  }

  Future<void> sendMessage(String content) async {
    final groupId = _activeGroupId;
    final userId = _currentUser?.uid;
    if (groupId == null || content.trim().isEmpty || userId == null) return;

    final message = Message(
      senderId: userId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'senderId': message.senderId,
      'content': message.content,
      'timestamp': message.timestamp,
    });
  }

  Future<void> sendMessageByBot(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('groups')
          .doc(_activeGroupId)
          .collection('messages')
          .add({
        'senderId': 'chatbot',
        'content': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print("Error sending message: $e");
    }
  }

  Future<void> joinGroup(String groupCode) async {
    final userId = _currentUser?.uid;
    if (userId == null) return;

    final query = await _firestore
        .collection('groups')
        .where('groupCode', isEqualTo: groupCode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final groupId = query.docs.first.id;
      if (_joinedGroups.containsKey(groupId)) {
        // User is already in the group
        _activeGroupId = groupId;
        notifyListeners();
        return;
      }
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
      final groupSnapshot =
          await _firestore.collection('groups').doc(groupId).get();
      if (groupSnapshot.exists) {
        final group = Group.fromFirestore(groupSnapshot);
        _joinedGroups[groupId] = group;
        _listenToGroup(groupId);
        _listenToMessages(groupId);
        _activeGroupId = groupId;
        // Fetch display names for all members after joining
        for (final memberId in group.members) {
          _fetchUserDisplayName(memberId);
        }
        notifyListeners();

        // Update the user's joinedGroups list
        await _updateUserJoinedGroups(userId, groupId);
      }
    } else {
      // Group not found
      // Consider showing an error message to the user
      logger.i('Group with code $groupCode not found.');
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = _currentUser?.uid;
    if (userId == null || !_joinedGroups.containsKey(groupId)) return;

    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    _joinedGroups.remove(groupId);
    _messageSubscriptions[groupId]?.cancel();
    _messageSubscriptions.remove(groupId);
    _groupSubscriptions[groupId]?.cancel();
    _groupSubscriptions.remove(groupId);
    if (_activeGroupId == groupId) {
      _activeGroupId =
          _joinedGroups.isNotEmpty ? _joinedGroups.keys.first : null;
    }
    notifyListeners();

    // Update the user's joinedGroups list
    await _firestore.collection('users').doc(userId).update({
      'joinedGroups': FieldValue.arrayRemove([groupId]),
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Cancel the auth state listener
    for (var sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    for (var sub in _groupSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
