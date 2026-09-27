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
  static const String _model = 'gemini-2.0-flash';

  static const String _prompt = '''
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

Rules:
- If a shift spans midnight (e.g. 22:00 to 06:00), keep both times as-is.
- If the year is not shown, assume the current year.
- If you cannot read a value, omit the shift rather than guessing.
- Do not invent shifts.
''';

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
      // Strip any accidental markdown fences.
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
          date: date,
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

  /// Normalise "7:00" → "07:00", "9:5" → "09:05", etc.
  String _normaliseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}