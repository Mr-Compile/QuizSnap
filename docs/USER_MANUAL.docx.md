# QuizSnap User Manual

**Version:** 1.0.0
**Platform:** Flutter (Android, iOS, Windows, macOS, Linux, Web)
**Generated from:** QuizSnap source code (`lib/`)

This manual describes only features that actually exist in the QuizSnap
codebase. Every screen, route, and behavior referenced here is backed by a real
implementation file.

---

## 1. Introduction

QuizSnap is an offline-first flashcard and study application that helps you
learn effectively using spaced repetition, AI-powered question generation, and
detailed analytics.

**Core capabilities:**

- Create decks and flashcards manually or via AI generation.
- Study using List Mode, Quiz Mode, or Today's Review with spaced repetition
  (SM-2 algorithm).
- Take timed exams generated from your deck content.
- Generate quiz questions, identification, enumeration, and mixed-format items
  from PDF, TXT, DOCX, or camera OCR text using the Groq AI service.
- Track study time, accuracy, streaks, and mastery in the Analytics dashboard.
- Back up and restore your database, export decks to PDF, and manage deleted
  items in Trash.
- Optional PIN lock and study reminders.

**Offline behavior:** Study, exam, analytics, library, backup, and trash
features work fully offline. AI features (Generate, Regenerate, View
Explanation) require an active internet connection.

---

## 2. Installation

1. Ensure Flutter SDK is installed (`flutter --version`).
2. Clone the QuizSnap repository.
3. Run `flutter pub get` to install dependencies.
4. Run `flutter run` to launch on a connected device or emulator.
5. For release builds: `flutter build apk` (Android) or
   `flutter build ios` (iOS).

**Required permissions (mobile):** camera (for OCR), notifications
(for study reminders), storage (for backup/export).

---

## 3. Home Screen

**Navigation path:** App launch → MainScreen (`/`)
**Bottom navigation tabs (left to right):**

1. **Library** (`LibraryScreen`) — manage decks and folders
2. **AI Generate** (`AiGenerateHomeScreen`) — AI question generation
3. **Study** (`StudyHomeScreen`) — study sessions and review
4. **Progress** (`AnalyticsDashboardScreen`) — analytics dashboard
5. **Settings** (`SettingsScreen`) — app configuration

**AppBar action:** Settings icon (top right) opens Settings.

**Security:** If a PIN lock is enabled in Settings, the app shows the
`PinLockScreen` on launch and requires authentication before continuing.

**Online requirement:** None. The home screen and tab navigation work offline.

---

## 4. Library & Folders

**Navigation path:** Bottom nav → Library tab

**Library screen actions:**

- **Folders icon (AppBar):** Opens Folder management (`/folders`) to create,
  rename, and delete folders.
- **Trash icon (AppBar):** Opens Trash (`/trash`) to restore or permanently
  delete items.
- **Deck cards:** Tap a deck to open Deck Details.
- **Create deck:** FAB or empty-state button opens Create Deck screen
  (`/decks/create`).

**Folders:** Group decks into folders for organization. A folder can be opened
to view its decks. Decks can be moved between folders via the move-deck dialog.

**Online requirement:** None.

---

## 5. Deck Management

**Navigation path:** Library → Tap a deck → Deck Details (`/decks/:deckId`)

**Deck Details screen:**

- View deck name, color, card count, and tags.
- **Edit Deck** (`/decks/:deckId/edit`) — rename, change color, assign folder/tags.
- **Delete Deck** — moves the deck to Trash (restorable for 30 days by default).
- **Add Flashcard** (`/decks/:deckId/flashcards/add`) — manual card creation.
- **Flashcard List** (`/decks/:deckId/flashcards`) — view, edit, delete cards.
- **Start Study** — quick link to study modes.
- **Start Exam** — opens Exam Setup (`/exam/:deckId/setup`).

**Online requirement:** None.

---

## 6. Flashcard Management

**Navigation path:** Deck Details → Flashcards

**Flashcard fields:**

- Question (front)
- Answer (back)
- Optional tags
- Bookmark/favorite flag
- SM-2 spaced repetition metadata (next review date, interval, ease factor)

**Actions:**

- **Create** (`/decks/:deckId/flashcards/add`) — add a new card.
- **Edit** (`/decks/:deckId/flashcards/:flashcardId/edit`) — modify an existing card.
- **Delete** — moves the card to Trash.
- **Move** (`/move-flashcards`) — move selected cards to another deck.
- **Bookmark** — toggle favorite flag for quick access in Bookmarks.

