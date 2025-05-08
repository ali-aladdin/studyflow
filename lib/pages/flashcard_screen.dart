import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/classes/flashcard.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/flashcard_edit_page.dart';
import 'package:studyflow_v2/states/flashcard_state.dart';

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
