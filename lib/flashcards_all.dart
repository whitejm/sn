import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import 'package:sn/pocketbase_library.dart';

class FlashcardAllView extends StatefulWidget {
  final String notebookId;

  const FlashcardAllView({Key? key, required this.notebookId})
      : super(key: key);

  @override
  _FlashcardAllViewState createState() => _FlashcardAllViewState();
}

class _FlashcardAllViewState extends State<FlashcardAllView> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PocketBaseLibraryNotifier>(
        builder: (context, library, child) {
      _flashcards = library.notebooks[widget.notebookId]?.allFlashcards ?? [];
      return Scaffold(
        appBar: AppBar(
            title: Text(
                'Flashcards for ${library.notebooks[widget.notebookId]?.name}')),
        body: (_flashcards.isEmpty)
            ? Center(child: Text("No Flashcards"))
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
                      IconButton(
                          onPressed: _handlePrevFlashcard,
                          icon: Icon(Icons.arrow_back)),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => showAnswer = !showAnswer),
                        child: Text(showAnswer ? 'Hide Answer' : 'Show Answer'),
                      ),
                      IconButton(
                          onPressed: _handleNextFlashcard,
                          icon: Icon(Icons.arrow_forward)),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  )
                ],
              ),
      );
    });
  }
}