**Online requirement:** None.

---

## 7. Study Mode

**Navigation path:** Bottom nav → Study tab

**Study Home screen:**

- **Today's Progress card:** shows Due Today, Bookmarked, and Accuracy stats.
- **Continue Last Session:** resumes an interrupted study session from the last
  viewed card.
- **Today's Review:** opens `TodayReviewScreen` listing cards due for review.
  Includes a **Shuffle** toggle to randomize card order for the session.
- **Bookmarks:** opens `BookmarkListScreen` to study favorited cards.
- **Study by Deck:** opens `DeckStudyScreen` to pick a deck, then choose:
  - **List Mode** (`FlashcardListScreen`) — browse cards with a Study All button.
  - **Quiz Mode** (`QuizPracticeScreen`) — self-graded quiz with I know / I
    don't know buttons and a summary screen.
  - Both modes include a **Shuffle** toggle in the deck options sheet.

**Flashcard Study Session (`FlashcardStudySessionScreen`):**

- 3D flip card with question/answer.
- Tap to reveal answer.
- Confidence buttons (Sure / Maybe / No) before reveal.
- Rating buttons (Again / Hard / Good / Easy) after reveal, which drive the
  SM-2 algorithm via `studyRepository.updateCardReview`.
- Previous / Next navigation follows the (optionally shuffled) session order.
- Bookmark toggle in the AppBar.
- End Session button confirms via a centered dialog.
- Session summary shows cards studied, average confidence, time spent, and due
  tomorrow count.
- "Continue Studying" restarts the session (re-shuffles if shuffle was on).

**Shuffle behavior:**

- Default OFF.
- When ON, cards are shuffled once at session start and the order is preserved
  for the entire session (next/previous/review all use the same order).
- Restarting a session creates a new shuffle.
- Bookmarks, ratings, and analytics are preserved regardless of shuffle state.

**Online requirement:** None. Study sessions are fully offline.

---

## 8. Exam Mode

**Navigation path:** Deck Details → Start Exam → Exam Setup
(`/exam/:deckId/setup`)

**Exam Setup screen:**

- **Number of Questions:** chips for 5, 10, 15, 20, 25, 30, 50, 100 (clamped
  to deck card count).
- **Time Limit:** preset chips (1, 5, 10, 15, 20, 25, 30 minutes) plus a
  custom minutes field (valid range 1–120).
- **Shuffle questions** toggle (default OFF). When ON, questions are randomized
  once at generation and the order is preserved for the entire exam, review,
  and result screens.
- **Exam Summary** card lists deck, question count, time limit, and shuffle
  state.
- **Start Exam** validates inputs and navigates to the Countdown screen.

**Countdown screen:** 3-2-1 countdown before the exam begins.

**Exam Question screen (`/exam/:examId/question`):**

- Countdown timer in the AppBar (turns red under 5 minutes).
- Pause button opens a pause dialog (resume or exit).
- Progress bar shows answered/total.
- Question rendering is type-aware:
  - **Multiple Choice:** A–D option tiles, single selection.
  - **Identification:** text field with done action.
  - **Enumeration:** add/remove list items one at a time.
  - **Mixed Format:** resolved per question data (enumeration if multiple
    correct answers, MCQ if ≥4 options, otherwise identification).
- Previous / Next navigation persists the current input before moving.
- Finish Exam opens a submit confirmation dialog.
- Time expiry auto-submits via a friendly dialog.

**Exam Result screen (`/exam/:examId/result`):**

- Score percentage, grade icon, and grade label.
- Statistics card: correct, incorrect, unanswered counts with a progress bar.
- Time taken card (formatted as h/m/s).
- **Review Answers** button opens the Exam Review screen.
- **Back to Deck** button clears the exam and returns to Deck Details.
- Exam results are persisted to analytics via
  `analyticsRepository.createQuizResult` and `db.refreshAnalytics()`.

**Exam Review screen (`/exam/:examId/review`):**

- Tabs: All / Correct / Incorrect.
- Each question card shows the question, your answer, the correct answer, and
  (for enumeration) any missing items.
- **View Explanation** button opens the Answer Explanation bottom sheet (see
  section 9).

**Shuffle behavior:** Same as Study Mode — order is set once at generation and
preserved through questions, results, and review.

**Online requirement:** None. Exams are generated from local deck content and
run entirely offline. Only the optional View Explanation feature requires
internet.

