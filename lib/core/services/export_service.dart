import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../models/export.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/folder_repository.dart';
import '../repositories/tag_repository.dart';

class ExportService {
  final AppDatabase _database;
  final DeckRepository _deckRepository;
  final FlashcardRepository _flashcardRepository;
  final FolderRepository _folderRepository;
  final TagRepository _tagRepository;

  ExportService(
    this._database,
    this._deckRepository,
    this._flashcardRepository,
    this._folderRepository,
    this._tagRepository,
  );

  Future<ExportResult> exportData(ExportOptions options, {int? deckId}) async {
    final exportId = DateTime.now().millisecondsSinceEpoch.toString();
    final result = ExportResult(
      id: exportId,
      options: options,
      status: ExportStatus.generating,
      createdAt: DateTime.now(),
    );

    try {
      String? filePath;
      int? fileSizeBytes;

      switch (options.format) {
        case ExportFormat.pdf:
          filePath = await _exportToPdf(options, deckId);
          break;
        case ExportFormat.csv:
          filePath = await _exportToCsv(options, deckId);
          break;
        case ExportFormat.json:
          filePath = await _exportToJson(options, deckId);
          break;
      }

      if (filePath != null) {
        final file = File(filePath);
        fileSizeBytes = await file.length();
      }

      return result.copyWith(
        status: ExportStatus.completed,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      return result.copyWith(
        status: ExportStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  Future<String?> _exportToPdf(ExportOptions options, int? deckId) async {
    final pdf = pw.Document();
    final deck = deckId != null ? await _deckRepository.getDeckById(deckId) : null;
    final flashcards = deckId != null
        ? await _flashcardRepository.getFlashcardsByDeck(deckId)
        : await _flashcardRepository.getAllFlashcards();

    // Apply filters
    var filteredCards = flashcards;
    if (options.shuffleQuestions) {
      filteredCards = List.from(filteredCards)..shuffle();
    }
    if (options.questionLimit != null && options.questionLimit! > 0) {
      filteredCards = filteredCards.take(options.questionLimit!).toList();
    }

    // Get tags if needed
    Map<int, List<String>> cardTags = {};
    if (options.includeTags) {
      for (final card in filteredCards) {
        final tags = await _database.getTagsForFlashcard(card.id);
        cardTags[card.id] = tags.map((t) => t.name).toList();
      }
    }

    // Build PDF content
    final title = options.customTitle ?? (deck?.name ?? 'Flashcards Export');
    final description = options.customDescription ?? deck?.description;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            if (description != null)
              pw.Paragraph(text: description, style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              text: 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            ...filteredCards.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final card = entry.value;
              final tags = cardTags[card.id] ?? [];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Q$index: ${card.question}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (options.includeTags && tags.isNotEmpty)
                          pw.SizedBox(height: 4),
                        if (options.includeTags && tags.isNotEmpty)
                          pw.Text('Tags: ${tags.join(', ')}',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('A$index: ${card.answer}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Reviewed: ${card.reviewCount} times | Correct: ${card.correctCount} times',
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  Future<String?> _exportToCsv(ExportOptions options, int? deckId) async {
    final deck = deckId != null ? await _deckRepository.getDeckById(deckId) : null;
    final flashcards = deckId != null
        ? await _flashcardRepository.getFlashcardsByDeck(deckId)
        : await _flashcardRepository.getAllFlashcards();

    // Apply filters
    var filteredCards = flashcards;
    if (options.shuffleQuestions) {
      filteredCards = List.from(filteredCards)..shuffle();
    }
    if (options.questionLimit != null && options.questionLimit! > 0) {
      filteredCards = filteredCards.take(options.questionLimit!).toList();
    }

    // Get tags if needed
    Map<int, List<String>> cardTags = {};
    if (options.includeTags) {
      for (final card in filteredCards) {
        final tags = await _database.getTagsForFlashcard(card.id);
        cardTags[card.id] = tags.map((t) => t.name).toList();
      }
    }

    // Build CSV rows
    final rows = <List<String>>[];
    
    // Header
    final header = ['Question', 'Answer'];
    if (options.includeTags) header.add('Tags');
    if (options.includeAnswers) header.add('Include Answer');
    rows.add(header);

    // Data rows
    for (final card in filteredCards) {
      final row = [
        card.question,
        options.includeAnswers ? card.answer : '[Hidden]',
      ];
      if (options.includeTags) {
        row.add((cardTags[card.id] ?? []).join(', '));
      }
      rows.add(row);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Save CSV
    final directory = await getApplicationDocumentsDirectory();
    final title = options.customTitle ?? (deck?.name ?? 'Flashcards Export');
    final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvString);

    return filePath;
  }

  Future<String?> _exportToJson(ExportOptions options, int? deckId) async {
    final deck = deckId != null ? await _deckRepository.getDeckById(deckId) : null;
    final flashcards = deckId != null
        ? await _flashcardRepository.getFlashcardsByDeck(deckId)
        : await _flashcardRepository.getAllFlashcards();

    // Apply filters
    var filteredCards = flashcards;
    if (options.shuffleQuestions) {
      filteredCards = List.from(filteredCards)..shuffle();
    }
    if (options.questionLimit != null && options.questionLimit! > 0) {
      filteredCards = filteredCards.take(options.questionLimit!).toList();
    }

    // Get tags if needed
    Map<int, List<Map<String, dynamic>>> cardTags = {};
    if (options.includeTags) {
      for (final card in filteredCards) {
        final tags = await _database.getTagsForFlashcard(card.id);
        cardTags[card.id] = tags.map((t) => {
          'id': t.id,
          'name': t.name,
          'color': t.color,
        }).toList();
      }
    }

    // Build JSON structure
    final exportData = {
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'format': options.format.toString(),
        'type': options.type.toString(),
        'deck': deck != null ? {
          'id': deck.id,
          'name': deck.name,
          'description': deck.description,
          'color': deck.color,
        } : null,
        'options': options.toJson(),
      },
      'flashcards': filteredCards.map((card) {
        final cardData = {
          'id': card.id,
          'question': card.question,
          'answer': options.includeAnswers ? card.answer : null,
          'deckId': card.deckId,
          'order': card.order,
          'isFavorite': card.isFavorite,
          'reviewCount': card.reviewCount,
          'correctCount': card.correctCount,
          'lastReviewedAt': card.lastReviewedAt?.toIso8601String(),
          'nextReviewAt': card.nextReviewAt?.toIso8601String(),
          'easeFactor': card.easeFactor,
          'interval': card.interval,
          'repetitions': card.repetitions,
          'createdAt': card.createdAt.toIso8601String(),
          'updatedAt': card.updatedAt.toIso8601String(),
        };
        
        if (options.includeTags) {
          cardData['tags'] = cardTags[card.id] ?? [];
        }
        
        return cardData;
      }).toList(),
    };

    // Convert to JSON string
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // Save JSON
    final directory = await getApplicationDocumentsDirectory();
    final title = options.customTitle ?? (deck?.name ?? 'Flashcards Export');
    final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  Future<void> shareExport(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  Future<void> printPdf(String filePath) async {
    await Printing.sharePdf(bytes: await File(filePath).readAsBytes(), filename: filePath.split('/').last);
  }

  Future<String> exportQuizToPdf(List<ExamQuestion> questions, String quizTitle) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(quizTitle, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              text: 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final question = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$index. ${question.question}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  ...question.options.asMap().entries.map((optEntry) {
                    final optIndex = optEntry.key;
                    final option = optEntry.value;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 16),
                      child: pw.Text('${String.fromCharCode(65 + optIndex)}. $option'),
                    );
                  }).toList(),
                  pw.SizedBox(height: 16),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${quizTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  Future<String> exportAnswerKeyToPdf(List<ExamQuestion> questions, String quizTitle) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('$quizTitle - Answer Key', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              text: 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final question = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$index. ${question.correctAnswer}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  if (question.explanation != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Paragraph(text: question.explanation!, style: pw.TextStyle(fontSize: 10)),
                  ],
                  pw.SizedBox(height: 12),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${quizTitle.replaceAll(' ', '_')}_answer_key_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
}