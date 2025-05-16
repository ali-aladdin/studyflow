import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyflow_v2/classes/note.dart';
import 'package:studyflow_v2/misc/colors.dart';
import 'package:studyflow_v2/pages/note_edit_page.dart';
import 'package:studyflow_v2/states/note_state.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoteState>(context, listen: false).fetchNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                setState(() {});
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
          if (_searchController.text.isNotEmpty &&
              !note.title.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) &&
              !note.content.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  )) {
            return const SizedBox.shrink();
          }
          final preview = note.content.length > 50
              ? '${note.content.substring(0, 50)}…'
              : note.content;

          return Card(
            color: elementColor,
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
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
