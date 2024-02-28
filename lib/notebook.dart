import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:sn/notebook_edit.dart';
import 'package:sn/pocketbase_library.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotebookPage extends StatelessWidget {
  final String notebookId;

  const NotebookPage({super.key, required this.notebookId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(library.notebooks[notebookId]?.getDataValue('name') ??
              'Notebook'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotebookEditPage(notebookId: notebookId),
                  ),
                );
              },
            ),
          ],
        ),
        body: library.notebooks[notebookId]?.getDataValue('content') != null &&
                library.notebooks[notebookId]?.getDataValue('content') != ""
            ? Markdown(
                data: library.notebooks[notebookId]!.getDataValue('content'))
            : const Center(
                child: Text('Notebook is empty'),
              ),
      );
    });
  }
}
