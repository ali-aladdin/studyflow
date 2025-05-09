import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_edit_page.dart';
import 'package:studyflow_v2/states/group_state.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import dart:convert for JSON handling

class ChatPage extends StatefulWidget {
  final String groupId;

  const ChatPage({
    super.key,
    required this.groupId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String DEVELOPER_ACCESS_TOKEN = "_FfOo5uFpUH_F1KvaQrmOJGqaWl3lkaK";

  GroupState? _groupState;
  Logger logger = Logger();

  final String _chatbotPromptPrefix =
      "You are a helpful and friendly member of a study group.  Reply to the following message:"; // Add context

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtain the GroupState and store it. This is safe during this lifecycle method.
    _groupState = Provider.of<GroupState>(context, listen: false);
    // If you were adding the listener here previously, move it to initState
    // or another appropriate lifecycle method if needed.
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    // Now use the stored reference to remove the listener.
    _groupState?.removeListener(_scrollToBottom);
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

  // Modified _sendMessage to handle @bot commands
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (text.startsWith('@bot')) {
      // Extract the message for the bot
      Provider.of<GroupState>(context, listen: false).sendMessage(text);
      final botMessage = text.substring(4).trim(); // Remove "@bot "
      if (botMessage.isNotEmpty) {
        // Send to chatbot API and handle response
        await _sendToChatbot(botMessage);
      } else {
        //  Optionally send a message to the group indicating that the user needs to provide a message after @bot
        Provider.of<GroupState>(context, listen: false)
            .sendMessage("Please provide a message for the bot after @bot");
      }
    } else {
      // Normal message: Send directly to Firestore
      Provider.of<GroupState>(context, listen: false).sendMessage(text);
    }

    _controller.clear();
    // Auto-scrolling is handled by the listener
  }

  // New method: _sendToChatbot
  Future<void> _sendToChatbot(String message) async {
    const apiKey =
        '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';
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message},
          ],
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final botReply = responseData['choices'][0]['message']['content'] ??
            "I couldn't understand that.";
        Provider.of<GroupState>(context, listen: false)
            .sendMessageByBot(botReply);
      } else {
        logger
            .e("Chatbot API error: ${response.statusCode} - ${response.body}");
        Provider.of<GroupState>(context, listen: false).sendMessageByBot(
            "Sorry, the bot is having trouble. Please try again later. Error: ${response.statusCode}");
      }
    } catch (e) {
      if (e is SocketException) {
        logger.e("Network error communicating with chatbot API: $e");
        Provider.of<GroupState>(context, listen: false).sendMessageByBot(
            "Sorry, I couldn't reach the bot. Please check your network connection.");
      } else {
        logger.e("Error communicating with chatbot API: $e");
        Provider.of<GroupState>(context, listen: false).sendMessageByBot(
            "Sorry, I couldn't reach the bot. An unexpected error occurred.");
      }
    }
  }

  void _openGroupSettings() {
    // Navigate to GroupSettingsScreen, PASSING the groupId
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
    );
  }

  Future<void> _deleteGroupIfEmpty(String groupId) async {
    try {
      final groupDocRef =
          FirebaseFirestore.instance.collection('groups').doc(groupId);
      final groupSnapshot = await groupDocRef.get();

      if (groupSnapshot.exists) {
        final groupData = groupSnapshot.data();
        if (groupData != null) {
          final members =
              groupData['members'] as List<dynamic>? ?? []; // Handle null case
          if (members.isEmpty) {
            // There are no members, so delete the group
            await groupDocRef.delete();
            // Optionally, delete any associated chat messages
            final chatMessagesRef = FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('messages');
            final messagesSnapshot = await chatMessagesRef.get();
            for (final doc in messagesSnapshot.docs) {
              await doc.reference.delete();
            }
            if (mounted) {
              Navigator.of(context).pop(); //remove the current screen
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group deleted as it was empty')),
            );
          } else {
            // There are members, so don't delete the group
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Cannot delete group: Members still exist')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group does not exist')),
        );
      }
    } catch (e) {
      // Handle errors, such as network issues or permission problems
      logger.e('Error deleting group: $e'); //important
    }
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
                  String? currentGroupId =
                      Provider.of<GroupState>(context, listen: false)
                          .activeGroupId;

                  await Provider.of<GroupState>(context, listen: false)
                      .leaveCurrentGroup();

                  if (currentGroupId != null) {
                    _deleteGroupIfEmpty(currentGroupId);
                  }
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
              // Reverse the list using .reversed
              itemBuilder: (context, i) {
                final reversedIndex = messages.length - 1 - i;
                final message = messages[reversedIndex];
                final isSentByMe = message.senderId == currentUserId;

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
                          senderUsername,
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
                      ],
                    ),
                  ),
                );
              },
              // Set reverse: true on the ListView.builder
              reverse: true,
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
