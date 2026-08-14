import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Data model for the in-app User Manual.
///
/// All content is bundled locally (offline-first).  Each [ManualSection]
/// represents a top-level guide (Getting Started, Library, Flashcards, etc.).
/// Sections contain [ManualTopic]s which hold the actual step-by-step
/// instructions, notes, and tips rendered by the guide screens.
///
/// The [ManualContent] class provides the full content tree and a flat
/// list used by the search index.

/// A single step in a numbered how-to list.
class ManualStep {
  final String title;
  final String description;

  const ManualStep({required this.title, required this.description});
}

/// A key-value pair rendered as a row in a comparison/info table.
class ManualInfoRow {
  final String label;
  final String value;

  const ManualInfoRow({required this.label, required this.value});
}

/// A troubleshooting FAQ item with symptom / cause / solution.
class ManualTroubleshootingItem {
  final String question;
  final String symptom;
  final String cause;
  final String solution;

  const ManualTroubleshootingItem({
    required this.question,
    required this.symptom,
    required this.cause,
    required this.solution,
  });
}

/// A sub-topic within a manual section.  Holds the rich content blocks
/// that the guide screen renders.
class ManualTopic {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> bulletPoints;
  final List<ManualStep> steps;
  final List<ManualInfoRow> infoTable;
  final String? note;
  final String? tip;
  final List<ManualTroubleshootingItem> troubleshooting;

  const ManualTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon = Icons.help_outline,
    this.bulletPoints = const [],
    this.steps = const [],
    this.infoTable = const [],
    this.note,
    this.tip,
    this.troubleshooting = const [],
  });
}

/// A top-level manual section (e.g. "Getting Started", "Study Mode").
class ManualSection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? intro;
  final List<ManualTopic> topics;
  final List<ManualTroubleshootingItem> troubleshooting;
  final List<ManualStep> quickStartSteps;
  final List<String> bestPractices;

  const ManualSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.intro,
    this.topics = const [],
    this.troubleshooting = const [],
    this.quickStartSteps = const [],
    this.bestPractices = const [],
  });
}

/// A single search hit returned by [ManualContent.search].
class ManualSearchResult {
  final String sectionId;
  final String sectionTitle;
  final String topicId;
  final String topicTitle;
  final String topicSubtitle;
  final IconData icon;
  final Color iconColor;
  final String matchedSnippet;

  const ManualSearchResult({
    required this.sectionId,
    required this.sectionTitle,
    required this.topicId,
    required this.topicTitle,
    required this.topicSubtitle,
    required this.icon,
    required this.iconColor,
    required this.matchedSnippet,
  });
}

/// Central content provider for the User Manual.
///
/// All content is defined as `const` lists so there is zero runtime
/// allocation cost — the entire manual is compiled into the app binary
/// and works fully offline.
class ManualContent {
  ManualContent._();

  static const String appTagline =
      'Offline study companion with AI-powered question generation';

  /// All manual sections in display order.
  static const List<ManualSection> sections = [
    _gettingStarted,
    _library,
    _flashcards,
    _studyMode,
    _examMode,
    _aiGenerate,
    _backupRestore,
    _security,
    _analytics,
    _troubleshooting,
  ];

