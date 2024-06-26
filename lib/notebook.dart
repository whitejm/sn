import 'package:flutter/material.dart';
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
      return Center(
        child: Container(
          width: 800.0,
          child: Scaffold(
            appBar: AppBar(
              title: Text(library.notebooks[notebookId]?.name ?? 'Notebook'),
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
            body: library.notebooks[notebookId]?.content != null &&
                    library.notebooks[notebookId]?.content != ""
                ? Markdown(data: library.notebooks[notebookId]!.content)
                : const Center(
                    child: Text('Notebook is empty'),
                  ),
          ),
        ),
      );
    });
  }
}
