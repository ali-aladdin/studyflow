import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';
import 'dart:math';

//! INDEXES to navigate more easily to certain code blocks
final StatelessWidget mainPage = MyApp(key: UniqueKey());
final StatefulWidget signInPage = SignInPage(key: UniqueKey());
final StatefulWidget signUpPage = SignUpPage(key: UniqueKey());
final StatefulWidget forgotPasswordPage = ForgotPasswordPage(key: UniqueKey());
final StatefulWidget homePage = HomePage(key: UniqueKey());
final StatelessWidget homeScreenPage = HomeScreen(key: UniqueKey());
final StatefulWidget notesPage = NotesScreen(key: UniqueKey());
final StatefulWidget flashcardsPage = FlashcardsScreen(key: UniqueKey());
final StatefulWidget groupChatPage = ChatPage(
  groupId: "232412232",
);
final StatefulWidget settingsPage = SettingsScreen(key: UniqueKey());
//! END OF INDEXES

//! GLOBAL VARS
final logger = Logger(); //! To log better
final DatabaseServices _databaseServices = DatabaseServices();

//? SECTION TO HELP WITH FIRESTORE

const String USERS_COLLECTION_REF = "users";

class DatabaseServices {
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference _usersRef;

  DatabaseServices() {
    // returns a schema associated reference
    _usersRef = FirebaseFirestore.instance
        .collection('users')
        .withConverter<User>(
            fromFirestore:
                (DocumentSnapshot<Map<String, dynamic>> snapshot, _) =>
                    User.fromMap(
                      snapshot.data()!,
                    ),
            toFirestore: (User user, _) => user.toMap());
  }

  Stream<QuerySnapshot> getUsers() {
    return _usersRef.snapshots();
  }

  void addUser(User user) async {
    _usersRef.add(user);
  }
}

//! END OF FIRESTORE HELPER SECTION

//* PREFERED LAYOUTS AND DESIGNS
/*



//! buttons
  ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SomeWhere()),
      );
    },
    style: ElevatedButton.styleFrom(
      foregroundColor: primaryColor,
      backgroundColor: secondaryColor,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text('Something'),
  ),

//! more buttons
  SizedBox(
    height: 35,
    width: 50,
    child: Container(
      height: 30,
      decoration: BoxDecoration(
        color: darkerSecondaryColor, // Your desired color
        borderRadius: BorderRadius.circular(
            8.0), // Optional rounded corners
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Join',
          style: TextStyle(
            fontSize: 10,
            color: textColor,
          ),
        ),
      ),
    ),
  ),  

//! search field
  child: TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: primaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintText: 'search for notes',
      prefixIcon: const Icon(Icons.search),
    ),
  ),


//! some font styles
  style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 26,
  ),

//! row or column with flexible
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Flexible(
        flex: 2,
        ...
      ),
      SizedBox(
        width: ...,
      ),
      Flexible(
        flex: 5,
        ...
      ),
    ],
  ),
*/

//* COMMONLY USED CODES
/*

  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (context) => SomeWhere()),
  );


*/

//? -------------------------------------------
//? colors that will be used throughout the app
//? -------------------------------------------
const Color primaryColor = Color(0xffF0F4F7);
const Color secondaryColor = Color(0xffF4D869);
const Color darkerSecondaryColor = Color.fromARGB(255, 226, 197, 82);
const Color textColor = Color(0xff1E1E1E);
const Color elementColor = Color(0xffD9D9D9);
const Color warningErrorColor = Color.fromARGB(255, 240, 42, 42);
//! ---------------------
//! END OF COLORS SECTION
//! ---------------------

//? ---------------------------------------------
//? state class for global accessing of variables
//? and detecting changes in state
//? ---------------------------------------------
//* usage:
//* READ:  final dtype var = context.watch<varState>().var;
//* WRITE: context.read<varState>().methodName();
/*
 * and use this instead of initState()
 * @override
 * void didChangeDependencies() {
 *   super.didChangeDependencies();
 *   .. context.watch<varState>().var;
 *   .. context.watch<varState>().var;
 * }
*/

/*
 *
 */