---

## 9. AI Features

**Navigation path:** Bottom nav → AI Generate tab

**AI Generate Home (`/ai-generate`):**

- First-time setup: enter a Groq API key (stored securely on-device via
  `flutter_secure_storage`). A help dialog explains how to obtain a key from
  `console.groq.com`.
- Quota display shows remaining AI requests for the day.
- **Import options:** PDF, TXT, DOCX, Cached Documents, Camera OCR.
- **Recent Generations** list reopens previous generation sessions.

**AI Generation Config (`/ai-generate/config`):**

- Question type: Multiple Choice, Identification, Enumeration, Mixed Format.
- Difficulty: Easy, Medium, Hard.
- Number of questions: 5–50 slider.
- **Generate Questions** triggers the AI request.
- **Connectivity guard:** Before generation, the app checks connectivity. If
  offline, a centered **No Internet Connection** dialog appears with Retry
  and Close buttons. No raw socket/HTTP/token errors are shown.
- On success, navigates to the Question Review screen.

**Question Review (`/ai-generate/review`):**

- Review, approve, reject, and edit generated questions.
- **Regenerate** options: All, Selected, or Keep Approved & Replace Rejected.
  Regeneration is also guarded by the connectivity check.
- Save approved questions to a new or existing deck.

**Camera OCR (`/ai-generate/camera-ocr`):** Capture a photo and run on-device
text recognition (ML Kit). No internet required for OCR itself; the subsequent
AI generation step is guarded.

**PDF / TXT / DOCX:** Local text extraction (no internet). The extracted text
is sent to the AI generation flow, which is connectivity-guarded.

**View Explanation (Exam Review):**

- Opens the Answer Explanation bottom sheet.
- Checks the local explanation cache first.
- If not cached and the device is offline, a **No Internet Connection** dialog
  is shown (closes the sheet, offers Retry).
- If the AI service is unavailable or returns no explanation, an
  **Explanation Unavailable** state is shown: "No explanation is available for
  this question yet."
- No stack traces, API tokens, or raw error messages are ever displayed.

**Online requirement:** All AI generation, regeneration, and explanation
features require internet. OCR and document text extraction work offline.

---

## 10. Analytics

**Navigation path:** Bottom nav → Progress tab (`/analytics`)

**Analytics Dashboard:**

- Quick stats: total decks, total flashcards, cards studied today, due today,
  current streak, average quiz score, total study time (formatted dynamically
  as sec / min sec / hr min), total flashcards reviewed, quiz attempts.
- Navigation cards to detailed analytics screens.

**Detailed analytics screens:**

- **Daily Activity** (`/analytics/daily-activity`) — bar chart of cards studied
  and study time per day.
- **Insights** (`/analytics/insights`) — AI-style study insights and
  suggestions based on recent activity.
- **Mastery Breakdown** (`/analytics/mastery`) — mastery level per deck.
- **Quiz Performance** (`/analytics/quiz-performance`) — quiz score history.
- **Study Time** (`/analytics/study-time`) — today / week / month study time
  with a comparison chart and daily goal progress.
- **Subject Accuracy** (`/analytics/subject-accuracy`) — accuracy per subject.
- **Weak Topics** (`/analytics/weak-topics`) — topics with low accuracy.

**Time format:** Study duration is stored and aggregated in seconds and
displayed dynamically:

- `< 60s` → `45 sec`
- `< 60m` → `12 min 30 sec`
- `≥ 1h` → `1 hr 12 min`

**Online requirement:** None. Analytics are computed from the local SQLite
database.

---

## 11. Bookmarks

**Navigation path:** Study tab → Bookmarks

- Lists all flashcards flagged as favorites across all decks.
- Tap a card to open the Flashcard Detail screen.
- Bookmarks are preserved during shuffle and across study sessions.

**Online requirement:** None.

---

## 12. Backup & Restore

**Navigation path:** Settings → Backup & Restore
(`/export/backups/restore-enhanced`)

**Features:**

- **Create Backup:** writes the SQLite database to a chosen folder.
- **Restore Backup:** imports a previously created backup file.
- **Backup History** (`/export/backups`) — list of past backups.
- **Change Backup Folder** (`/export/backups/change-folder`) — set the default
  backup location.
- **Import Preview** (`/export/backups/import-preview`) — preview contents
  before restoring.
- **Export Center** (`/export`) and **Export Options** (`/export/options`) —
  export decks to PDF or other formats.
