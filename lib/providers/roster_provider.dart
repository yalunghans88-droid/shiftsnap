import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shift.dart';
import '../services/gemini_service.dart';

/// State for the currently-in-progress roster extraction.
class RosterState {
  final bool isLoading;
  final List<Shift> extractedShifts;
  final Uint8List? imageBytes;
  final String? error;

  const RosterState({
    this.isLoading = false,
    this.extractedShifts = const [],
    this.imageBytes,
    this.error,
  });

  RosterState copyWith({
    bool? isLoading,
    List<Shift>? extractedShifts,
    Uint8List? imageBytes,
    String? error,
    bool clearError = false,
  }) {
    return RosterState(
      isLoading: isLoading ?? this.isLoading,
      extractedShifts: extractedShifts ?? this.extractedShifts,
      imageBytes: imageBytes ?? this.imageBytes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RosterNotifier extends Notifier<RosterState> {
  final _gemini = GeminiService();

  @override
  RosterState build() => const RosterState();

  Future<void> extractFromImage(Uint8List imageBytes) async {
    state = state.copyWith(
      isLoading: true,
      imageBytes: imageBytes,
      clearError: true,
      extractedShifts: const [],
    );

    final result = await _gemini.extractShifts(imageBytes);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        extractedShifts: result.shifts,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  void updateShift(int index, Shift updated) {
    final list = [...state.extractedShifts];
    list[index] = updated;
    state = state.copyWith(extractedShifts: list);
  }

  void removeShift(int index) {
    final list = [...state.extractedShifts]..removeAt(index);
    state = state.copyWith(extractedShifts: list);
  }

  void addShift(Shift shift) {
    state = state.copyWith(extractedShifts: [...state.extractedShifts, shift]);
  }

  void reset() {
    state = const RosterState();
  }
}

final rosterProvider =
    NotifierProvider<RosterNotifier, RosterState>(RosterNotifier.new);