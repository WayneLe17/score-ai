import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:score_ai_app/features/auth/data/auth_repository.dart';
import 'package:score_ai_app/features/home/presentation/home_controller.dart';
import 'package:score_ai_app/core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  String _getFilenameFromPath(String path) {
    try {
      return path.split('/').last.split('?').first;
    } catch (e) {
      return 'Unknown File';
    }
  }

  String _getFolderNameFromPath(String path) {
    try {
      final parts = path.split('/');

      // Handle GCS paths: gs://bucket-name/folder/file or https://storage.googleapis.com/bucket-name/folder/file
      int folderStartIndex = 0;
      if (path.startsWith('gs://')) {
        // For gs:// URLs, folder starts after bucket name (skip gs://, empty string, bucket-name)
        folderStartIndex = 3;
      } else if (path.contains('storage.googleapis.com')) {
        // For HTTPS GCS URLs, folder starts after bucket name
        final bucketIndex = parts.indexOf('storage.googleapis.com');
        if (bucketIndex >= 0 && bucketIndex + 2 < parts.length) {
          folderStartIndex =
              bucketIndex + 2; // Skip storage.googleapis.com and bucket-name
        }
      }

      // Find the actual folder name (second-to-last part after skipping GCS prefix)
      if (parts.length > folderStartIndex + 1) {
        final folderIndex = parts.length - 2;
        if (folderIndex >= folderStartIndex) {
          return parts[folderIndex];
        }
      }

      return _getFilenameFromPath(path);
    } catch (e) {
      return 'Unknown Folder';
    }
  }

  bool _isImageFile(String filename) {
    final ext = filename.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png');
  }

  bool _isScannedImage(String filename) {
    final name = filename.toLowerCase();
    return name.contains('image_picker') ||
        name.contains('img_') ||
        name.startsWith('pic_') ||
        (name.contains(RegExp(r'\d{8,}')) && _isImageFile(filename));
  }

  String _getDisplayTitle(Map<String, dynamic> job) {
    final filePath = job['file_gcs_path'] ?? '';
    final filename = _getFilenameFromPath(filePath);
    if (job['status'] == 'completed' && job['first_question'] != null) {
      String question = job['first_question'].toString();
      if (question.length > 60) {
        question = '${question.substring(0, 57)}...';
      }
      return question;
    }
    if (_isImageFile(filename) && _isScannedImage(filename)) {
      return 'Scanned Problem';
    }
    if (!_isScannedImage(filename)) {
      final folderName = _getFolderNameFromPath(filePath);
      if (folderName != filename && folderName != 'Unknown Folder') {
        return folderName;
      }
    }
    return filename;
  }

  IconData _getJobIcon(Map<String, dynamic> job) {
    final filePath = job['file_gcs_path'] ?? '';
    final filename = _getFilenameFromPath(filePath);
    if (_isImageFile(filename)) {
      if (_isScannedImage(filename)) {
        return Icons.camera_alt_rounded;
      } else {
        return Icons.image_rounded;
      }
    } else if (filename.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }
    return Icons.description_rounded;
  }

  Widget _buildJobIcon(Map<String, dynamic> job, Color statusColor) {
    final filePath = job['file_gcs_path'] ?? '';
    final filename = _getFilenameFromPath(filePath);
    final jobIcon = _getJobIcon(job);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: statusColor.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isImageFile(filename) && _isScannedImage(filename)
          ? _buildImagePreview(filePath, statusColor)
          : Icon(
              jobIcon,
              color: statusColor,
              size: 24,
            ),
    );
  }

  Widget _buildImagePreview(String filePath, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withAlpha(77),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: statusColor.withAlpha(13),
          child: Icon(
            Icons.camera_alt_rounded,
            color: statusColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Account Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.clear_all_rounded,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                      ),
                      title: const Text('Clear All Solutions'),
                      subtitle: const Text('Delete all your saved solutions'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showClearAllDialog(context, ref);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                      ),
                      title: const Text('Sign Out'),
                      subtitle: const Text('Sign out of your account'),
                      onTap: () {
                        Navigator.of(context).pop();
                        ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Clear All Solutions'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete all your solutions? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(jobsControllerProvider.notifier)
                      .deleteAllJobs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All solutions cleared successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to clear solutions: $e'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteJobDialog(
      BuildContext context, WidgetRef ref, String jobId, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              const Text('Delete Solution'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$title"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(jobsControllerProvider.notifier)
                      .deleteJob(jobId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solution deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete solution: $e'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, String title) async {
    final colorScheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Text('Delete Solution'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete "$title"? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _formatJobDate(String dateString) {
    try {
      DateTime date;
      try {
        date = DateTime.parse(dateString);
      } catch (e) {
        date =
            DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'').parse(dateString);
      }
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = ref.watch(homeActionsControllerProvider);
    final jobsState = ref.watch(jobsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Score AI',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_circle_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              onPressed: () => _showAccountMenu(context, ref),
              tooltip: 'Account Settings',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withAlpha(26),
                  colorScheme.secondary.withAlpha(13),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withAlpha(102),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(48),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.waves_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to solve problems?',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload your math problems and get instant solutions',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isUploading != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(102),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Processing "$isUploading"...',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Solutions',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () => ref.invalidate(jobsControllerProvider),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: jobsState.when(
              loading: () => _buildLoadingState(colorScheme),
              error: (err, stack) => _buildErrorState(context, err.toString()),
              data: (List<Map<String, dynamic>> jobs) {
                if (jobs.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildJobsList(context, jobs, ref);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isUploading != null
          ? null
          : _buildFloatingActionButtons(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your solutions...',
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(179),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No solutions yet',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your first math problem to get started with AI-powered solutions',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList(
      BuildContext context, List<Map<String, dynamic>> jobs, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final filename = _getFilenameFromPath(job['file_gcs_path'] ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(job['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              final displayTitle = _getDisplayTitle(job);
              return await _showDeleteConfirmation(context, displayTitle);
            },
            onDismissed: (direction) {
              final displayTitle = _getDisplayTitle(job);
              ref
                  .read(jobsControllerProvider.notifier)
                  .deleteJob(job['id'])
                  .then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Solution deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete solution: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              });
            },
            child: _buildJobCard(context, job, filename, ref),
          ),
        );
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job,
      String filename, WidgetRef ref) {
    final status = job['status'] ?? 'unknown';
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppTheme.getStatusColor(status, isDark: isDark);
    final createdAt = job['created_at'] != null
        ? _formatJobDate(job['created_at'])
        : 'No date';
    final displayTitle = _getDisplayTitle(job);
    final jobIcon = _getJobIcon(job);
    final isCompletedWithQuestion =
        status == 'completed' && job['first_question'] != null;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: status == 'completed'
              ? () => context.go('/solution/${job['id']}?filename=$filename')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildJobIcon(job, statusColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: isCompletedWithQuestion ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            createdAt,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                          if (isCompletedWithQuestion) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Question',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(status),
                            style: textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.outline,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Ready';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  Widget _buildFloatingActionButtons(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "camera_fab",
              onPressed: () async {
                try {
                  await ref
                      .read(homeActionsControllerProvider.notifier)
                      .uploadFromCamera();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Camera access failed. Please check camera permissions and try again.',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        action: SnackBarAction(
                          label: 'Dismiss',
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                'Scan Problem',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              elevation: 0,
              highlightElevation: 0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "upload_fab",
              onPressed: () =>
                  ref.read(homeActionsControllerProvider.notifier).uploadFile(),
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text(
                'Upload File',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              elevation: 0,
              highlightElevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
