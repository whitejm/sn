import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sn/notebook.dart';
import 'package:sn/pocketbase_auth.dart';
import 'package:sn/pocketbase_library.dart';

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
          if (library.notebooks.isEmpty) {
            library.loadNotebooks(auth.userId);
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Dashboard'),
            ),
            body: Center(
                child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true, // Allow the list to shrink in height
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
                      );
                    },
                  ),
                ),
                ElevatedButton(
                    onPressed: _handleAddNotebook, child: Text("Add Notebook")),
                ElevatedButton(
                  onPressed: () async {
                    await auth.signOut();
                  },
                  child: Text("Logout"),
                )
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
                          onPressed: () =>
                              _createNotebook(library, auth.userId),
                          child: Text('Create Notebook'),
                        ),
                      ],
                    ),
                  )
                : null, // Hide the modal when not visible
          );
        },
      );
    });
  }
}
