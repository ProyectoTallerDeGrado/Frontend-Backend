import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registro `id → GlobalKey` de los elementos que el tutorial puede resaltar.
class TourTargets {
  final _keys = <String, GlobalKey>{};

  GlobalKey keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour:$id'));

  /// Zona en pantalla del elemento, o `null` si no está montado.
  Rect? rectOf(String id) {
    final context = _keys[id]?.currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Desplaza el elemento hasta que se vea (si está dentro de un scroll).
  Future<void> reveal(String id) async {
    final context = _keys[id]?.currentContext;
    if (context == null || !context.mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.3,
      duration: const Duration(milliseconds: 250),
    );
  }
}

final tourTargetsProvider = Provider<TourTargets>((ref) => TourTargets());

/// Marca [child] como resaltable por el paso `target == id` del tutorial.
class TourTarget extends ConsumerWidget {
  const TourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KeyedSubtree(
    key: ref.watch(tourTargetsProvider).keyFor(id),
    child: child,
  );
}