class HomeState extends ChangeNotifier {
  bool _inGroup = false;

  bool get inGroup => _inGroup;

  void toggleIsSomething() {
    _inGroup = !_inGroup;
    notifyListeners();
  }
}

class GroupState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser = FirebaseAuth.instance.currentUser as User?;

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
}

class NoteState extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // Firestore collection reference
  CollectionReference<Note> get notesCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in'); // Or handle this appropriately
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .withConverter<Note>(
          fromFirestore: Note.fromFirestore,
          toFirestore: (Note note, SetOptions? options) => note.toFirestore(),
        );
  }

  NoteState() {
    fetchNotes();
  }

  // Fetch notes from Firestore
  Future<void> fetchNotes() async {
    try {
      final snapshot = await notesCollection.get();
      _notes = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching notes: $e');
      // Handle error (e.g., show a message to the user)
    }
  }

  // Add a new note to Firestore
  Future<void> addNote(Note note) async {
    try {
      final docRef = await notesCollection.add(note);
      final newNote = Note(
          id: docRef.id,
          title: note.title,
          content: note.content,
          pinned: note.pinned); //get ID
      _notes.add(newNote);
      notifyListeners();
    } catch (e) {
      logger.e('Error adding note: $e');
      // Handle error
    }
  }

  // Update an existing note in Firestore
  Future<void> updateNote(Note updatedNote) async {
    try {
      await notesCollection.doc(updatedNote.id).update({
        'title': updatedNote.title,
        'content': updatedNote.content,
        'pinned': updatedNote.pinned,
      });
      final index = _notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating note: $e');
      // Handle error
    }
  }

  // Delete a note from Firestore
  Future<void> deleteNote(String noteId) async {
    try {
      await notesCollection.doc(noteId).delete();
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting note: $e');
      // Handle error
    }
  }

  // Pin a note
  Future<void> pinNote(String noteId, bool pinned) async {
    try {
      await notesCollection.doc(noteId).update({'pinned': pinned});
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(pinned: pinned);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error pinning note: $e');
      // Handle error.  You might want to show a message to the user.
    }
  }
}

class FlashcardState extends ChangeNotifier {
  List<Flashcard> _cards = [];

  List<Flashcard> get cards => _cards;
  // Firestore collection reference
  CollectionReference<Flashcard> get flashcardsCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in'); // Or handle this appropriately
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards') // Changed collection name
        .withConverter<Flashcard>(
          fromFirestore: Flashcard.fromFirestore,
          toFirestore: (Flashcard flashcard, SetOptions? options) =>
              flashcard.toFirestore(),
        );
  }

  FlashcardState() {
    fetchFlashcards();
  }

  // Fetch flashcards from Firestore
  Future<void> fetchFlashcards() async {
    try {
      final snapshot = await flashcardsCollection.get();
      _cards = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching flashcards: $e');
      // Handle error (e.g., show a message to the user)
    }
  }

  // Add a new flashcard to Firestore
  Future<void> addCard(Flashcard newCard) async {
    try {
      final docRef = await flashcardsCollection.add(newCard);
      final newFlashcard = Flashcard(
          id: docRef.id,
          title: newCard.title,
          content: newCard.content,
          pinned: newCard.pinned); //get ID
      _cards.add(newFlashcard);
      notifyListeners();
    } catch (e) {
      logger.e('Error adding flashcard: $e');
      // Handle error
    }
  }

  void deleteCard(Flashcard cardToDelete) async {
    try {
      await flashcardsCollection.doc(cardToDelete.id).delete();
      _cards.removeWhere((card) => card.id == cardToDelete.id);
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting flashcard: $e');
    }
  }

  Future<void> editCardTitle(String id, String newTitle) async {
    try {
      await flashcardsCollection.doc(id).update({'title': newTitle});
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(title: newTitle);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating flashcard title: $e');
    }
  }

  Future<void> editCardContent(String id, String newContent) async {
    try {
      await flashcardsCollection.doc(id).update({'content': newContent});
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(content: newContent);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating flashcard content: $e');
    }
  }

  Future<void> pinCard(String cardId, bool pinned) async {
    try {
      await flashcardsCollection.doc(cardId).update({'pinned': pinned});
      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(pinned: pinned);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error pinning flashcard: $e');
      // Handle error.  You might want to show a message to the user.
    }
  }
}
//! -------------------------------
//! END OF STATE MANAGEMENT SECTION
//! -------------------------------

