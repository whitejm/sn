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

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
      builder: (context, library, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Notebook'),
            actions: [
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
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter a name' : null,
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
        );
      },
    );
  }
}
