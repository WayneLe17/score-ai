import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/features/solution/data/solution_repository.dart';
final solutionControllerProvider = StateNotifierProvider.autoDispose
    .family<SolutionController, AsyncValue<Map<String, dynamic>>, String>(
        (ref, jobId) {
  return SolutionController(ref.watch(solutionRepositoryProvider(jobId)));
});
class SolutionController
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final SolutionRepository _solutionRepository;
  SolutionController(this._solutionRepository)
      : super(const AsyncValue.loading()) {
    getSolution();
  }
  Future<void> getSolution({String? cursor}) async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final result = await _solutionRepository.getSolution(cursor: cursor);
      if (mounted) {
        state = AsyncValue.data(result);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}