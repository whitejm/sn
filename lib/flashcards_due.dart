import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import 'package:sn/pocketbase_library.dart';

class FlashcardDueView extends StatefulWidget {
  final String notebookId;

  const FlashcardDueView({Key? key, required this.notebookId})
      : super(key: key);

  @override
  _FlashcardDueViewState createState() => _FlashcardDueViewState();
}

class _FlashcardDueViewState extends State<FlashcardDueView> {
  bool showAnswer = false;
  int flashcardIndex = 0;
  List<String> _flashcards = [];

  void _handleNextFlashcard() {
    setState(() {
      if (flashcardIndex < _flashcards.length - 1) {
        flashcardIndex++;
      } else {
        // Reset to the beginning or handle end of deck
      }
      showAnswer = false;
    });
  }

  void _handlePrevFlashcard() {
    setState(() {
      if (flashcardIndex > 0) {
        flashcardIndex--;
      } else {
        // Reset to the beginning or handle end of deck
      }
      showAnswer = false;
    });
  }

  void _handleDue(int days, PocketBaseLibraryNotifier library) {
    library.setDueDate(_flashcards[flashcardIndex], days);
    setState(() {
      showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
      _flashcards = library.notebooks[widget.notebookId]?.dueFlashcards ?? [];
      return Scaffold(
        appBar: AppBar(
            title: Text(
                'Flashcards: ${library.notebooks[widget.notebookId]?.name}')),
        body: (_flashcards.isEmpty)
            ? Center(child: Text("No Due Flashcards"))
            : Column(
                children: [
                  Expanded(
                    child: Markdown(
                        data: showAnswer
                            ? library
                                .flashcards[_flashcards[flashcardIndex]]!.answer
                            : library.flashcards[_flashcards[flashcardIndex]]!
                                .question),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!showAnswer) ...[
                        IconButton(
                            onPressed: _handlePrevFlashcard,
                            icon: Icon(Icons.arrow_back)),
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => showAnswer = !showAnswer),
                          child:
                              Text(showAnswer ? 'Hide Answer' : 'Show Answer'),
                        ),
                        IconButton(
                            onPressed: _handleNextFlashcard,
                            icon: Icon(Icons.arrow_forward)),
                      ],
                      if (showAnswer) ...[
                        ElevatedButton(
                            onPressed: () => _handleDue(0, library),
                            child: Text('Now')),
                        ElevatedButton(
                            onPressed: () => _handleDue(1, library),
                            child: Text('Day')),
                        ElevatedButton(
                            onPressed: () => _handleDue(7, library),
                            child: Text('Week')),
                        ElevatedButton(
                            onPressed: () => _handleDue(30, library),
                            child: Text('Month')),
                      ]
                    ],
                  ),
                  if (showAnswer) ...[
                    Text(library.flashcards[_flashcards[flashcardIndex]]
                            ?.reviewHistory ??
                        "no review history found")
                  ],
                  const SizedBox(
                    height: 20,
                  )
                ],
              ),
      );
    });
  }
}
