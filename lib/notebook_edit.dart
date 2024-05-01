import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:sn/pocketbase_library.dart';

class NotebookEditPage extends StatefulWidget {
  final String notebookId;

  const NotebookEditPage({super.key, required this.notebookId});

  @override
  State<NotebookEditPage> createState() => _NotebookEditPageState();
}

class _NotebookEditPageState extends State<NotebookEditPage> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _errorOccurred = false;

  @override
  void initState() {
    super.initState();
    _loadNotebook();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNotebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pocketBaseLibrary =
          Provider.of<PocketBaseLibraryNotifier>(context, listen: false);
      final record = await pocketBaseLibrary.pb
          .collection('notebooks')
          .getOne(widget.notebookId);

      _nameController.text = record.getDataValue('name');
      _contentController.text = record.getDataValue('content');
    } catch (error) {
      setState(() {
        _errorOccurred = true;
      });
      print('Error loading notebook: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Notebook?'),
          content: const Text('Are you sure you want to delete this notebook?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                final library = Provider.of<PocketBaseLibraryNotifier>(context,
                    listen: false);

                await library.deleteNotebook(widget.notebookId);

                // Assuming successful deletion, navigate back:
                if (!library.errorOccurred) {
                  Navigator.popAndPushNamed(context, '/');
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
      builder: (context, library, child) {
        return Center(
          child: Container(
            width: 800,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Edit Notebook'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context),
                  ),
                  IconButton(
                    onPressed: () async {
                      await library.updateNotebook(widget.notebookId,
                          _nameController.text, _contentController.text);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                  ),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : library.errorOccurred
                      ? Center(child: Text(library.errorMessage))
                      : Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Notebook Name'),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter a name'
                                      : null,
                                ),
                                const SizedBox(height: 20.0),
                                Expanded(
                                  child: TextFormField(
                                    controller: _contentController,
                                    decoration: const InputDecoration(
                                        labelText: 'Notebook Content'),
                                    maxLines: null, // Make it multiline
                                    keyboardType: TextInputType.multiline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}