//? ------------------------------------------
//? classes section that'll aid in development
//? ------------------------------------------
class User {
  final String email;
  final String username;
  final String uid;

  User({
    required this.email,
    required this.username,
    required this.uid,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      email: map['email'],
      uid: map['uid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'uid': uid,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? username,
  }) {
    return User(
      email: email ?? this.email,
      username: username ?? this.username,
      uid: uid ?? this.uid,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  bool pinned;
  Note({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? pinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'pinned': pinned,
    };
  }

  factory Note.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Note(
      id: snapshot.id,
      title: data?['title'] ?? '',
      content: data?['content'] ?? '',
      pinned: data?['pinned'] ?? false,
    );
  }
}

class Flashcard {
  final String id;
  final String title;
  final String content;
  bool pinned;
  Flashcard({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
  });
  Flashcard copyWith({
    String? id,
    String? title,
    String? content,
    bool? pinned,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'pinned': pinned,
    };
  }

  factory Flashcard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Flashcard(
      id: snapshot.id,
      title: data?['title'] ?? '',
      content: data?['content'] ?? '',
      pinned: data?['pinned'] ?? false,
    );
  }
}

class Group {
  final String groupId;
  final String ownerId; // Firebase Auth UID of the owner
  final String groupName;
  final String groupCode;
  final List<String> members; // List of Firebase Auth UIDs

  Group({
    required this.groupId,
    required this.ownerId,
    required this.groupName,
    required this.groupCode,
    required this.members,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Group(
      groupId: doc.id,
      ownerId: data['ownerId'] ?? '',
      groupName: data['groupName'] ?? 'Unnamed Group',
      groupCode: data['groupCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'groupName': groupName,
      'groupCode': groupCode,
      'members': members,
    };
  }
}

class Message {
  final String messageId;
  final String senderId; // Firebase Auth UID of the sender
  final String text;
  final DateTime timestamp;

  Message({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    Timestamp? ts = data['timestamp'] as Timestamp?;
    return Message(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
//! ----------------------
//! END OF CLASSES SECTION
//! ----------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeState>(
          create: (_) => HomeState(),
        ),
        ChangeNotifierProvider<NoteState>(
          create: (_) => NoteState(),
        ),
        ChangeNotifierProvider<FlashcardState>(
          create: (_) => FlashcardState(),
        ),
        ChangeNotifierProvider<GroupState>(
          create: (_) => GroupState(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: primaryColor,
            scaffoldBackgroundColor: primaryColor,
            appBarTheme: AppBarTheme(
              foregroundColor: textColor,
            )),
        home: HomePage(),
      ),
    );
  }
}
//! -----------
//! END OF MAIN
//! -----------

//? --------------------
//? authentication pages
//? --------------------
//? ------------------------------------------
//? splash screen, the first screen in our app
//? ------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 15),
            Text(
              'StudyFlow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: secondaryColor,
              strokeWidth: 6,
            ),
          ],
        ),
      ),
    );
  }
}
//! --------------------
//! END OF SPLASH SCREEN
//! --------------------

