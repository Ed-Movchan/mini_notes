// Import necessary packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Note model
part 'main.g.dart';

@HiveType(typeId: 0)
class Note {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String group;

  Note({
    required this.title,
    required this.content,
    required this.group,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter()); // Ensure this matches the generated adapter class name
  await Hive.openBox<Note>('notes');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box<Note> notesBox = Hive.box<Note>('notes');
  String filterGroup = "All";

  void _addNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddNoteForm(
            onSave: (title, content, group) {
              final newNote = Note(title: title, content: content, group: group);
              notesBox.add(newNote);
              setState(() {}); // Refresh the screen
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _deleteNoteAt(int index) {
    final key = notesBox.keyAt(index); // Get the key for the note
    notesBox.delete(key); // Delete the note by key
    setState(() {}); // Refresh the screen
  }

  @override
  Widget build(BuildContext context) {
    final notes = filterGroup == "All"
        ? notesBox.values.toList()
        : notesBox.values.where((note) => note.group == filterGroup).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mini Notes'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String group) {
              setState(() {
                filterGroup = group;
              });
            },
            itemBuilder: (BuildContext context) {
              return ["All", "Work", "Personal", "Others"].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing: $filterGroup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${notes.length} Notes',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: notesBox.listenable(),
              builder: (context, Box<Note> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Text('No notes yet!'),
                  );
                }
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Dismissible(
                      key: UniqueKey(), // Ensure a unique key for each item
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNoteAt(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Note deleted')),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(note.content),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddNoteForm extends StatefulWidget {
  final Function(String, String, String) onSave;

  AddNoteForm({required this.onSave});

  @override
  _AddNoteFormState createState() => _AddNoteFormState();
}

class _AddNoteFormState extends State<AddNoteForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedGroup = "Work";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              items: ["Work", "Personal", "Others"].map((String group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Group'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _titleController.text,
                  _contentController.text,
                  _selectedGroup,
                );
              },
              child: Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
