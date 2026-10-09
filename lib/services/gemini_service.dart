import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/shift.dart';

/// Result wrapper so callers can distinguish success from failure.
class RosterExtractionResult {
  final List<Shift> shifts;
  final String? error;

  RosterExtractionResult({required this.shifts, this.error});

  bool get success => error == null;
}

/// Sends a roster photo to Gemini and parses out shifts.
class GeminiService {
  static const String _model = 'gemini-3.1-flash-lite';

  /// Prompt is a getter because it needs today's date at runtime.
  static String get _prompt {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return '''
You are extracting shift data from a photo of a printed duty roster.

Return ONLY valid JSON. No prose, no markdown fences, no explanation.

The JSON schema must be exactly:
{
  "shifts": [
    {
      "title": "string (e.g. Morning Shift, Night Shift)",
      "date": "YYYY-MM-DD",
      "startTime": "HH:mm (24-hour)",
      "endTime": "HH:mm (24-hour)",
      "description": "string or null"
    }
  ]
}

CRITICAL DATE RULES:
- Today's date is $today.
- If a roster shows only month and day (e.g. "Oct 9"), you MUST use the year that makes the date fall on or after today.
- Prefer the current year unless that would put the shift in the past. If the current year would make it past, use next year.
- NEVER output a year earlier than ${now.year}.

Other rules:
- If a shift spans midnight (e.g. 22:00 to 06:00), keep both times as-is.
- If you cannot read a value, omit the shift rather than guessing.
- Do not invent shifts.
''';
  }

  /// Extract shifts from a JPEG/PNG byte array.
  Future<RosterExtractionResult> extractShifts(Uint8List imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return RosterExtractionResult(
          shifts: const [],
          error: 'Missing GEMINI_API_KEY in .env',
        );
      }

      final model = GenerativeModel(
        model: _model,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
      );

      final content = [
        Content.multi([
          TextPart(_prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return RosterExtractionResult(
          shifts: const [],
          error: 'Gemini returned an empty response.',
        );
      }

      return _parseResponse(text);
    } on SocketException {
      return RosterExtractionResult(
        shifts: const [],
        error: 'No internet connection.',
      );
    } catch (e) {
      return RosterExtractionResult(
        shifts: const [],
        error: 'Extraction failed: $e',
      );
    }
  }

  RosterExtractionResult _parseResponse(String raw) {
    try {
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final list = decoded['shifts'] as List<dynamic>? ?? [];

      final shifts = <Shift>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final title = (map['title'] as String?)?.trim() ?? '';
        final dateStr = (map['date'] as String?)?.trim() ?? '';
        final startStr = (map['startTime'] as String?)?.trim() ?? '';
        final endStr = (map['endTime'] as String?)?.trim() ?? '';
        final description = map['description'] as String?;

        if (title.isEmpty ||
            dateStr.isEmpty ||
            startStr.isEmpty ||
            endStr.isEmpty) {
          continue;
        }

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        shifts.add(Shift(
          title: title,
          date: _forceFutureYear(date),
          startTime: _normaliseTime(startStr),
          endTime: _normaliseTime(endStr),
          description: description,
          confirmed: false,
        ));
      }

      if (shifts.isEmpty) {
        return RosterExtractionResult(
          shifts: const [],
          error: 'No shifts found in the photo.',
        );
      }

      return RosterExtractionResult(shifts: shifts);
    } catch (e) {
      return RosterExtractionResult(
        shifts: const [],
        error: 'Could not parse Gemini response: $e',
      );
    }
  }

  /// If a parsed date is before today, assume Gemini mis-guessed the year
  /// and bump it forward until it's in the future.
  DateTime _forceFutureYear(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var candidate = date;
    // Same month/day but ensure the year is >= current year.
    // If the year is behind, advance one year at a time until future.
    while (candidate.isBefore(today)) {
      candidate = DateTime(
        candidate.year + 1,
        candidate.month,
        candidate.day,
        candidate.hour,
        candidate.minute,
      );
    }
    return candidate;
  }

  String _normaliseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}