//? ------------
//? sign in page
//? ------------
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _userPassword = true;
  bool _rememberMe = false;
  String _usernameError = '';
  String _passwordError = '';

  Future<void> signInWithUsername(BuildContext context) async {
    setState(() {
      _usernameError = '';
      _passwordError = '';
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersRef
          .where('username', isEqualTo: _usernameController.text)
          .get();

      if (querySnapshot.docs.isEmpty) {
        logger.i('Error: User not found');
        setState(() {
          _usernameError = 'Username not found.';
        });
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'];
      final uid = userData['uid']; // Get the uid here

      // 2. Sign in with email and password using Firebase Authentication
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          setState(() {
            _passwordError = 'Invalid password.';
          });
          return;
        } else {
          setState(() {
            _passwordError = 'Error signing in.'; // generic
          });
          logger.e("FirebaseAuthException: ${e.message}");
          return; // Exit, so we don't proceed to the next step.
        }
      }

      // 3.  Retrieve the user data, since we now have the uid
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        logger.i('Signed in successfully!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        logger.i('Error: User data not found in Firestore');
        setState(() {
          _usernameError =
              'Error retrieving user data.'; // Or a more specific message.
        });
        return;
      }
    } catch (e) {
      // Handle other errors (e.g., Firestore error)
      logger.i('Error retrieving user data: $e');
      setState(() {
        _usernameError = 'An error occurred.';
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/signinlogoandtext.png',
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : secondaryColor,
                        ),
                      ),
                      errorText:
                          _usernameError.isNotEmpty ? _usernameError : null,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _userPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : textColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : secondaryColor,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _userPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _userPassword = !_userPassword;
                          });
                        },
                      ),
                      errorText:
                          _passwordError.isNotEmpty ? _passwordError : null,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        checkColor: primaryColor,
                        activeColor: secondaryColor,
                        side: BorderSide(
                          color: secondaryColor,
                          width: 2.0,
                        ),
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => signInWithUsername(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//! -------------------
//! END OF SIGN IN PAGE
//! -------------------

//? --------------------
//? forgot password page
//? --------------------
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;
  String _emailError = '';

  Future<void> sendResetPasswordEmail() async {
    setState(() {
      _isSending = true;
      _emailError = '';
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      // Show a success message to the user.  Consider using a dialog.
      logger.i("Email Sent Successfully");
      Navigator.pop(context); // Go back to the sign-in page
    } on FirebaseAuthException catch (e) {
      // Handle errors, such as invalid email or user not found
      _emailError = 'Failed to send reset email.';
      if (e.code == 'invalid-email') {
        _emailError = 'Invalid email address.';
      } else if (e.code == 'user-not-found') {
        _emailError = 'No user found with this email.';
      }
      logger.i(_emailError);
      logger.i('Error sending password reset email: ${e.message}');
    } catch (e) {
      // Handle other errors
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
      backgroundColor: primaryColor, // Set the background color
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
        automaticallyImplyLeading:
            false, // Remove the default back button, we'll use a TextButton
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Make children stretch
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: textColor), // Set text color
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: textColor),
                errorText:
                    _emailError.isNotEmpty ? _emailError : null, // Label color
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: textColor), // Border color  <--- ADDED THIS LINE
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
                backgroundColor:
                    darkerSecondaryColor, // Button color  <--- CHANGED THIS LINE
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
                        color: secondaryColor, // Match the button's text color
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
                foregroundColor: textColor, // Text color
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

//! ---------------------------
//! END OF FORGOT PASSWORD PAGE
//! ---------------------------

//? ------------
//? sign up page
//? ------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _userPassword = true;
  String _emailError = '';
  String _usernameError = '';
  String _passwordError = '';

  void resetControllers() {
    _emailController.text = '';
    _usernameController.text = '';
    _passwordController.text = '';
  }

  Future<void> signUpWithEmailUsernameAndPassword(BuildContext context) async {
    setState(() {
      _emailError = '';
      _usernameError = '';
      _passwordError = '';
    });
    try {
      if (_formKey.currentState!.validate()) {
        // 1. Create user with email and password using Firebase Authentication
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // 2. Get the user's UID
        final uid = userCredential.user!.uid;

        // 3. Store additional user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailController.text,
          'username': _usernameController.text,
          'uid': uid, // Store the UID for easy access later
        });
        logger.i('Signed up successfully!');
        resetControllers();
        //pop to signin
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors (e.g., email already in use)
      logger.i('Error signing up: ${e.message}');
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = 'Email address is already in use.';
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Invalid email address.';
        });
      } else if (e.code == 'weak-password') {
        setState(() {
          _passwordError = 'Password is too weak.';
        });
      } else {
        setState(() {
          _emailError = 'Error signing up.';
        });
      }
      resetControllers(); // Important: rethrow the error to be handled by the caller
    } catch (e) {
      // Handle other errors (e.g., Firestore error)
      logger.i('Error creating user in Firestore: $e');
      setState(() {
        _emailError = 'Error creating user.';
      });
      resetControllers();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/signuplogoandtext.png', // Make sure this path is correct
                    width: 190,
                    height: 190,
                  ),
                  const SizedBox(height: 24),
                  // Email Input Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _emailError.isNotEmpty
                              ? Colors.red
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _emailError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
                        ),
                      ),
                      errorText: _emailError.isNotEmpty
                          ? _emailError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Username Input Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _usernameError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
                        ),
                      ),
                      errorText: _usernameError.isNotEmpty
                          ? _usernameError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password Input Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _userPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: textColor,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : textColor, // Change border color on error
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2.5,
                          color: _passwordError.isNotEmpty
                              ? Colors.red
                              : secondaryColor, // Change border color on error
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _userPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _userPassword = !_userPassword;
                          });
                        },
                      ),
                      errorText: _passwordError.isNotEmpty
                          ? _passwordError
                          : null, // Show Error
                      errorStyle: const TextStyle(height: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: () =>
                        signUpWithEmailUsernameAndPassword(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: primaryColor,
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  // Already Registered Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already registered?',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignInPage()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//! -------------------
//! END OF SIGN UP PAGE
//! -------------------
//! ---------------------------
//! END OF AUTHENTICATION PAGES
//! ---------------------------

//? ----------------------------------------------
//? the home page that the app will revolve around
//? ----------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

bool inGroup = false;

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController __groupCodeInput = TextEditingController();

  //! UTILITY FUNCTIONS
  List<String> adjectives = [
    "Bold",
    "Fearless",
    "United",
    "Strong",
    "Luminous",
    "Epic"
  ];
  List<String> nouns = [
    "Warriors",
    "Explorers",
    "Dreamers",
    "Innovators",
    "Pioneers",
    "Voyagers"
  ];

  String generateRandom_GroupName() {
    Random random = Random();
    String adjective = adjectives[random.nextInt(adjectives.length)];
    String noun = nouns[random.nextInt(nouns.length)];

    return "$adjective$noun";
  }

  String generateRandom_GroupCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    String code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    return code;
  }

  //! END OF UTILITY FUNCTIONS

  // Dialog to create/join group:
  void _showGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkerSecondaryColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<HomeState>().toggleIsSomething();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        groupId: "123123123",
                      ),
                    ),
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'Create New Group',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: __groupCodeInput,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: primaryColor,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: primaryColor,
                          ),
                        ),
                        labelText: 'Enter group code',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: darkerSecondaryColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'Join',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Pages with injected onFab behavior:
  final List<Widget> _pages = [
    const HomeScreen(),
    const NotesScreen(),
    const FlashcardsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        iconSize: 35,
        backgroundColor: secondaryColor,
        selectedItemColor: textColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_filled,
              color: textColor,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_book_rounded,
              color: textColor,
            ),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.credit_card,
              color: textColor,
            ),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
              color: textColor,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
