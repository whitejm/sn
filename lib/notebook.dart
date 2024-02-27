import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:sn/notebook_edit.dart';
import 'package:sn/pocketbase_library.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotebookPage extends StatelessWidget {
  final String notebook_id;

  const NotebookPage({super.key, required this.notebook_id});

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
      print("test");
      print(notebook_id);
      // Find the notebook
      RecordModel? notebook;
      for (RecordModel record in library.notebooks) {
        if (record.id == notebook_id) {
          notebook = record;
          break;
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(notebook?.getDataValue('name') ?? 'Notebook'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotebookEditPage(notebookId: notebook_id),
                  ),
                );
              },
            ),
          ],
        ),
        body: notebook?.getDataValue('content') != null &&
                notebook?.getDataValue('content') != ""
            ? Markdown(data: notebook!.getDataValue('content'))
            : const Center(
                child: Text('Notebook is empty'),
              ),
      );
    });
  }
}