  // ─────────────────────────────────────────────────────────────────────
  //  Section 1 — Getting Started
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _gettingStarted = ManualSection(
    id: 'getting-started',
    title: 'Getting Started',
    subtitle: 'Learn the basics and take your first steps',
    icon: Icons.rocket_launch_outlined,
    iconColor: AppTheme.bambooGreen600,
    intro:
        'QuizSnap is an offline-first flashcard and study application. '
        'Your data stays on your device in a local SQLite database. '
        'AI features (question generation) require internet and a Groq API key; '
        'everything else works completely offline.',
    quickStartSteps: [
      ManualStep(
        title: 'Create a folder',
        description:
            'Open the Library tab, tap the folder icon, and create a folder '
            'to organise your decks (e.g. "Biology", "Math 101").',
      ),
      ManualStep(
        title: 'Create a deck',
        description:
            'Inside a folder (or the root library), tap "+" to create a new '
            'deck. Give it a name and optional description.',
      ),
      ManualStep(
        title: 'Add flashcards',
        description:
            'Open the deck, tap "Add Flashcard", choose a question type '
            '(Identification, Enumeration, or Multiple Choice), and fill in '
            'the question and answer.',
      ),
      ManualStep(
        title: 'Start studying',
        description:
            'Go to the Study tab, select your deck, and flip through cards. '
            'Tap to reveal the answer, then rate your recall.',
      ),
      ManualStep(
        title: 'Take an exam',
        description:
            'From a deck, tap "Exam", set a time limit, and answer all '
            'questions. Review your score and explanations afterwards.',
      ),
      ManualStep(
        title: 'Backup your data',
        description:
            'Go to Settings → Backup & Restore and create a .db backup file. '
            'Store it in a safe location or share it to cloud storage.',
      ),
    ],
    topics: [
      ManualTopic(
        id: 'what-is-quizsnap',
        title: 'What is QuizSnap?',
        subtitle: 'A complete study toolkit in your pocket',
        icon: Icons.info_outline,
        bulletPoints: [
          'Create and organise flashcards with three question types',
          'Study with card-flip mode, shuffle, and bookmarks',
          'Take timed exams with automatic scoring',
          'Generate questions from PDFs, documents, and images using AI',
          'Track progress with detailed analytics',
          'Secure your app with PIN lock and inactivity timeout',
          'Backup and restore your data locally',
        ],
      ),
      ManualTopic(
        id: 'offline-first',
        title: 'Offline-First Architecture',
        subtitle: 'Your data never leaves your device',
        icon: Icons.offline_bolt_outlined,
        bulletPoints: [
          'All flashcards, decks, folders, and study data are stored in a local SQLite database',
          'No account, login, or internet connection required for core features',
          'Study mode, exam mode, and analytics work fully offline',
          'Backups are saved as .db files on your device storage',
          'API keys are encrypted using Flutter Secure Storage',
        ],
        note:
            'The only feature that requires internet is AI question generation, '
            'which sends your text to Groq\'s servers using your own API key.',
      ),
      ManualTopic(
        id: 'ai-requires-internet',
        title: 'AI Features Require Internet',
        subtitle: 'Question generation uses the Groq API',
        icon: Icons.wifi_outlined,
        bulletPoints: [
          'AI Generate sends your source text to Groq\'s API',
          'You need a free Groq API key (Settings → API Configuration)',
          'A daily quota limits how many questions you can generate',
          'All other app features work without internet',
        ],
        tip: 'Get a free API key at console.groq.com. It only takes a minute.',
      ),
      ManualTopic(
        id: 'recommended-first-steps',
        title: 'Recommended First Steps',
        subtitle: 'Get productive in minutes',
        icon: Icons.checklist_outlined,
        steps: [
          ManualStep(
            title: 'Set up your library',
            description:
                'Create folders for your subjects, then create decks inside them.',
          ),
          ManualStep(
            title: 'Add a few flashcards manually',
            description:
                'Try all three question types to see which works best for you.',
          ),
          ManualStep(
            title: 'Run a study session',
            description:
                'Flip through cards and rate your recall to build analytics data.',
          ),
          ManualStep(
            title: 'Take a practice exam',
            description:
                'Test yourself with a timed exam to see your score and review explanations.',
          ),
          ManualStep(
            title: 'Create a backup',
            description:
                'Protect your data by creating a backup file in Settings → Backup & Restore.',
          ),
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 2 — Library & Decks
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _library = ManualSection(
    id: 'library',
    title: 'Library & Decks',
    subtitle: 'Organise your study material',
    icon: Icons.library_books_outlined,
    iconColor: AppTheme.blue600,
    intro:
        'The Library is where you manage folders, decks, and flashcards. '
        'Use folders to group decks by subject, and decks to hold sets of '
        'flashcards. Search, filter, sort, and bookmark tools help you find '
        'what you need quickly.',
    topics: [
      ManualTopic(
        id: 'library-screen',
        title: 'Library Screen',
        subtitle: 'The main hub for your study content',
        icon: Icons.library_books_outlined,
        bulletPoints: [
          'Accessed from the bottom navigation bar (Library tab)',
          'Shows all folders and decks in a grid or list',
          'Tap a folder to view its decks',
          'Tap a deck to view its flashcards',
          'Use the search bar to find decks by name',
        ],
      ),
      ManualTopic(
        id: 'folders',
        title: 'Folders',
        subtitle: 'Group decks by subject or category',
        icon: Icons.folder_outlined,
        steps: [
          ManualStep(
            title: 'Create a folder',
            description:
                'Tap the folder icon in the Library, then "Create Folder". '
                'Enter a name and optional description.',
          ),
          ManualStep(
            title: 'Open a folder',
            description: 'Tap any folder to see the decks inside it.',
          ),
          ManualStep(
            title: 'Move a deck to a folder',
            description:
                'From a deck\'s options menu, select "Move to Folder" and '
                'choose the destination folder.',
          ),
          ManualStep(
            title: 'Delete a folder',
            description:
                'Open the folder, tap the delete option. Decks inside are '
                'moved to trash, not permanently deleted.',
          ),
        ],
      ),
      ManualTopic(
        id: 'decks',
        title: 'Decks',
        subtitle: 'Collections of flashcards for a topic',
        icon: Icons.style_outlined,
        steps: [
          ManualStep(
            title: 'Create a deck',
            description:
                'In the Library, tap "+" or "Create Deck". Enter a name, '
                'description, and optionally assign it to a folder.',
          ),
          ManualStep(
            title: 'Edit a deck',
            description:
                'Open the deck, tap the edit icon. Update the name, '
                'description, or folder assignment.',
          ),
          ManualStep(
            title: 'Delete a deck',
            description:
                'From the deck\'s options menu, select "Delete". The deck '
                'and its flashcards are moved to trash and can be restored.',
          ),
          ManualStep(
            title: 'Restore from Trash',
            description:
                'Go to Settings → Trash (or the Trash route). Select the '
                'deleted deck and tap "Restore" to bring it back.',
          ),
        ],
      ),
      ManualTopic(
        id: 'search-filter-sort',
        title: 'Search, Filter & Sort',
        subtitle: 'Find decks and flashcards fast',
        icon: Icons.search_outlined,
        bulletPoints: [
          'Use the search bar in the Library to find decks by name',
          'Global Search (magnifying glass icon) searches across all decks and flashcards',
          'Filter decks by folder, tag, or mastery level',
          'Sort decks by name, creation date, or card count',
          'Bookmark important flashcards for quick access (Study → Bookmarks)',
        ],
      ),
      ManualTopic(
        id: 'trash',
        title: 'Trash & Recovery',
        subtitle: 'Deleted items are recoverable',
        icon: Icons.delete_outline,
        bulletPoints: [
          'Deleted decks, flashcards, and folders go to Trash first',
          'Open Trash from Settings → Data Management → Trash',
          'Restore items individually or empty trash permanently',
          'Trash Settings let you configure auto-cleanup intervals',
          'Once trash is emptied, items cannot be recovered',
        ],
        note:
            'Always create a backup before emptying trash if you\'re unsure.',
      ),
      ManualTopic(
        id: 'move-flashcards',
        title: 'Move Flashcards Between Decks',
        subtitle: 'Reorganise your cards',
        icon: Icons.swap_horiz,
        steps: [
          ManualStep(
            title: 'Select flashcards',
            description:
                'In the flashcard list, long-press or use multi-select to '
                'choose the cards you want to move.',
          ),
          ManualStep(
            title: 'Tap "Move"',
            description:
                'Select "Move to Deck" from the action bar.',
          ),
          ManualStep(
            title: 'Choose destination',
            description:
                'Pick the target deck from the list. The flashcards are '
                'transferred immediately.',
          ),
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 3 — Flashcard Creation
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _flashcards = ManualSection(
    id: 'flashcards',
    title: 'Flashcard Creation',
    subtitle: 'Three question types for effective learning',
    icon: Icons.style_outlined,
    iconColor: AppTheme.purple600,
    intro:
        'QuizSnap supports three manual flashcard question types: '
        'Identification, Enumeration, and Multiple Choice. Each type has '
        'dedicated fields and is rendered appropriately in study and exam modes.',
    topics: [
      ManualTopic(
        id: 'identification',
        title: 'Identification',
        subtitle: 'Short, direct-answer questions',
        icon: Icons.short_text,
        bulletPoints: [
          'A question with a single short answer',
          'Best for definitions, terms, and facts',
          'Example: Q: "Capital of France?" A: "Paris"',
          'In exam mode, you type the answer in a text field',
        ],
        steps: [
          ManualStep(
            title: 'Open the flashcard form',
            description:
                'In a deck, tap "Add Flashcard". The form defaults to '
                'Identification type.',
          ),
          ManualStep(
            title: 'Enter the question',
            description: 'Type your question in the "Question" field.',
          ),
          ManualStep(
            title: 'Enter the answer',
            description: 'Type the expected answer in the "Answer" field.',
          ),
          ManualStep(
            title: 'Add an explanation (optional)',
            description:
                'Provide context that is shown after answering in exam mode.',
          ),
          ManualStep(
            title: 'Save',
            description: 'Tap "Save" to add the flashcard to the deck.',
          ),
        ],
      ),
      ManualTopic(
        id: 'enumeration',
        title: 'Enumeration',
        subtitle: 'List-based answers with multiple items',
        icon: Icons.format_list_numbered,
        bulletPoints: [
          'A question that requires listing multiple items',
          'Best for "Name the three branches of government" style questions',
          'Each item is stored separately and revealed individually',
          'In exam mode, you add items one at a time',
          'Items are stored as a JSON array in the database',
        ],
        steps: [
          ManualStep(
            title: 'Select "Enumeration" type',
            description:
                'In the flashcard form, tap the "Enumeration" chip.',
          ),
          ManualStep(
            title: 'Enter the question',
            description: 'Type the question that asks for a list.',
          ),
          ManualStep(
            title: 'Add enumeration items',
            description:
                'Tap "Add Item" for each list entry. Add as many as needed.',
          ),
          ManualStep(
            title: 'Save',
            description: 'Tap "Save". Items are stored as a JSON array.',
          ),
        ],
      ),
      ManualTopic(
        id: 'multiple-choice',
        title: 'Multiple Choice',
        subtitle: 'Question with four options (A–D) and one correct answer',
        icon: Icons.check_circle_outline,
        bulletPoints: [
          'A question with four options labelled A, B, C, D',
          'Exactly one option is marked as correct',
          'Best for exam-style MCQ practice',
          'In study mode, all four options are shown on reveal',
          'In exam mode, you tap the option you believe is correct',
        ],
        steps: [
          ManualStep(
            title: 'Select "Multiple Choice" type',
            description:
                'In the flashcard form, tap the "Multiple Choice" chip.',
          ),
          ManualStep(
            title: 'Enter the question',
            description: 'Type the MCQ question.',
          ),
          ManualStep(
            title: 'Fill in options A–D',
            description:
                'Enter text for all four options. Leave unused options blank '
                'only if you have fewer than four (not recommended).',
          ),
          ManualStep(
            title: 'Mark the correct option',
            description:
                'Tap the radio button next to the correct option (A, B, C, or D).',
          ),
          ManualStep(
            title: 'Save',
            description:
                'Tap "Save". The correct option letter is stored in the '
                'correctOption column.',
          ),
        ],
      ),
      ManualTopic(
        id: 'question-type-comparison',
        title: 'Question Type Comparison',
        subtitle: 'Choose the right type for your content',
        icon: Icons.compare_arrows_outlined,
        infoTable: [
          ManualInfoRow(label: 'Type', value: 'Identification'),
          ManualInfoRow(label: 'Best for', value: 'Definitions, terms, facts'),
          ManualInfoRow(label: 'Answer format', value: 'Single short text'),
          ManualInfoRow(label: 'Exam input', value: 'Text field'),
          ManualInfoRow(label: '', value: ''),
          ManualInfoRow(label: 'Type', value: 'Enumeration'),
          ManualInfoRow(label: 'Best for', value: 'Lists, steps, sequences'),
          ManualInfoRow(label: 'Answer format', value: 'Multiple items'),
          ManualInfoRow(label: 'Exam input', value: 'Add-item list'),
          ManualInfoRow(label: '', value: ''),
          ManualInfoRow(label: 'Type', value: 'Multiple Choice'),
          ManualInfoRow(label: 'Best for', value: 'Exam-style practice'),
          ManualInfoRow(label: 'Answer format', value: 'A/B/C/D options'),
          ManualInfoRow(label: 'Exam input', value: 'Tap to select'),
        ],
      ),
      ManualTopic(
        id: 'edit-delete-bookmark',
        title: 'Edit, Delete & Bookmark Flashcards',
        subtitle: 'Manage your cards',
        icon: Icons.edit_outlined,
        bulletPoints: [
          'Edit: Tap a flashcard in the list, then the edit icon',
          'Delete: Use the delete option — cards go to Trash first',
          'Bookmark: Tap the bookmark icon on a card to save it for quick access',
          'Bookmarked cards are available in Study → Bookmarks',
          'Move: Select cards and use "Move to Deck" to reorganise',
        ],
      ),
      ManualTopic(
        id: 'explanations',
        title: 'Explanations',
        subtitle: 'Add context to your answers',
        icon: Icons.lightbulb_outline,
        bulletPoints: [
          'Optional field available on all question types',
          'Shown after answering in exam mode (on the review screen)',
          'Shown when revealing a card in study mode',
          'Best used for "why" the answer is correct',
          'AI-generated flashcards include explanations automatically',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 4 — Study Mode
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _studyMode = ManualSection(
    id: 'study-mode',
    title: 'Study Mode',
    subtitle: 'Flip cards, reveal answers, track progress',
    icon: Icons.school_outlined,
    iconColor: AppTheme.emerald600,
    intro:
        'Study Mode is your day-to-day learning tool. Flip through flashcards, '
        'reveal answers when ready, and rate your recall. The study timer and '
        'session tracking feed into your analytics dashboard.',
    topics: [
      ManualTopic(
        id: 'card-flipping',
        title: 'Card Flipping & Reveal',
        subtitle: 'Answers are hidden until you choose to reveal them',
        icon: Icons.flip_outlined,
        bulletPoints: [
          'The question side is shown first',
          'Tap the card (or the reveal button) to flip and see the answer',
          'For Multiple Choice, all four options are shown on reveal',
          'For Enumeration, all items are listed on reveal',
          'Answers are never shown automatically — you control the pace',
        ],
      ),
      ManualTopic(
        id: 'navigation',
        title: 'Next / Previous & Shuffle',
        subtitle: 'Navigate through your deck',
        icon: Icons.swap_horiz,
        bulletPoints: [
          'Use the next/previous arrows to move between cards',
          'Shuffle button randomises card order for the session',
          'Progress indicator shows current card / total cards',
          'Swipe gestures supported for next/previous',
        ],
      ),
      ManualTopic(
        id: 'bookmarks',
        title: 'Bookmarks',
        subtitle: 'Save important cards for quick access',
        icon: Icons.bookmark_border_outlined,
        bulletPoints: [
          'Tap the bookmark icon on any card to bookmark it',
          'Access all bookmarks from Study → Bookmarks',
          'Bookmarks work across all decks',
          'Use bookmarks to flag difficult cards for review',
        ],
      ),
      ManualTopic(
        id: 'study-timer',
        title: 'Study Timer & Session Tracking',
        subtitle: 'Your study time is recorded automatically',
        icon: Icons.timer_outlined,
        bulletPoints: [
          'A timer runs while you are actively studying',
          'Study sessions are saved to the database',
          'Session data feeds the analytics dashboard',
          'Total study time, cards studied, and streaks are tracked',
          'Timer pauses when the app is backgrounded',
        ],
        note:
            'Focus mode (active during study sessions) suspends the '
            'inactivity lock so your session is never interrupted.',
      ),
      ManualTopic(
        id: 'analytics-updates',
        title: 'Analytics Updates',
        subtitle: 'Study activity feeds your dashboard',
        icon: Icons.analytics_outlined,
        bulletPoints: [
          'Each card you study updates your analytics',
          'Daily activity, study time, and card counts update in real time',
          'Streaks are calculated from consecutive study days',
          'Deck mastery improves as you rate your recall',
        ],
      ),
      ManualTopic(
        id: 'best-practices',
        title: 'Best Study Practices',
        subtitle: 'Get the most out of Study Mode',
        icon: Icons.tips_and_updates_outlined,
        bulletPoints: [
          'Study in short, focused sessions (15–25 minutes)',
          'Always try to recall the answer before revealing it',
          'Use shuffle to avoid memorising card order',
          'Bookmark difficult cards and review them more frequently',
          'Study daily to maintain your streak',
          'Mix question types in a deck for varied practice',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 5 — Exam Mode
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _examMode = ManualSection(
    id: 'exam-mode',
    title: 'Exam Mode',
    subtitle: 'Timed tests with automatic scoring',
    icon: Icons.quiz_outlined,
    iconColor: AppTheme.amber600,
    intro:
        'Exam Mode turns your decks into timed tests. Answers are not shown '
        'during the exam — you answer all questions, then review your score '
        'and explanations afterwards. Mixed-format decks use each card\'s '
        'stored question type.',
    topics: [
      ManualTopic(
        id: 'setup',
        title: 'Setting Up an Exam',
        subtitle: 'Choose a deck and configure the exam',
        icon: Icons.settings_outlined,
        steps: [
          ManualStep(
            title: 'Open a deck',
            description:
                'Navigate to the deck you want to be tested on.',
          ),
          ManualStep(
            title: 'Tap "Exam"',
            description:
                'This opens the exam setup screen with configuration options.',
          ),
          ManualStep(
            title: 'Set a time limit',
            description:
                'Choose how long you have (e.g. 10, 20, 30 minutes). '
                'A countdown timer runs during the exam.',
          ),
          ManualStep(
            title: 'Enable shuffle (optional)',
            description:
                'Shuffle question order for a more realistic exam experience.',
          ),
          ManualStep(
            title: 'Start the exam',
            description:
                'Tap "Start". A countdown screen appears, then the exam begins.',
          ),
        ],
      ),
      ManualTopic(
        id: 'answering',
        title: 'Answering Questions',
        subtitle: 'Each question type has a different input method',
        icon: Icons.edit_note_outlined,
        bulletPoints: [
          'Identification: Type your answer in a text field',
          'Enumeration: Add items one at a time using the add-item button',
          'Multiple Choice: Tap the option (A, B, C, or D) you think is correct',
          'Answers are saved automatically as you go',
          'You can navigate between questions using next/previous',
        ],
        note:
            'Answers are NOT shown during the exam. You only see correct '
            'answers and explanations on the review screen after submission.',
      ),
      ManualTopic(
        id: 'mixed-format',
        title: 'Mixed-Format Exams',
        subtitle: 'Decks with multiple question types',
        icon: Icons.shuffle_outlined,
        bulletPoints: [
          'If a deck contains cards of different types, the exam includes all of them',
          'Each card is rendered according to its stored questionType',
          'The exam adapts the input field for each question automatically',
          'You can mix Identification, Enumeration, and MCQ in the same exam',
        ],
      ),
      ManualTopic(
        id: 'review',
        title: 'Review & Score',
        subtitle: 'See your results after submitting',
        icon: Icons.assignment_turned_in_outlined,
        bulletPoints: [
          'After submission, your score is calculated automatically',
          'The review screen shows each question with your answer and the correct answer',
          'Explanations (if added) are shown for each question',
          'Identification answers are compared as text (case-insensitive)',
          'Enumeration answers are matched item by item',
          'MCQ answers are scored as correct/incorrect',
          'Cached explanations are available offline after the exam',
        ],
      ),
      ManualTopic(
        id: 'score-interpretation',
        title: 'Score Interpretation',
        subtitle: 'Understanding your results',
        icon: Icons.bar_chart_outlined,
        bulletPoints: [
          'Score is shown as a percentage (correct / total questions)',
          'Per-question results show pass/fail for each item',
          'Use low scores to identify topics that need more study',
          'Exam results feed into your analytics dashboard',
          'Retake exams to track improvement over time',
        ],
        tip:
            'Review the explanations for every question — even the ones you '
            'got right — to reinforce your understanding.',
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 6 — AI Generate
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _aiGenerate = ManualSection(
    id: 'ai-generate',
    title: 'AI Generate',
    subtitle: 'Create flashcards from documents using AI',
    icon: Icons.auto_awesome_outlined,
    iconColor: AppTheme.purple600,
    intro:
        'AI Generate uses the Groq API to automatically create flashcards '
        'from your source material. Upload PDFs, DOCX, TXT files, or images, '
        'select the content you want, and let AI generate questions. '
        'This feature requires internet and a Groq API key.',
    topics: [
      ManualTopic(
        id: 'api-key',
        title: 'Setting Up Your API Key',
        subtitle: 'Required before using AI features',
        icon: Icons.key_outlined,
        steps: [
          ManualStep(
            title: 'Get a Groq API key',
            description:
                'Visit console.groq.com, create a free account, and generate '
                'an API key.',
          ),
          ManualStep(
            title: 'Open API Configuration',
            description:
                'Go to Settings → AI Features → API Configuration, or tap '
                'the setup prompt on the AI Generate tab.',
          ),
          ManualStep(
            title: 'Enter your key',
            description:
                'Paste your API key into the field and save. The key is '
                'encrypted using Flutter Secure Storage.',
          ),
        ],
        note:
            'Your API key is stored locally and encrypted. It is never sent '
            'to any server except Groq\'s API directly.',
      ),
      ManualTopic(
        id: 'daily-quota',
        title: 'Daily Quota',
        subtitle: 'Limits on AI generation per day',
        icon: Icons.data_usage_outlined,
        bulletPoints: [
          'A daily quota limits how many questions you can generate',
          'View remaining quota in Settings → AI Usage',
          'Quota resets daily',
          'Authorized Quota Management allows password-protected quota changes',
          'When quota is low, a warning chip appears on the AI Usage tile',
        ],
      ),
      ManualTopic(
        id: 'uploading-files',
        title: 'Uploading Files',
        subtitle: 'PDF, DOCX, TXT, and images',
        icon: Icons.upload_file_outlined,
        bulletPoints: [
          'PDF files: Upload and preview pages before generating',
          'DOCX files: Text is extracted and previewed',
          'TXT files: Plain text is loaded directly',
          'Images: OCR extracts text from photos of notes or textbooks',
          'Camera OCR: Take a photo directly within the app',
        ],
      ),
      ManualTopic(
        id: 'selecting-content',
        title: 'Selecting Pages & Headings',
        subtitle: 'Choose what to generate from',
        icon: Icons.check_box_outlined,
        bulletPoints: [
          'PDF Preview: Select specific pages to include',
          'Heading/Chapter selection: Pick which sections to use',
          'Highlight extraction: Select specific text passages',
          'Text Preview: Edit the extracted text before generating',
        ],
      ),
      ManualTopic(
        id: 'generating',
        title: 'Generating & Regenerating Questions',
        subtitle: 'AI creates flashcards from your content',
        icon: Icons.auto_awesome,
        bulletPoints: [
          'Choose question type (Identification, Enumeration, or Multiple Choice)',
          'Choose difficulty level (Easy, Medium, Hard)',
          'AI generates questions and shows them in a review screen',
          'Regenerate: Tap regenerate to get a new set of questions',
          'Review and edit before saving to a deck',
        ],
        tip:
            'Always review AI-generated questions for accuracy before saving '
            'them to your deck. AI can sometimes misinterpret context.',
      ),
      ManualTopic(
        id: 'internet-required',
        title: 'Internet Required',
        subtitle: 'AI features need a connection',
        icon: Icons.wifi_outlined,
        bulletPoints: [
          'AI Generate sends your text to Groq\'s API servers',
          'A stable internet connection is required during generation',
          'If connection drops, the generation will fail — retry when online',
          'All other app features (study, exam, analytics) work offline',
          'Previously generated flashcards are available offline',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 7 — Backup & Restore
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _backupRestore = ManualSection(
    id: 'backup-restore',
    title: 'Backup & Restore',
    subtitle: 'Protect and recover your data',
    icon: Icons.backup_outlined,
    iconColor: AppTheme.blue600,
    intro:
        'QuizSnap stores all data in a local SQLite database. Backups create '
        'a copy of the entire .db file, which can be restored later or '
        'transferred to another device. Backups include all flashcards, decks, '
        'folders, study sessions, and settings.',
    topics: [
      ManualTopic(
        id: 'creating-backups',
        title: 'Creating Backups',
        subtitle: 'Save a .db copy of your data',
        icon: Icons.backup_outlined,
        steps: [
          ManualStep(
            title: 'Open Backup & Restore',
            description:
                'Go to Settings → Data Management → Backup & Restore.',
          ),
          ManualStep(
            title: 'Tap "Create Backup"',
            description:
                'A .db file is created in your backup folder.',
          ),
          ManualStep(
            title: 'Choose backup folder (optional)',
            description:
                'Use "Change Backup Folder" to store backups in a custom '
                'location (e.g. Downloads, Google Drive).',
          ),
        ],
      ),
      ManualTopic(
        id: 'backup-folder',
        title: 'Backup Folder',
        subtitle: 'Where your backups are stored',
        icon: Icons.folder_outlined,
        bulletPoints: [
          'Default backup folder is set automatically',
          'Change the folder via Settings → Change Backup Folder',
          'Open the backup folder directly from the app',
          'Share backups to cloud storage or other devices',
          'Backup folder location is remembered between sessions',
        ],
      ),
      ManualTopic(
        id: 'restoring',
        title: 'Restoring Backups',
        subtitle: 'Replace current data with a backup',
        icon: Icons.restore_outlined,
        steps: [
          ManualStep(
            title: 'Open Backup & Restore',
            description: 'Go to Settings → Backup & Restore.',
          ),
          ManualStep(
            title: 'Select a backup',
            description:
                'Choose from the recent backups list, or import a .db file.',
          ),
          ManualStep(
            title: 'Confirm restore',
            description:
                'Read the warning and confirm. The current database is '
                'replaced with the backup.',
          ),
        ],
        note:
            'Restore will replace ALL current local data. Create a backup '
            'of your current data first if you might need it.',
      ),
      ManualTopic(
        id: 'automatic-backups',
        title: 'Automatic Backups',
        subtitle: 'Schedule regular backups',
        icon: Icons.schedule_outlined,
        bulletPoints: [
          'Enable automatic backups in the Backup & Restore screen',
          'Choose frequency (daily, weekly, custom)',
          'Set retention policy (how many old backups to keep)',
          'Automatic backups run in the background',
          'View next backup time and last backup time on the schedule card',
        ],
      ),
      ManualTopic(
        id: 'backup-history',
        title: 'Backup History',
        subtitle: 'View and manage previous backups',
        icon: Icons.history_outlined,
        bulletPoints: [
          'Settings → Backup History shows all backups in the folder',
          'See file size, date, and time for each backup',
          'Restore or delete individual backups',
          'Import a backup from another location',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 8 — Security & PIN Lock
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _security = ManualSection(
    id: 'security',
    title: 'Security & PIN Lock',
    subtitle: 'Protect your app with PIN and inactivity lock',
    icon: Icons.security_outlined,
    iconColor: AppTheme.red600,
    intro:
        'QuizSnap offers multiple layers of security: a 4-digit PIN lock, '
        'app lock on open/resume, inactivity-based session lock, and a '
        'focus-mode exemption so study/exam sessions are never interrupted. '
        'All security data stays on your device.',
    topics: [
      ManualTopic(
        id: 'enable-pin',
        title: 'Enabling PIN Lock',
        subtitle: 'Set a 4-digit PIN to protect your app',
        icon: Icons.lock_outline,
        steps: [
          ManualStep(
            title: 'Open Security settings',
            description: 'Go to Settings → Security & Privacy → Security.',
          ),
          ManualStep(
            title: 'Toggle PIN Lock on',
            description:
                'Turn on the PIN Lock switch. You\'ll be prompted to set a '
                '4-digit PIN.',
          ),
          ManualStep(
            title: 'Set your PIN',
            description:
                'Enter a 4-digit numeric PIN. Confirm it when prompted.',
          ),
          ManualStep(
            title: 'PIN is now active',
            description:
                'The app will require your PIN on launch and on resume from '
                'background.',
          ),
        ],
        tip: 'Use a unique PIN that you can remember. Avoid 1234 or 0000.',
      ),
      ManualTopic(
        id: 'app-lock',
        title: 'App Lock on Open & Resume',
        subtitle: 'When the PIN is required',
        icon: Icons.phone_iphone_outlined,
        bulletPoints: [
          'PIN is required when the app launches',
          'PIN is required when the app returns from background',
          'The route you were on is saved and restored after unlock',
          'Lock screen cannot be bypassed by navigation',
        ],
      ),
      ManualTopic(
        id: 'inactivity-lock',
        title: 'Inactivity Lock',
        subtitle: 'Automatic lock after a period of no activity',
        icon: Icons.lock_clock_outlined,
        bulletPoints: [
          'Session locks automatically after a period of inactivity',
          'A warning countdown appears before the lock triggers',
          'Any tap or interaction resets the inactivity timer',
          'Inactivity lock is separate from manual "Lock Now"',
        ],
      ),
      ManualTopic(
        id: 'focus-mode',
        title: 'Focus-Mode Exemption',
        subtitle: 'Study and exam sessions are never interrupted',
        icon: Icons.center_focus_strong_outlined,
        bulletPoints: [
          'During an active study session, inactivity lock is suspended',
          'During an active exam, inactivity lock is suspended',
          'Focus mode activates automatically when you start studying or an exam',
          'When focus mode ends, the inactivity timer resets',
          'This ensures your study/exam is never interrupted by a lock screen',
        ],
        note:
            'The app lock on resume (from background) still applies during '
            'focus mode — only the inactivity timer is suspended.',
      ),
      ManualTopic(
        id: 'lock-now',
        title: 'Lock Now',
        subtitle: 'Manually lock the app immediately',
        icon: Icons.lock_outlined,
        bulletPoints: [
          'Settings → Security → Lock Now locks the app instantly',
          'A confirmation dialog appears before locking',
          'Your current route is saved and restored after unlock',
          'Useful when you need to step away from your device',
        ],
      ),
      ManualTopic(
        id: 'failed-attempts',
        title: 'Failed-Attempt Lockout',
        subtitle: 'Brute-force protection',
        icon: Icons.shield_outlined,
        bulletPoints: [
          'After 5 failed PIN attempts, a 30-second lockout is triggered',
          'During lockout, even the correct PIN is rejected',
          'A countdown shows remaining lockout time',
          'Failed attempts and lockout state persist across app restarts',
          'Successful unlock resets the failed attempt counter',
        ],
      ),
      ManualTopic(
        id: 'data-on-device',
        title: 'Your Data Stays on Your Device',
        subtitle: 'No servers, no accounts, no tracking',
        icon: Icons.privacy_tip_outlined,
        bulletPoints: [
          'All flashcard and study data is in a local SQLite database',
          'PINs are hashed with SHA-256 before storage',
          'API keys are encrypted with Flutter Secure Storage',
          'No account or login required',
          'No analytics or tracking data is sent to any server',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 9 — Dashboard & Analytics
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _analytics = ManualSection(
    id: 'analytics',
    title: 'Dashboard & Analytics',
    subtitle: 'Track your study progress',
    icon: Icons.dashboard_outlined,
    iconColor: AppTheme.indigo600,
    intro:
        'The Dashboard is the first tab in the app. It shows an overview of '
        'your study activity, including study time, cards studied, streaks, '
        'and accuracy. All analytics are calculated from your actual study '
        'and exam activity — there is no manual data entry.',
    topics: [
      ManualTopic(
        id: 'study-time',
        title: 'Study Time',
        subtitle: 'Total time spent studying',
        icon: Icons.timer_outlined,
        bulletPoints: [
          'Total study time is accumulated from study sessions',
          'View daily, weekly, and monthly breakdowns',
          'Study time screen shows trends over time',
          'Timer runs only during active study sessions',
        ],
      ),
      ManualTopic(
        id: 'cards-studied',
        title: 'Cards Studied',
        subtitle: 'How many flashcards you\'ve reviewed',
        icon: Icons.style_outlined,
        bulletPoints: [
          'Counts every card you flip through in Study Mode',
          'Includes cards from all decks',
          'Used to calculate daily activity and streaks',
        ],
      ),
      ManualTopic(
        id: 'streaks',
        title: 'Streaks',
        subtitle: 'Consecutive days of studying',
        icon: Icons.local_fire_department_outlined,
        bulletPoints: [
          'A streak counts consecutive days with at least one study session',
          'Missing a day breaks the streak',
          'Streaks motivate consistent study habits',
          'View your current and longest streak on the dashboard',
        ],
      ),
      ManualTopic(
        id: 'daily-activity',
        title: 'Daily Activity Graph',
        subtitle: 'Visualise your study consistency',
        icon: Icons.bar_chart_outlined,
        bulletPoints: [
          'Bar chart showing cards studied per day',
          'Weekly and monthly views available',
          'Tap a bar to see details for that day',
          'Helps identify patterns in your study habits',
        ],
      ),
      ManualTopic(
        id: 'accuracy',
        title: 'Accuracy Metrics',
        subtitle: 'Exam and quiz performance',
        icon: Icons.gps_fixed_outlined,
        bulletPoints: [
          'Average quiz score across all exams',
          'Per-deck accuracy breakdown',
          'Subject accuracy shows performance by subject/folder',
          'Quiz performance screen shows score trends',
        ],
      ),
      ManualTopic(
        id: 'deck-performance',
        title: 'Deck Performance',
        subtitle: 'Mastery and progress per deck',
        icon: Icons.trending_up_outlined,
        bulletPoints: [
          'Mastery breakdown shows progress for each deck',
          'Weak topics highlight areas that need more study',
          'Per-deck analytics help you focus your efforts',
          'Insights screen provides AI-style recommendations based on your data',
        ],
        note:
            'Analytics are calculated from actual study and exam activity. '
            'The more you use the app, the more accurate your analytics become.',
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Section 10 — Troubleshooting
  // ─────────────────────────────────────────────────────────────────────
  static const ManualSection _troubleshooting = ManualSection(
    id: 'troubleshooting',
    title: 'Troubleshooting',
    subtitle: 'Common issues and solutions',
    icon: Icons.build_outlined,
    iconColor: AppTheme.orange600,
    intro:
        'If you run into problems, check the FAQ items below. Each item '
        'includes the symptom, likely cause, and a step-by-step solution.',
    troubleshooting: [
      ManualTroubleshootingItem(
        question: 'AI is not generating questions',
        symptom:
            'Tapping "Generate" does nothing or shows an error message.',
        cause:
            'The most common causes are: no API key configured, no internet '
            'connection, daily quota exhausted, or an invalid/expired API key.',
        solution:
            '1. Go to Settings → API Configuration and verify your Groq API '
            'key is set.\n'
            '2. Check your internet connection.\n'
            '3. Go to Settings → AI Usage and check if your daily quota is '
            'exhausted (resets daily).\n'
            '4. If the key is invalid, generate a new one at console.groq.com '
            'and update it in API Configuration.',
      ),
      ManualTroubleshootingItem(
        question: 'No internet connection',
        symptom: 'AI generation fails with a network error.',
        cause:
            'AI features require internet to communicate with Groq\'s API. '
            'All other features work offline.',
        solution:
            'Connect to Wi-Fi or mobile data and retry. If the connection is '
            'unstable, try again in a moment. Study, exam, and analytics '
            'features continue to work without internet.',
      ),
      ManualTroubleshootingItem(
        question: 'Backup folder not opening',
        symptom:
            'Tapping "Open Backup Folder" does nothing or shows "No file '
            'manager found".',
        cause:
            'Your device may not have a file manager app that responds to '
            'the folder-open intent.',
        solution:
            'Use the "Share Backup" option instead to send the .db file to '
            'another app (e.g. Google Drive, email). Alternatively, install '
            'a file manager app from the Play Store and try again.',
      ),
      ManualTroubleshootingItem(
        question: 'Restore failed',
        symptom:
            'Restoring a backup shows an error or the app crashes.',
        cause:
            'The backup file may be corrupted, from an incompatible app '
            'version, or the file may not be a valid QuizSnap .db backup.',
        solution:
            '1. Ensure the .db file is a QuizSnap backup (not another app\'s '
            'database).\n'
            '2. Try a different, known-good backup from Backup History.\n'
            '3. If all backups fail, go to Settings → Database Maintenance → '
            'Repair Database.\n'
            '4. Restart the app and try restoring again.',
      ),
      ManualTroubleshootingItem(
        question: 'PIN lock not accepting correct PIN',
        symptom:
            'You enter your correct PIN but the app says it\'s wrong or '
            'shows a lockout countdown.',
        cause:
            'After 5 failed attempts, a 30-second lockout is enforced during '
            'which even the correct PIN is rejected. Alternatively, the PIN '
            'may have been changed.',
        solution:
            '1. If a lockout countdown is showing, wait for it to expire '
            '(30 seconds), then enter your PIN.\n'
            '2. If you forgot your PIN, you can clear all security data from '
            'Settings → Security → Danger Zone → Clear All Security Data '
            '(this also removes API keys).\n'
            '3. Re-set your PIN after clearing.',
      ),
      ManualTroubleshootingItem(
        question: 'Exam answers not saving',
        symptom:
            'You answer exam questions but when you submit, some answers '
            'are missing.',
        cause:
            'Answers are saved as you navigate between questions. If the app '
            'crashes or is killed mid-exam, unsaved answers may be lost.',
        solution:
            '1. Make sure to tap "Next" or navigate to the next question '
            'after answering — this triggers a save.\n'
            '2. Avoid force-closing the app during an exam.\n'
            '3. If the exam timer runs out, submitted answers up to that '
            'point are scored.\n'
            '4. Retake the exam if needed.',
      ),
      ManualTroubleshootingItem(
        question: 'Dark mode display issues',
        symptom:
            'Some elements are hard to read or colors look wrong in dark mode.',
        cause:
            'The app uses Material 3 with a full dark theme. If you see '
            'contrast issues, you may be on an older app version or your '
            'device has a custom display setting.',
        solution:
            '1. Go to Settings → Appearance and verify the theme is set '
            'correctly (Light, Dark, or System).\n'
            '2. If using "System" mode, check your device\'s dark mode '
            'setting.\n'
            '3. Try switching to explicit "Dark" mode to override system '
            'settings.\n'
            '4. Restart the app after changing themes.',
      ),
      ManualTroubleshootingItem(
        question: 'Missing backups',
        symptom:
            'Backups you created are not showing in Backup History.',
        cause:
            'The backup folder may have changed, files may have been moved '
            'or deleted externally, or the app is looking in the wrong folder.',
        solution:
            '1. Go to Settings → Change Backup Folder and verify the current '
            'folder path.\n'
            '2. Use a file manager to check if the .db files exist in the '
            'folder.\n'
            '3. If files were moved, navigate to the new location or use '
            '"Import Backup" to load a specific .db file.\n'
            '4. Create a new backup to verify the folder is writable.',
      ),
      ManualTroubleshootingItem(
        question: 'OCR text formatting problems',
        symptom:
            'Text extracted from images has weird characters, missing words, '
            'or poor formatting.',
        cause:
            'OCR quality depends on image clarity, lighting, and text size. '
            'Handwritten or low-contrast text is harder to extract accurately.',
        solution:
            '1. Use the Text Preview screen to edit the extracted text '
            'before generating questions.\n'
            '2. Retake the photo with better lighting and focus.\n'
            '3. Ensure the text is printed (not handwritten) for best results.\n'
            '4. Crop the image to include only the relevant text area.\n'
            '5. Manually fix any OCR errors in the text preview before '
            'generating.',
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────
  //  Search
  // ─────────────────────────────────────────────────────────────────────

  /// Searches all manual content and returns matching results.
  ///
  /// Search is case-insensitive and matches against section titles,
  /// topic titles, topic subtitles, bullet points, step descriptions,
  /// notes, tips, and troubleshooting questions.
  static List<ManualSearchResult> search(String query) {
    if (query.trim().isEmpty) return const [];
    final lowerQuery = query.toLowerCase();
    final results = <ManualSearchResult>[];

    for (final section in sections) {
      // Match section-level intro and quick start steps.
      if (section.intro != null &&
          section.intro!.toLowerCase().contains(lowerQuery)) {
        results.add(ManualSearchResult(
          sectionId: section.id,
          sectionTitle: section.title,
          topicId: '${section.id}-intro',
          topicTitle: section.title,
          topicSubtitle: section.subtitle,
          icon: section.icon,
          iconColor: section.iconColor,
          matchedSnippet: _extractSnippet(section.intro!, lowerQuery),
        ));
      }

      for (final topic in section.topics) {
        final searchableText = [
          topic.title,
          topic.subtitle,
          ...topic.bulletPoints,
          ...topic.steps.map((s) => '${s.title}: ${s.description}'),
          ...topic.infoTable.map((r) => '${r.label}: ${r.value}'),
          if (topic.note != null) topic.note!,
          if (topic.tip != null) topic.tip!,
        ];

        String? matchedSnippet;
        for (final text in searchableText) {
          if (text.toLowerCase().contains(lowerQuery)) {
            matchedSnippet = _extractSnippet(text, lowerQuery);
            break;
          }
        }

        if (matchedSnippet != null ||
            topic.title.toLowerCase().contains(lowerQuery) ||
            topic.subtitle.toLowerCase().contains(lowerQuery)) {
          results.add(ManualSearchResult(
            sectionId: section.id,
            sectionTitle: section.title,
            topicId: topic.id,
            topicTitle: topic.title,
            topicSubtitle: topic.subtitle,
            icon: topic.icon,
            iconColor: section.iconColor,
            matchedSnippet: matchedSnippet ?? topic.subtitle,
          ));
        }
      }

      // Search troubleshooting items.
      for (final item in section.troubleshooting) {
        final searchText = '${item.question} ${item.symptom} ${item.cause} '
            '${item.solution}';
        if (searchText.toLowerCase().contains(lowerQuery)) {
          results.add(ManualSearchResult(
            sectionId: section.id,
            sectionTitle: section.title,
            topicId: '${section.id}-troubleshooting',
            topicTitle: item.question,
            topicSubtitle: item.symptom,
            icon: Icons.build_outlined,
            iconColor: section.iconColor,
            matchedSnippet: _extractSnippet(searchText, lowerQuery),
          ));
        }
      }
    }

    return results;
  }

  /// Extracts a snippet of text around the first match of [query].
  static String _extractSnippet(String text, String query) {
    final lowerText = text.toLowerCase();
    final index = lowerText.indexOf(query);
    if (index == -1) return text;

    const snippetRadius = 40;
    final start = (index - snippetRadius).clamp(0, text.length);
    final end = (index + query.length + snippetRadius).clamp(0, text.length);

    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';

    return '$prefix${text.substring(start, end)}$suffix';
  }

  /// Returns a section by its ID, or null if not found.
  static ManualSection? getSectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }
}