//! ----------------
//! END OF HOME PAGE
//! ----------------

//? ----------------------------------------------------------
//? the home screen that's the first item in the bottom navbar
//? ----------------------------------------------------------
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
//! ------------------
//! END OF HOME SCREEN
//! ------------------

//? -------------------------------------------------------------
//? the notes section that's the second item in the bottom navbar
//? -------------------------------------------------------------
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make a copy and sort so pinned are first
    final notes = Provider.of<NoteState>(context).notes;
    final sortedNotes = List<Note>.from(notes)
      ..sort((a, b) {
        if (a.pinned == b.pinned) return 0;
        return a.pinned ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                //  Implement search functionality.
                // You'll likely want to update the displayed list based on the search term
                setState(() {}); // Trigger a rebuild to update the list
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: elementColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Search for notes',
                hintStyle: const TextStyle(
                  color: textColor,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: sortedNotes.length,
        itemBuilder: (context, index) {
          final note = sortedNotes[index];
          //search implementation
          if (_searchController.text.isNotEmpty &&
              !note.title.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) &&
              !note.content.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  )) {
            return const SizedBox
                .shrink(); // Return an empty widget if it doesn't match
          }
          final preview = note.content.length > 50
              ? '${note.content.substring(0, 50)}…'
              : note.content;

          return Card(
            color: elementColor,
            margin: const EdgeInsets.all(8.0), // Margin around the Card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
            ),
            child: ListTile(
              title: Text(
                note.title,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                preview,
                style: const TextStyle(
                  color: textColor,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      note.pinned ? Icons.favorite : Icons.favorite_border,
                      color: note.pinned ? Colors.red : textColor,
                    ),
                    onPressed: () {
                      Provider.of<NoteState>(context, listen: false)
                          .pinNote(note.id, !note.pinned);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: textColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteEditPage(note: note),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondaryColor,
        onPressed: () {
          // Navigate to NoteEditPage for creating a new note.  Pass in a new Note with an empty ID.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditPage(
                note: Note(id: '', title: '', content: ''),
              ),
            ),
          );
        },
        child: const Icon(Icons.add_circle_outline, size: 45, color: textColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class NoteEditPage extends StatefulWidget {
  final Note note;
  const NoteEditPage({super.key, required this.note});

  @override
  _NoteEditPageState createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: Text(
          widget.note.id.isEmpty ? 'New Note' : 'Edit Note',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (widget
              .note.id.isNotEmpty) // Only show delete if it's an existing note
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: textColor,
              ),
              onPressed: () {
                // Show a confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text(
                        'Are you sure you want to delete this note?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<NoteState>(context, listen: false)
                              .deleteNote(widget.note.id);
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).pop(); // Go back to the list
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  flex: 2,
                  child: Text(
                    "Note Title",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  flex: 5,
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: darkerSecondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Expanded(
          child: TextFormField(
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            controller: _contentController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondaryColor,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final note = Note(
              id: widget.note.id, // Keep the original ID if editing
              title: _titleController.text,
              content: _contentController.text,
              pinned: widget.note.pinned,
            );
            if (widget.note.id.isEmpty) {
              // Add new note
              Provider.of<NoteState>(context, listen: false).addNote(note);
            } else {
              // Update existing note
              Provider.of<NoteState>(context, listen: false).updateNote(note);
            }
            Navigator.of(context).pop(); // Go back to the list
          }
        },
        child: const Icon(Icons.save, color: textColor),
      ),
    );
  }
}

//! --------------------
//! END OF NOTES SECTION
//! --------------------

//? -----------------------------------------------------------------
//? the flashcards section that's the third item in the bottom navbar
//? -----------------------------------------------------------------
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Copy and sort so pinned first
    final cards = Provider.of<FlashcardState>(context).cards;
    final sortedCards = List<Flashcard>.from(cards)
      ..sort((a, b) {
        if (a.pinned == b.pinned) return 0;
        return a.pinned ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Flashcards',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: elementColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Search for flashcards',
                hintStyle: TextStyle(
                  color: textColor,
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          itemCount: sortedCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final card = sortedCards[index];
            //search implementation
            if (_searchController.text.isNotEmpty &&
                !card.title.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ) &&
                !card.content.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    )) {
              return const SizedBox
                  .shrink(); // Return an empty widget if it doesn't match
            }
            return Card(
              color: elementColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(card.title),
                      content: Text(card.content),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            card.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              card.pinned
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: card.pinned ? Colors.red : textColor,
                            ),
                            onPressed: () {
                              Provider.of<FlashcardState>(context,
                                      listen: false)
                                  .pinCard(card.id, !card.pinned);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: textColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FlashcardEditPage(card: card),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondaryColor,
        onPressed: () {
          // Navigate to FlashcardEditPage for creating a new flashcard.  Pass in a new Flashcard with an empty ID.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardEditPage(
                card: Flashcard(id: '', title: '', content: ''),
              ),
            ),
          );
        },
        child: const Icon(Icons.add_circle_outline, size: 45, color: textColor),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, //changed to centerFloat
    );
  }
}

