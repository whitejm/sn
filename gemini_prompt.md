I would like to have a conversation with you about an app I'm creating.

This is a study note app called subnotes. The app allows users to create notebooks. A notebook is a single markdown file. The app can parse notebooks for "flashcards." A flashcard is a nested blockquote parsed from a notebook file. The answer is in the first level blockquote and the answer is in the second level nested blockquote.

The app is a flutter app and uses pocketbase for the backend. Pocketbase will support the email + password authentication. Because the app will be published to both mobile and web, we will not be using Pocketbase's RealTime feature because it doesn't work on web. State management will be handled with Provider.

The following are user stories for the app. (checked user stories are completed). This is an MVP and at this time I do not want to add any features until the ones listed below are complete.

- App
  - I want to be able to use the app in a browser (Web app - https://subnotes.io)
  - I want to be able to use the app on a android phone (Android app)
- Accounts
  - [x] I want to be able to create an account with my email and a password
  - [x] I want to be able to login with my email and password
  - [x] I want to be able to reset my password
  - [x] I want to be able to logout
- Notebooks (markdown document)
  - [x] I want to be able to create a new notebook
  - [x] I want to be able to change the notebooks name
  - [x] I want to be able to delete a notebook
  - [x] I want to be able to edit a notebook's content (markdown/text)
  - [x] I want to see a list of my notebooks ordered by name
  - [x] I want to view my notebooks as html (rendered from markdown)
- Flashcards (question answer pairs parsed from notebooks)
  - [ ] I want to be able to review new (never have had a next review date set) flashcards from a notebook
  - [ ] I want to be able to review all flashcards from a notebook
  - [ ] I want to be able to review due (next review date is in the past) flashcards from a notebook
  - [ ] I want to be able to set a next review date on new and due flashcards after reviewing them
  - [ ] I want to be able to see how many times I have reviewd a flashcard 
  - [ ] I want to be able to see the last time I reviewd a flashcard

The following is an example of a notebook with a single flashcard in it.

```md
# this is a notebook

This part is not a flashcard because it is not a nested blockquote.

> this is the question side of a flashcard.
> > and this is the answer side of the flashcard.
```

The folowing nested list is a description of the database tables.

- user (table)
  - id - text, primary key
  - created - datetime (automatically created by database)
- notebooks (table)
  - id - text, primary key
  - userId - a references user(id)
  - name - text
  - content - text
  - created - datetime (automatically created by database)
- flashcards (table)
  - id - text, primary key
  - due - datetime
  - userId - a refrence to users(id)
  - notebookId - a reference to notebooks(id)
  - sha512 - text (sha512 digest of the question's html )
  - created - datetime (automatically created by database)
- reviews (table)
  - id - text, primary key
  - userId - a refrence to users(id)
  - flashcardId - a reference to flashcards(id)
  - created - datetime (automatically created by database)

The flashcard's question, after being parsed, will be hash summed so they can be identified the next time the notebook is edited. If a user modifies a flashcard's question inside a notebook it will be considered a different flashcard.

If a flashcard's "due" field is empty it will be considered "new." If a flashcards "due" field has a datetime in the past it will be considered "Due." If it is in the future it will be considerd "not due" and "not new."

Flashcard Parsing: 

I need to parse flashcards (question and answer pairs) out of the markdown files. In the future I might use one of flutters markdown packages for parsing flashcards, but their documentation is poor. So for now we need to write a parsing function that keeps the contents of the question and answer in markdown. 


In the main dashboard/library each noteobook ListTile should have three flashcard buttons. All (Green), New (Blue), and Due (Red). "All" is all flashcards in the notebook, wether they are new, due, or not new and not due. "New" are flashcards that have had no due date set in the flaschards table. The buttons should use the "quiz" icon and with a colored badge. If a notebook has 20 total flashcards the "All" quiz icon button should have a green badge with the number 20 in it. If the notebook as 3 new flashcards the "New" quiz icon button should have a blue badge with the number 3 in it. If the notebook has 5 due flashcards the "Due" quiz icon button should have a red badge with the number 5 in it. If there are no flashcards in a notebook the All button should be disabled. If there are no new flashcards in the notebook the new button should be disabled. If there are no due flashcards in the notebook the due button should be disabled.

After a user has viewed a flashcard they can set the 'due' datetime to now, a user entered number of days using a textfield, or never.
 
The repos is located here... `https://github.com/whitejm/sn`

Flashcards (question answer pairs) are made with blockquotes. The question is in the first level blockquote and the answer is in the nested blockquote.
 
```md

> this is a question
> > this is an answer

> this is not a question or answer because there is no nested 

> > this is not an answer because there is no content in first level blockquote

```


```dart
class QA {
  final String question;
  final String answer;

  // Constructor to initialize question and answer
  QA({required this.question, required this.answer});
}

List<QA> parseNotebook(String md) {
  String potentialQ;
  String potentialA;
  List<QA> qas = [];
  bool blockQuote = false;
  bool nestedBlockQoute = false;
  bool codeFence = false;

  // loop through each line in md and get QAs 

}
```

Please help me finish the parseNotebook function. blockquotes inside code fences should be ignored. https://spec.commonmark.org/0.31.2/ has rules on blockquotes and code fences.