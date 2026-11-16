import 'package:app_emprendeu/core/storage/providers.dart';
import 'package:app_emprendeu/features/ventures/presentation/controllers/ventures_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

ProviderContainer _container(InMemoryKeyValueStore store) {
  final container = ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'el emprendimiento elegido se recuerda al reabrir la app (CU05)',
    () async {
      final store = InMemoryKeyValueStore();
      final first = _container(store);
      first.read(selectedVentureIdProvider.notifier).select(2);
      expect(first.read(selectedVentureIdProvider), 2);

      // Otra «apertura» de la app con el mismo almacenamiento del dispositivo.
      final second = _container(store);
      expect(second.read(selectedVentureIdProvider), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(second.read(selectedVentureIdProvider), 2);
    },
  );

  test('sin elección guardada se queda en el primero', () async {
    final container = _container(InMemoryKeyValueStore());
    container.read(selectedVentureIdProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(selectedVentureIdProvider), isNull);
  });

  test('una elección hecha antes de terminar de leer no se pisa', () async {
    final store = InMemoryKeyValueStore()
      ..data[SelectedVentureController.storageKey] = '1';
    final container = _container(store);
    container.read(selectedVentureIdProvider);
    container.read(selectedVentureIdProvider.notifier).select(3);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(selectedVentureIdProvider), 3);
  });
}