class FlashcardEditPage extends StatefulWidget {
  final Flashcard card;
  const FlashcardEditPage({super.key, required this.card});

  @override
  _FlashcardEditPageState createState() => _FlashcardEditPageState();
}

class _FlashcardEditPageState extends State<FlashcardEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.card.title;
    _contentController.text = widget.card.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: Text(
          widget.card.id.isEmpty ? 'New Flashcard' : 'Edit Flashcard',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (widget.card.id
              .isNotEmpty) // Only show delete if it's an existing flashcard
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: textColor,
              ),
              onPressed: () {
                // Show a confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Flashcard'),
                    content: const Text(
                        'Are you sure you want to delete this flashcard?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<FlashcardState>(context, listen: false)
                              .deleteCard(widget.card);
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.of(context).pop(); // Go back to the list
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  flex: 2,
                  child: Text(
                    "Flashcard Title",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  flex: 5,
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: darkerSecondaryColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Expanded(
          child: TextFormField(
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top,
            controller: _contentController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: secondaryColor,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final flashcard = Flashcard(
              id: widget.card.id, // Keep the original ID if editing
              title: _titleController.text,
              content: _contentController.text,
              pinned: widget.card.pinned,
            );
            if (widget.card.id.isEmpty) {
              // Add new flashcard
              Provider.of<FlashcardState>(context, listen: false)
                  .addCard(flashcard);
            } else {
              // Update existing flashcard
              Provider.of<FlashcardState>(context, listen: false)
                  .editCardTitle(widget.card.id, flashcard.title);
              Provider.of<FlashcardState>(context, listen: false)
                  .editCardContent(widget.card.id, flashcard.content);
            }
            Navigator.of(context).pop(); // Go back to the list
          }
        },
        child: const Icon(Icons.save, color: textColor),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, //changed to centerFloat
    );
  }
}

