import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:score_ai_app/features/home/data/jobs_repository.dart';

final jobsControllerProvider = StateNotifierProvider.autoDispose<JobsController,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return JobsController(ref.watch(jobsRepositoryProvider));
});

class JobsController
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final JobsRepository _jobsRepository;
  JobsController(this._jobsRepository) : super(const AsyncValue.loading()) {
    fetchJobs();
  }
  Future<void> fetchJobs() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final jobs = await _jobsRepository.getJobs();
      if (mounted) {
        state = AsyncValue.data(jobs);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> deleteJob(String jobId) async {
    if (!mounted) return;
    try {
      await _jobsRepository.deleteJob(jobId);
      if (mounted) {
        await fetchJobs();
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> deleteAllJobs() async {
    if (!mounted) return;
    try {
      await _jobsRepository.deleteAllJobs();
      if (mounted) {
        await fetchJobs();
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

final homeActionsControllerProvider =
    StateNotifierProvider.autoDispose<HomeActionsController, String?>((ref) {
  return HomeActionsController(ref);
});

class HomeActionsController extends StateNotifier<String?> {
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();

  HomeActionsController(this._ref) : super(null);

  Future<void> _uploadAndUpdate({
    File? mobileFile,
    Uint8List? webFileBytes,
    required String fileName,
  }) async {
    if (!mounted) return;
    state = fileName;
    try {
      await _ref.read(jobsRepositoryProvider).uploadFile(
            mobileFile: mobileFile,
            webFileBytes: webFileBytes,
            fileName: fileName,
          );
      if (mounted) {
        _ref.invalidate(jobsControllerProvider);
      }
    } finally {
      if (mounted) {
        state = null;
      }
    }
  }

  Future<void> uploadFile() async {
    if (!mounted) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb,
    );
    if (result != null && mounted) {
      final file = result.files.single;
      await _uploadAndUpdate(
        mobileFile: kIsWeb ? null : File(file.path!),
        webFileBytes: file.bytes,
        fileName: file.name,
      );
    }
  }

  Future<void> uploadFromCamera() async {
    if (!mounted) return;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        await _uploadAndUpdate(
          mobileFile: kIsWeb ? null : File(image.path),
          webFileBytes: await image.readAsBytes(),
          fileName: image.name,
        );
      }
    } catch (e) {
      print('Camera error: $e');
      rethrow;
    }
  }
}
