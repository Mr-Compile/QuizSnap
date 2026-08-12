# QuizSnap — Smart Document Analysis

This document describes the redesigned AI import, analysis scope, preview and cached-document workflow delivered for QuizSnap.

## 1. UX Flow

```text
Import (PDF/DOCX/TXT/OCR)
    ↓
Extraction + text cleaning pipeline
    ↓
Scope Selection
    ├── Entire Document
    ├── Specific Pages
    ├── By Chapter / Heading
    └── Highlighted Text
    ↓
Analysis Preview Screen
    (mandatory confirmation of source, scope, stats, tokens)
    ↓
AI Generation
    (AiGenerationConfigScreen)
    ↓
Question Review
```

## 2. Screen List

| Screen | File | Purpose |
|--------|------|---------|
| AI Home | `features/ai_generate/ai_generate_home_screen.dart` | Entry point, recent docs, recent generations |
| File Picker | `features/ai_generate/file_picker_bottom_sheet.dart` | Choose PDF/DOCX/TXT |
| Camera OCR | `features/ai_generate/camera_ocr_screen.dart` | Scan text |
| Scope Selection | `features/ai_generate/document_scope_selection_screen.dart` | Choose one of four analysis scopes |
| Page Range Selector | `features/ai_generate/page_range_selector_screen.dart` | Range input + page grid (PDF) |
| Heading Selection | `features/ai_generate/heading_selection_screen.dart` | Existing screen wired to preview |
| Text Highlight | `features/ai_generate/text_highlight_selection_screen.dart` | Selectable text viewer + summary |
| Analysis Preview | `features/ai_generate/analysis_preview_screen.dart` | Final confirmation before AI |
| Cached Documents | `features/ai_generate/cached_documents_screen.dart` | List cached imports |
| Cached Document Details | `features/ai_generate/cached_document_details_screen.dart` | Offline reopen / delete / analyze |

## 3. Heading Detection Algorithm

**File:** `lib/core/services/heading_detection_service.dart`

The engine is purely local and text-based. It does not require PDF metadata.

1. Split the cleaned document into lines.
2. For each non-empty line run `_headingLevel(line, previousLine)`.
   - **Numbered sections:** `1.`, `1.1`, `1.1.1` etc. → `level == dot-count`.
   - **Keyword headings:** `Chapter N`, `Section N`, `Module N`, `Unit N`, `Lesson N`, `Topic N` → `level 1`.
   - **All-caps short line** (≤80 chars, not ending a list) → `level 1`.
   - **Isolated short line after a blank line** (≤60 chars) → `level 2`.
3. Build a tree of `DocumentSection` nodes with `startLine` / `endLine`.
4. Sibling and parent relationships are resolved by closing open sections whose level is `>=` the new heading.

## 4. Highlight Selection Architecture

**Provider:** `lib/core/providers/highlighted_selection_provider.dart` (ChangeNotifier).

```
SelectableDocumentViewer (SelectableText)
    ↓
onSelectionChanged(TextSelection, _)
    ↓
HighlightedSelectionProvider.setSelection(text)
    ↓
SelectedTextSummarySheet displays stats + Analyze Selection
    ↓
AnalysisPreviewScreen
```

- `SelectableDocumentViewer` wraps `SelectableText` and returns the selected substring.
- `SelectedTextSummarySheet` is the floating bottom action card.
- `HighlightedSelectionProvider` lets the rest of the app read the active selection.

## 5. Cached Document Architecture

**Files:**
- `lib/core/services/cached_document_service.dart`
- `lib/core/repositories/cached_document_repository.dart`

Drift schema is **unchanged**. Extra metadata (raw text, cleaned text, detected sections, source, pages) is stored in the existing `scopeDetails` JSON column of `ExtractedDocuments`.

```
Import  →  CachedDocumentService.cacheDocument(rawText)
          →  TextNormalizationService.reconstruct(rawText)
          →  HeadingDetectionService.detectSections(cleaned)
          →  Persist to ExtractedDocuments

Reopen  →  CachedDocumentService.getCachedDocument(id)
          →  CachedDocumentDetailsScreen
          →  AnalysisPreviewScreen (offline, no file needed)
```