//! -------------------------
//! END OF FLASHCARDS SECTION
//! -------------------------

//? -------------------------------------------------------------
//? the settings screen that's the last item in the bottom navbar
//? -------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // dummy data
  String _username = 'CurrentUser';
  String _email = 'user@example.com';

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
          // Username tile
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

          SizedBox(
            height: 15,
          ),

          // Email tile
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

          SizedBox(
            height: 15,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 175, // Adjust this value to your desired width
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

          SizedBox(
            height: 15,
          ),

          // Logout
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110, // Adjust this value to your desired width
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

          SizedBox(
            height: 15,
          ),

          // About Us
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 110, // Adjust this value to your desired width
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

          SizedBox(
            height: 15,
          ),

          // Delete Account
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150, // Adjust this value to your desired width
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
          )
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
                  // TODO: validate & save new username
                  _username = controller.text.trim();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username updated')),
                  );
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
    final passController = TextEditingController();
    final emailController = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Change Email Address',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: textColor),
                labelText: 'Current Password',
                filled: true,
                fillColor: primaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
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
          ],
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
                  // TODO: verify password, save new email
                  _email = emailController.text.trim();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email updated')),
                  );
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text(
          'Change Password',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
            ),
            const SizedBox(height: 8),
            TextField(
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
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPassCtrl,
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
            ),
          ],
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
                  // TODO: reauthenticate & update password
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed')),
                  );
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
                  // TODO: sign out
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/signin');
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. Please enter your password to confirm.',
              style: TextStyle(color: warningErrorColor),
            ),
            const SizedBox(height: 8),
            TextField(
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
            ),
          ],
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
                  // TODO: delete account
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/signin');
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

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
        ),
      ),
      body: const Center(child: Text('content to be added later...')),
    );
  }
}
//! ----------------------
//! END OF SETTINGS SCREEN
//! ----------------------

//? --------------------------
//? the main group chat screen
//? --------------------------
class ChatPage extends StatefulWidget {
  // REMOVED: final String classGroupName;
  // REMOVED: final String classGroupCode;

  // NEW FIELD: groupId
  // The ID of the active group from Firestore.
  final String groupId;

