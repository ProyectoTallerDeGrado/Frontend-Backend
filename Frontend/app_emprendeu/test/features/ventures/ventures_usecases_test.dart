import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/documents/domain/entities/picked_file.dart';
import 'package:app_emprendeu/features/documents/domain/usecases/documents_usecases.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture.dart';
import 'package:app_emprendeu/features/ventures/domain/usecases/milestones_usecases.dart';
import 'package:app_emprendeu/features/ventures/domain/usecases/update_venture_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../documents/fake_documents.dart';

void main() {
  group('UpdateVentureUseCase (CU05)', () {
    test('rechaza un nombre vacío sin llamar al servidor', () async {
      final repo = FakeVenturesRepository(
        venture: const Venture(id: 1, name: 'Sabores'),
      );
      final result = await UpdateVentureUseCase(repo)(1, name: '   ');
      expect(result.failureOrNull, isA<FieldFailure>());
      expect((result.failureOrNull as FieldFailure).field, 'name');
      expect(repo.updateCalls, 0);
    });

    test('limpia espacios y envía vacíos como nulos', () async {
      final repo = FakeVenturesRepository(
        venture: const Venture(id: 1, name: 'Sabores'),
      );
      final result = await UpdateVentureUseCase(repo)(
        1,
        name: '  Tejidos  ',
        description: '   ',
        sector: ' Textil ',
      );
      expect(result.valueOrNull?.name, 'Tejidos');
      expect(repo.lastUpdatedDescription, isNull);
      expect(repo.lastUpdatedSector, 'Textil');
    });
  });

  group('CreateMilestoneUseCase (CU20)', () {
    test('exige un título', () async {
      final repo = FakeVenturesRepository();
      final result = await CreateMilestoneUseCase(repo)(1, title: ' ');
      expect((result.failureOrNull as FieldFailure).field, 'title');
      expect(repo.milestoneCalls, 0);
    });

    test('guarda la descripción solo si hay texto', () async {
      final repo = FakeVenturesRepository();
      final result = await CreateMilestoneUseCase(repo)(
        1,
        title: ' Primer prototipo ',
        description: '  ',
      );
      expect(result.valueOrNull?.title, 'Primer prototipo');
      expect(result.valueOrNull?.description, isNull);
    });
  });

  group('UploadEvidenceUseCase (CU20)', () {
    test('rechaza una extensión no permitida sin subir nada', () async {
      final repo = FakeDocumentsRepository();
      final result = await UploadEvidenceUseCase(repo)(
        ventureId: 1,
        milestoneId: 2,
        file: const PickedFile(name: 'virus.exe', path: '/tmp/virus.exe'),
      );
      expect((result.failureOrNull as FieldFailure).field, 'file');
      expect(repo.uploadCalls, 0);
    });

    test('acepta mayúsculas y sube con el hito indicado', () async {
      final repo = FakeDocumentsRepository();
      final result = await UploadEvidenceUseCase(repo)(
        ventureId: 7,
        milestoneId: 2,
        file: const PickedFile(name: 'FOTO.JPG', path: '/tmp/FOTO.JPG'),
      );
      expect(result.valueOrNull?.milestoneId, 2);
      expect(repo.lastVentureId, 7);
    });
  });
}
