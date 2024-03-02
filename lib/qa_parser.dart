class QA {
  final String question;
  final String answer;

  // Constructor to initialize question and answer
  QA({required this.question, required this.answer});
}

List<QA> parseQAsFromMD(String md) {
  List<QA> qas = [];
  bool blockQuote = false;
  bool nestedBlockQuote = false;
  bool codeFence = false;
  String potentialQ = '';
  String potentialA = '';
  const String newline = '\n';

  // this isn't 100% compliant, but good enough for now - https://spec.commonmark.org/
  final codeFenceRegex = RegExp(r'^\s{0,3}[`|~]{3}(?![`|~]).*');
  final blockQuoteRegex = RegExp(r'^\s{0,3}>((?!\s*>).*)');
  final nestedBlockQuoteRegex = RegExp(r'^\s{0,3}>\s{0,3}>((?!\s*>).*)');
  final lazyContinuationRegex = RegExp(r'^(\s*\w+.*)');

  // add newline to md so QAs at end of file are processed
  md += newline;
  // Split the Markdown content by lines for processing
  for (String line in md.split('\n')) {
    //print('blockquote: ${blockQuote ? 'true' : 'false'} | nestedBlockquote: ${nestedBlockQuote ? 'true' : 'false'} |  codeFence: ${codeFence ? 'true' : 'false'} | processing line...');
    //print(line);
    // Code fence handling
    if (codeFenceRegex.hasMatch(line)) {
      codeFence = !codeFence; // Toggle code fence status
    }

    // Ignore lines if within a code fence
    if (codeFence) {
      blockQuote = false;
      nestedBlockQuote = false;
      continue;
    }

    // block quote start check
    if (!blockQuote && !nestedBlockQuote && blockQuoteRegex.hasMatch(line)) {
      potentialQ += blockQuoteRegex.firstMatch(line)!.group(1)! + newline;
      blockQuote = true;
      continue;
    }
    // block quote continuation check
    if (blockQuote && blockQuoteRegex.hasMatch(line)) {
      potentialQ += blockQuoteRegex.firstMatch(line)!.group(1)! + newline;
      continue;
    }
    // block quote lazy continuation check
    if (blockQuote && lazyContinuationRegex.hasMatch(line)) {
      print('blockquote lazy');
      potentialQ += lazyContinuationRegex.firstMatch(line)!.group(1)! + newline;
      continue;
    }
    // nested block quote start check (only care about nested blockquotes that have a line in parent blockquote)
    if (blockQuote && nestedBlockQuoteRegex.hasMatch(line)) {
      potentialA += nestedBlockQuoteRegex.firstMatch(line)!.group(1)! + newline;
      blockQuote = false;
      nestedBlockQuote = true;
      continue;
    }
    // nested block quote continuation check
    if (nestedBlockQuote && nestedBlockQuoteRegex.hasMatch(line)) {
      potentialA += nestedBlockQuoteRegex.firstMatch(line)!.group(1)! + newline;
      continue;
    }
    // nested block quote lazy continuation checks
    if (nestedBlockQuote && lazyContinuationRegex.hasMatch(line)) {
      print('nested blockquote lazy');
      potentialA += lazyContinuationRegex.firstMatch(line)!.group(1)! + newline;
      continue;
    }
    if (nestedBlockQuote && blockQuoteRegex.hasMatch(line)) {
      potentialA += blockQuoteRegex.firstMatch(line)!.group(1)! + newline;
      continue;
    }
    // save
    if (potentialA.isNotEmpty && potentialQ.isNotEmpty) {
      qas.add(
          QA(answer: potentialA.trimRight(), question: potentialQ.trimRight()));
    }
    // reset
    blockQuote = false;
    nestedBlockQuote = false;
    potentialQ = "";
    potentialA = "";
  }
  return qas;
}