  const ChatPage({
    super.key,
    required this.groupId, // REQUIRE group ID
    // REMOVED: required this.classGroupName,
    // REMOVED: required this.classGroupCode,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize the GroupState with the current group ID
    // Use Future.microtask to avoid calling notifyListeners during build
    Future.microtask(() {
      Provider.of<GroupState>(context, listen: false).initGroup(widget.groupId);
    });
    // Add listener to scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupState>(context, listen: false)
          .addListener(_scrollToBottom);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    Provider.of<GroupState>(context, listen: false)
        .removeListener(_scrollToBottom);
    // Note: GroupState itself is disposed higher up in the tree by Provider
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Call the sendMessage method on GroupState
    Provider.of<GroupState>(context, listen: false).sendMessage(text);

    _controller.clear();
    // Auto-scrolling is handled by the listener
  }

  void _openGroupSettings() {
    // Navigate to GroupSettingsScreen, PASSING the groupId
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the GroupState for changes
    final groupState = context.watch<GroupState>();
    final messages = groupState.messages; // List of Message objects from stream
    final currentUserId = groupState.currentUserId; // Get current user UID

    // Show loading indicator if group data isn't ready yet
    if (groupState.currentGroup == null) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('Loading Group...',
                  style: TextStyle(color: textColor)),
              backgroundColor: secondaryColor),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: GestureDetector(
          onTap: _openGroupSettings,
          child: Text(
            groupState.groupName ??
                'Loading...', // Display actual group name from state
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 18, color: textColor),
          ),
        ),
        // Add a leave group button (optional, could be only in settings)
        // Keeping it here as it was in the previous version
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: textColor),
            tooltip: 'Leave Group',
            onPressed: () async {
              final bool? confirmLeave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Group?'),
                  content:
                      const Text('Are you sure you want to leave this group?'),
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
                  await Provider.of<GroupState>(context, listen: false)
                      .leaveCurrentGroup();

                  // Navigate back to Home after leaving
                  Navigator.of(context).pop(); // Pop ChatPage
                  // The HomeScreen UI will automatically update as groupState.isInGroup becomes false
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final message = messages[i];
                final isSentByMe =
                    message.senderId == currentUserId; // Check by UID

                // Get the username for the sender UID using the state's helper
                String senderUsername =
                    groupState.getUsername(message.senderId);

                return Align(
                  alignment:
                      isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSentByMe ? secondaryColor : elementColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: isSentByMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Display sender Username
                        Text(
                          senderUsername, // Use the fetched username
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Display message text
                        Text(
                          message.text,
                          style: const TextStyle(color: textColor),
                        ),
                        // Optional: Add timestamp if needed
                        // Text(
                        //   DateFormat('HH:mm').format(message.timestamp),
                        //   style: TextStyle(fontSize: 8, color: textColor.withOpacity(0.6)),
                        // ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: elementColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type your message',
                          hintStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: textColor),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
//! ----------------------
//! END OF GROUP CHAT PAGE
//! ----------------------

//? ----------------------------
//? the group chat settings page
//? ----------------------------
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
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mute not implemented yet')),
                  );
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Mute', style: TextStyle(color: textColor)),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ban not implemented yet')),
                  );
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: darkerSecondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ban', style: TextStyle(color: textColor)),
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
            const SizedBox(height: 16),
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
                itemCount: memberUids.length, // Iterate over UIDs
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
                      leading: isOwner &&
                              !isSelf // Only show options icon to owner (not on self)
                          ? IconButton(
                              icon:
                                  const Icon(Icons.more_vert, color: textColor),
                              // Pass the member's UID to the options dialog
                              onPressed: () =>
                                  _showMemberOptions(memberUid, groupState),
                            )
                          : null, // Hide icon if not owner or is self
                      // Display member Username
                      title: Text(
                          memberUsername + (isMemberOwner ? ' (Owner)' : ''),
                          style: const TextStyle(color: textColor)),
                      trailing: isSelf && !isOwner
                          ? const Text('(You)',
                              style: TextStyle(
                                  color: textColor,
                                  fontStyle: FontStyle.italic))
                          : null,

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
//! -------------------------------
//! END OF GROUP CHAT SETTINGS PAGE
//! -------------------------------
