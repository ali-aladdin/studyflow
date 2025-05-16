import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/chat_edit_page.dart';
import 'package:studyflow_v2/states/group_state.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String groupId;
  final bool showBackButton;

  const ChatPage({
    super.key,
    required this.groupId,
    this.showBackButton = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Scroll to the beginning when the list is reversed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(GroupState groupState) async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      if (text.startsWith('@bot')) {
        groupState.sendMessage(text);
        final botMessage = text.substring(4).trim();
        if (botMessage.isNotEmpty) {
          await _sendToChatbot(botMessage, groupState);
        } else {
          groupState
              .sendMessage("Please provide a message for the bot after @bot");
        }
      } else {
        groupState.sendMessage(text);
      }
      _messageController.clear();
    }
  }

  void _openGroupSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => GroupSettingsScreen(groupId: widget.groupId)),
    );
  }

  Future<void> _sendToChatbot(String message, GroupState groupState) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
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
        groupState.sendMessageByBot(botReply);
      } else {
        _logger
            .e("Chatbot API error: ${response.statusCode} - ${response.body}");
        groupState.sendMessageByBot(
            "Sorry, the bot is having trouble. Please try again later. Error: ${response.statusCode}");
      }
    } catch (e) {
      if (e is SocketException) {
        _logger.e("Network error communicating with chatbot API: $e");
        groupState.sendMessageByBot(
            "Sorry, I couldn't reach the bot. Please check your network connection.");
      } else {
        _logger.e("Error communicating with chatbot API: $e");
        groupState.sendMessageByBot(
            "Sorry, I couldn't reach the bot. An unexpected error occurred.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = Provider.of<GroupState>(context);
    final activeGroup = groupState.activeGroup;
    final messages = groupState.activeGroupMessages.reversed.toList();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (activeGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('Loading Chat...', style: TextStyle(color: textColor)),
          backgroundColor: secondaryColor,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: textColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: textColor),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        centerTitle: true,
        backgroundColor: secondaryColor,
        title: GestureDetector(
          onTap: _openGroupSettings,
          child: Text(
            activeGroup.groupName ?? 'Loading...',
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 18, color: textColor),
          ),
        ),
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
                      onPressed: () {
                        groupState.leaveGroup(activeGroup.groupId);
                        Navigator.of(context).pop(); // Go back to home screen
                      },
                      child: const Text('Leave',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
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
                final reversedIndex = messages.length - 1 - i;
                final message = messages[reversedIndex];
                final isSentByMe = message.senderId == currentUserId;

                String senderUsername =
                    groupState.getUserDisplayNameNonFuture(message.senderId);

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
                        Text(
                          senderUsername,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.content,
                          style: const TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(groupState),
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
                      onPressed: () => _sendMessage(groupState),
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
