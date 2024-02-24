import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sn/pocketbase_auth.dart';
import 'package:sn/pocketbase_library.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
      if (library.notebooks.isEmpty) {
        library.loadNotebooks();
      }
      return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
          ),
          body: Center(
            child: Column(children: [
              Expanded(
                child: ListView.builder(
                  itemCount: library.notebooks.length,
                  itemBuilder: (context, index) {
                    return Container(
                      child: Text(
                        library.notebooks[index].getStringValue('name'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                  onPressed: () async {
                    await library.addNotebook("NOTEBOOK NAME");
                    library.loadNotebooks();
                  },
                  child: Text("Add Notebook")),
              Consumer<PocketBaseAuthNotifier>(builder: (context, auth, child) {
                return ElevatedButton(
                  onPressed: () async {
                    await auth.signOut();
                  },
                  child: Text("Logout"),
                );
              }),
            ]),
          ));
    });
  }
}