- **Export Success** (`/export/success`) — confirmation screen after export.

**Online requirement:** None. Backup and restore are local file operations.

---

## 13. Trash & Restore

**Navigation path:** Library AppBar → Trash (`/trash`) or Settings → Trash

- Deleted decks and flashcards are moved to Trash (soft delete).
- Items can be restored within the retention period (default 30 days,
  configurable in Trash Settings).
- **Trash Settings** (`/settings/trash`) — configure auto-cleanup schedule and
  retention.
- A background cleanup scheduler runs on app start to purge expired items.

**Online requirement:** None.

---

## 14. Settings

**Navigation path:** Bottom nav → Settings tab (`/settings`)

**Sections:**

- **General**
  - **Appearance** (`/settings/appearance`) — light/dark theme, display options.
- **Security & Privacy**
  - **Security** (`/settings/security`) — PIN lock and API key management.
  - **Study Reminders** (`/settings/reminders`) — configure notification schedule.
- **AI Features**
  - **AI Usage** (`/settings/ai-usage`) — view remaining daily AI quota.
- **Data Management**
  - **Backup & Restore** (`/export/backups/restore-enhanced`).
  - **Database Maintenance** (`/settings/database`) — check integrity and repair.
  - **Trash** (`/trash`) — restore or permanently delete items.
  - **Trash Settings** (`/settings/trash`) — auto-cleanup configuration.
- **About**
  - App version and feature list.

**Related screens:**

- **API Configuration** (`/settings/api-config`) — manage Groq API key and model.
- **Authorized Quota** (`/settings/authorized-quota`) — admin-configured quota.
- **Set PIN** (`/settings/pin-set`) and **PIN Lock** (`/settings/pin-lock`).

**Online requirement:** None, except for API key validation which contacts
Groq.

---

## 15. Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| AI Generate shows "No Internet Connection" | Device offline | Connect to Wi-Fi or mobile data and tap Retry. |
| AI Generate shows "AI Limit Reached" | Daily quota exhausted | Wait until tomorrow or request additional quota. |
| View Explanation shows "Explanation Unavailable" | No cached explanation and AI unavailable | Try again later when online. |
| Exam won't start | Deck has fewer cards than requested | Lower the question count or add more cards. |
| Study session progress lost | Session was ended or app was killed | Use Continue Last Session on the Study home screen. |
| PIN lock blocks access | PIN enabled in Security settings | Enter the correct PIN, or disable PIN in Settings. |
| Backup restore fails | Incompatible or corrupted backup file | Use a valid backup from the same app version. |
| Trash item missing | Retention period expired | Items are auto-purged after the configured retention window. |

---

## 16. FAQ

**Q: Does QuizSnap work without internet?**
A: Yes. Study, exam, analytics, library, backup, and trash features work fully
offline. Only AI generation, regeneration, and AI explanation features require
internet.

**Q: Where is my API key stored?**
A: The Groq API key is stored securely on-device using `flutter_secure_storage`.
It is never sent to any server other than Groq's official API.

**Q: Can I shuffle cards in a study session?**
A: Yes. Enable the Shuffle toggle on the Today's Review, Quiz, or Study by Deck
screens. The order is set once at session start and preserved for the entire
session.

**Q: Can I shuffle exam questions?**
A: Yes. Enable the Shuffle questions toggle on the Exam Setup screen. The
order is preserved through the exam, results, and review screens.

**Q: How is study time calculated?**
A: Study duration is tracked in seconds and aggregated from each study
session's start and end time. It is displayed in a dynamic format (sec / min
sec / hr min).

**Q: What happens to deleted decks and cards?**
A: They are moved to Trash and can be restored within the retention period
(default 30 days). After that they are permanently deleted by the cleanup
scheduler.

**Q: Can I export my decks?**
A: Yes. Use Export Center in the Backup & Restore flow to export decks to PDF.

**Q: How do I reset my PIN?**
A: Open Settings → Security → disable PIN lock (requires the current PIN).

**Q: Why does the AI explanation sometimes show "Explanation Unavailable"?**
A: This appears when no explanation is cached and the AI service cannot
generate one (for example, the AI service is not initialized or returned no
content). No technical error details are shown.

**Q: Are my bookmarks and ratings preserved when I shuffle?**
A: Yes. Shuffle only changes the order of cards/questions, not their data.
Bookmarks, ratings, and analytics are always preserved.