`CachedDocumentRepository` is a reactive `ChangeNotifier` for UI consumers.

## 6. Patched Flutter Widgets

- `CustomCard` — unchanged.
- `FormattedStudyText` — used by preview to render cleaned paragraphs/lists.
- `SelectableDocumentViewer` — new selectable text widget.
- `SelectedTextSummarySheet` — new selection action sheet.

## 7. Patched Services

- `HeadingDetectionService` (new)
- `PageRangeParser` (new)
- `CachedDocumentService` (new)
- `CachedDocumentRepository` (new)
- `DocumentExtractionService` (unchanged schema, existing normalization used)
- `TextNormalizationService` (reconstruct pipeline from previous session)
- `DocumentImportService` — `ImportResult` extended with `id` for navigation.

## 8. Provider Updates

`lib/main.dart` added:
- `CachedDocumentRepository` (ChangeNotifierProxyProvider over DatabaseProvider)
- `HighlightedSelectionProvider`

## 9. Final QA Results

```bash
flutter analyze lib --no-pub
```

Result: **No issues found.**

### Functional checks

- All four scope selection paths now route through `AnalysisPreviewScreen`.
- Entire document scope caches raw + cleaned text + detected sections.
- Specific pages selection uses `CachedDocumentService` and previews selected pages.
- Highlighted text uses `SelectableDocumentViewer` and `SelectedTextSummarySheet`.
- Cached document list navigates to `CachedDocumentDetailsScreen`.
- Existing Drift schemas, provider names, route names and folder structure preserved.

### Remaining recommended enhancements

- Page thumbnails in `PageRangeSelectorScreen` (currently shows a number grid).
- Hierarchical tree UI in `HeadingSelectionScreen` using `DocumentSectionModel` children.
- True PDF text-layer highlight with floating `ContextMenu` for `Highlight/Analyze`.
- PDF page count extraction in `DocumentScopeSelectionScreen` beyond the current heuristic.

## Deep implementation additions

### PDF page count extraction
- `DocumentExtractionService.getPageCount(File)` uses `syncfusion_flutter_pdf` to read `pages.count` without rendering.
- `DocumentScopeSelectionScreen` and `PageRangeSelectorScreen` now load the real page count.
- `RecentDocumentsSection` and `CachedDocumentsScreen` display `“name • X pages”`.

### Page selection provider
- `lib/core/providers/page_selection_provider.dart` tracks selected pages, ranges, Select All/Clear, and long-press range selection.
- Registered as a `ChangeNotifierProvider` in `main.dart`.

### Section/heading tree UI
- `lib/features/ai_generate/heading_tree_selection_screen.dart` uses `HeadingDetectionService` + `DocumentSectionModel`.
- Supports nested `ExpansionTile`, tri-state checkboxes, estimated question counts, and a bottom summary bar.
- `DocumentScopeSelectionScreen` now routes to this tree screen.

### Section preview
- `lib/features/ai_generate/section_preview_screen.dart` shows combined selected section text, stats, and a `Generate Questions` action.

### Cached document reopen
- `CachedDocumentDetailsScreen` now has `Analyze Entire Document` and `Choose Sections`.
- `Choose Sections` reopens `HeadingTreeSelectionScreen` from the cached file path without re-extraction.

### QA
- `flutter analyze lib --no-pub` → **No issues found.**

### Remaining enhancements
### UX stepper and haptics
- `lib/shared/widgets/stepper_header.dart` added.
- Stepper displayed on `DocumentScopeSelectionScreen`, `PageRangeSelectorScreen`, `HeadingTreeSelectionScreen`, and `SectionPreviewScreen`.
- `HapticFeedback.lightImpact()` on section selection in `HeadingTreeSelectionScreen`.

### Remaining enhancements
- Extraction percentage and cancel/retry UI in `HeadingTreeSelectionScreen` and `PageRangeSelectorScreen`.
- PDF thumbnail page grid with `pdfx` page rendering.
