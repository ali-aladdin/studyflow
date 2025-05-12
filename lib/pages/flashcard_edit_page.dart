import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/classes/flashcard.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/states/flashcard_state.dart';

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
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text(
                      'Delete Flashcard',
                      style: TextStyle(color: textColor),
                    ),
                    content: const Text(
                      'Are you sure you want to delete this flashcard?',
                      style: TextStyle(color: textColor),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
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
                              Provider.of<FlashcardState>(context,
                                      listen: false)
                                  .deleteCard(widget.card);
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context)
                                  .pop(); // Go back to the list
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: darkerSecondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
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
              // Update existing flashcard using the new method
              Provider.of<FlashcardState>(context, listen: false)
                  .updateCard(flashcard);
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
