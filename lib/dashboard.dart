import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sn/flashcards_all.dart';
import 'package:sn/flashcards_due.dart';
import 'package:sn/flashcards_new.dart';
import 'package:sn/notebook.dart';
import 'package:sn/pocketbase_auth.dart';
import 'package:sn/pocketbase_library.dart';
import 'package:badges/badges.dart' as badges;

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showModal = false;
  final _notebookNameController = TextEditingController();

  @override
  void dispose() {
    _notebookNameController.dispose();
    super.dispose();
  }

  void _handleAddNotebook() {
    setState(() {
      _showModal = true; // Show the modal
    });
  }

  void _createNotebook(PocketBaseLibraryNotifier library, String userId) async {
    final notebookName = _notebookNameController.text;
    await library.addNotebook(notebookName);

    // Close modal and clear the field
    setState(() {
      _showModal = false;
    });
    _notebookNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseAuthNotifier>(builder: (context, auth, child) {
      return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
          if (library.userId.isEmpty) {
            library.loadNotebooks(auth.userId);
            return Center(child: const Text('loading data'));
          } else {
            return Center(
              child: Container(
                width: 800,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('Notebooks'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _handleAddNotebook(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await auth.signOut();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                      child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap:
                              true, // Allow the list to shrink in height
                          itemCount: library.sortedNotebooks.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              key: ValueKey(library.sortedNotebooks[index].id),
                              title: Text(
                                library.sortedNotebooks[index].name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotebookPage(
                                        notebookId:
                                            library.sortedNotebooks[index].id),
                                  ),
                                );
                              },
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                    color: Color.fromARGB(255, 243, 246, 249),
                                    width: 2.0),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // NEW FLASHCARDS
                                  badges.Badge(
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor:
                                          Color.fromARGB(255, 0, 0, 128),
                                    ),
                                    badgeContent: Text(
                                      library.sortedNotebooks[index]
                                          .newFlashcards.length
                                          .toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.quiz,
                                        color: Color.fromARGB(255, 0, 0, 64),
                                      ),
                                      onPressed: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FlashcardNewView(
                                                    notebookId: library
                                                        .sortedNotebooks[index]
                                                        .id),
                                          ),
                                        )
                                      },
                                    ),
                                  ),
                                  // DUE FLASHCARDS
                                  badges.Badge(
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor:
                                          Color.fromARGB(255, 128, 0, 0),
                                    ),
                                    badgeContent: Text(
                                      library.sortedNotebooks[index]
                                          .dueFlashcards.length
                                          .toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.quiz,
                                        color: Color.fromARGB(255, 64, 0, 0),
                                      ),
                                      onPressed: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FlashcardDueView(
                                                    notebookId: library
                                                        .sortedNotebooks[index]
                                                        .id),
                                          ),
                                        )
                                      },
                                    ),
                                  ),
                                  // ALL FLASHCARDS
                                  badges.Badge(
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor:
                                          Color.fromARGB(255, 0, 128, 0),
                                    ),
                                    badgeContent: Text(
                                      library.sortedNotebooks[index]
                                          .allFlashcards.length
                                          .toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.quiz,
                                        color: Color.fromARGB(255, 0, 64, 0),
                                      ),
                                      onPressed: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FlashcardAllView(
                                                    notebookId: library
                                                        .sortedNotebooks[index]
                                                        .id),
                                          ),
                                        )
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )),

                  // The Modal
                  bottomSheet: _showModal
                      ? Padding(
                          padding: MediaQuery.of(context).viewInsets,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextField(
                                  controller: _notebookNameController,
                                  decoration: InputDecoration(
                                      hintText: 'Enter notebook name'),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 158, 183, 58),
                                ),
                                onPressed: () =>
                                    _createNotebook(library, auth.userId),
                                child: Text('Create Notebook'),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        )
                      : null, // Hide the modal when not visible
                ),
              ),
            );
          }
        },
      );
    });
  }
}
