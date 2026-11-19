import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tour_steps.dart';

/// Estado del recorrido: cerrado, o abierto en el paso [step].
class TourState {
  const TourState({this.open = false, this.step = 0});

  final bool open;
  final int step;
}

class TourController extends Notifier<TourState> {
  @override
  TourState build() => const TourState();

  List<TourStep> get steps => ref.read(tourStepsProvider);

  void start() => state = const TourState(open: true);

  void next() {
    if (!state.open) return;
    if (state.step < steps.length - 1) {
      state = TourState(open: true, step: state.step + 1);
    }
  }

  void prev() {
    if (!state.open || state.step == 0) return;
    state = TourState(open: true, step: state.step - 1);
  }

  void close() => state = TourState(step: state.step);
}

/// Pasos del recorrido (se sobrescribe en pruebas).
final tourStepsProvider = Provider<List<TourStep>>((ref) => buildTourSteps());

final tourControllerProvider = NotifierProvider<TourController, TourState>(
  TourController.new,
);
