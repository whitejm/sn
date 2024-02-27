import os
import pyperclip  # Make sure you install this: pip install pyperclip

preamble = """
I would like to have a conversation with you about an app I'm creating.

This is a study note app called subnotes. The app allows users to create notebooks. A notebook is a single markdown file. The app can parse notebooks for "flashcards." A flashcard is a nested blockquote parsed from a notebook file. The answer is in the first level blockquote and the answer is in the second level nested blockquote.

The app is a flutter app and uses pocketbase for the backend. Pocketbase will support the email + password authentication. Because the app will be published to both mobile and web, we will not be using Pocketbase's RealTime feature because it doesn't work on web. State management will be handled with Provider.

The following are user stories for the app. (checked user stories are completed)

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
  - [ ] I want to be able to change the notebooks name
  - [ ] I want to be able to delete a notebook
  - [ ] I want to be able to edit a notebook's content (markdown/text)
  - [ ] I want to see a list of my notebooks ordered by name
  - [ ] I want to view my notebooks as html (rendered from markdown)
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
  - user_id - a references user(id)
  - name - text
  - content - text
  - created - datetime (automatically created by database)
- flashcards (table)
  - id - text, primary key
  - due - datetime
  - user_id - a refrence to users(id)
  - notebook_id - a reference to notebooks(id)
  - question_sha512 - text
  - created - datetime (automatically created by database)
- reviews (table)
  - id - text, primary key
  - user_id - a refrence to users(id)
  - flashcard_id - a reference to flashcards(id)
  - created - datetime (automatically created by database)

  For parsing flashcards from notebooks, the notebooks should be converted to html from markdown first, and then the flashcards should be parsed with the notebooks DOM. Trying to use regex to parse the flashcards directly from markdown would be fragile and overly complicted. For example, you would have to consider all the different valid ways nested blockqoutes can be written in markdown.

  The flashcard's question, after being parsed, will be hash summed so they can be identified the next time the notebook is edited. If a user modifies a flashcard's question inside a notebook it will be considered a different flashcard.

  If a flashcard's "due" field is empty it will be considered "new." If a flashcards "due" field has a datetime in the past it will be considered "Due." If it is in the future it will be considerd "not due" and "not new."
  
  After a user has viewed a flashcard they can set the 'due' datetime to now, a user entered number of days using a textfield, or never.
 
  The following are the currect code files from the apps lib directory.

"""

def combine_dart_files(directory_path):
    """Combines all Dart files in a directory and puts the content in the clipboard."""
    combined_content = preamble

    for filename in os.listdir(directory_path):
        if filename.endswith(".dart"):
            filepath = os.path.join(directory_path, filename)
            with open(filepath, 'r') as file:
                combined_content += f"{filename}\n'''md\n" + file.read() + "\n'''\n\n"  # Add newlines between files

    pyperclip.copy(combined_content)
    print("Combined Dart code copied to clipboard!")

# Set the directory path
lib_directory = "./lib/"

# Call the function to combine and copy
combine_dart_files(lib_directory)


