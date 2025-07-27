import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:score_ai_app/features/chat/presentation/chat_screen.dart';
import 'package:score_ai_app/features/solution/presentation/solution_controller.dart';
import 'package:score_ai_app/features/home/data/jobs_repository.dart';

class SolutionScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String filename;
  const SolutionScreen(
      {super.key, required this.jobId, required this.filename});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends ConsumerState<SolutionScreen> {
  late final PageController _pageController;
  int _currentQuestionIndex = 0;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _flattenResults(List<dynamic> results) {
    final List<Map<String, dynamic>> allQuestions = [];
    for (var pageResult in results) {
      final pageNumber = pageResult['page_number'];
      final qaPairs = pageResult['results'] as List;
      for (var qa in qaPairs) {
        allQuestions.add({
          ...qa,
          'page_number': pageNumber,
        });
      }
    }
    return allQuestions;
  }

  void _showDeleteJobDialog(BuildContext context, WidgetRef ref) {
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
            'Are you sure you want to delete "${widget.filename}"? This action cannot be undone.',
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
                      .read(jobsRepositoryProvider)
                      .deleteJob(widget.jobId);
                  if (context.mounted) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
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

  String _formatAnswerText(String answer) {
    if (answer.isEmpty) return 'No solution available';
    String formatted = answer;
    formatted = formatted.replaceAll('\\n', '\n');
    formatted =
        formatted.replaceAll(RegExp(r'\$\s*\n\s*([^\n$]+)\s*\n\s*\$'), r'$$1$');
    formatted = formatted.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    formatted = formatted.trim();
    return formatted;
  }

  Widget _buildMathContent(String text, TextStyle? style) {
    if (text.isEmpty) {
      return Text('No content available', style: style);
    }
    return RichText(
      text: _buildFormattedTextSpan(text, style),
    );
  }

  TextSpan _buildFormattedTextSpan(String text, TextStyle? baseStyle) {
    final children = <TextSpan>[];
    final regex = RegExp(r'\$([^$]+)\$');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start);
        if (beforeText.isNotEmpty) {
          children.add(TextSpan(
            text: beforeText,
            style: baseStyle,
          ));
        }
      }
      final mathExpression = match.group(1)!;
      children.add(TextSpan(
        text: mathExpression,
        style: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: baseStyle.color?.withAlpha(26),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        children.add(TextSpan(
          text: remainingText,
          style: baseStyle,
        ));
      }
    }
    if (children.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final solutionState = ref.watch(solutionControllerProvider(widget.jobId));
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.filename,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'AI Solutions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
                size: 20,
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
              ),
              onPressed: () => _showDeleteJobDialog(context, ref),
              tooltip: 'Delete Solution',
            ),
          ),
        ],
      ),
      body: solutionState.when(
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(err.toString()),
        data: (data) {
          if (data['status'] != 'completed') {
            return _buildProcessingState();
          }
          final allQuestions = _flattenResults(data['results'] as List);
          if (allQuestions.isEmpty) {
            return _buildEmptyState();
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: allQuestions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildQuestionCard(allQuestions[index]);
                  },
                ),
              ),
              _buildNavigationControls(allQuestions),
            ],
          );
        },
      ),
      floatingActionButton: solutionState.when(
        data: (data) => FloatingActionButton(
          onPressed: () {
            final allQuestions = _flattenResults(data['results'] as List);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ChatScreen(
                  jobId: widget.jobId,
                  question: allQuestions[_currentQuestionIndex],
                ),
              ),
            );
          },
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        loading: () => const SizedBox(),
        error: (error, stack) => const SizedBox(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Solutions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing your math problems...',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Solutions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildProcessingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
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
            color: colorScheme.primary.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI is Working',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your job is still being processed by our AI. Please check back in a few moments.',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(179),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.refresh(solutionControllerProvider(widget.jobId)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
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
              'No Questions Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any math problems in this document. Please try uploading a clearer image.',
              style: TextStyle(
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

  Widget _buildQuestionCard(Map<String, dynamic> qa) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withAlpha(26),
                    colorScheme.primary.withAlpha(13),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Problem',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(51),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: qa['question']?.toString().isNotEmpty == true
                        ? _buildMathContent(
                            _formatAnswerText(qa['question']),
                            textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            'No question text available',
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI Solution',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.secondary.withAlpha(20),
                          colorScheme.tertiary.withAlpha(13),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.secondary.withAlpha(77),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: qa['answer']?.toString().isNotEmpty == true
                        ? _buildMathContent(
                            _formatAnswerText(qa['answer']),
                            textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            'No solution available',
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(List<Map<String, dynamic>> allQuestions) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha(38),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _currentQuestionIndex > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentQuestionIndex > 0
                      ? colorScheme.secondary.withAlpha(26)
                      : colorScheme.outline.withAlpha(26),
                  foregroundColor: _currentQuestionIndex > 0
                      ? colorScheme.secondary
                      : colorScheme.onSurface.withAlpha(102),
                  elevation: _currentQuestionIndex > 0 ? 2 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(38),
                    colorScheme.primary.withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(51),
                  width: 1,
                ),
              ),
              child: Text(
                '${_currentQuestionIndex + 1}/${allQuestions.length}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _currentQuestionIndex < allQuestions.length - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _currentQuestionIndex < allQuestions.length - 1
                          ? colorScheme.primary
                          : colorScheme.outline.withAlpha(26),
                  foregroundColor:
                      _currentQuestionIndex < allQuestions.length - 1
                          ? Colors.white
                          : colorScheme.onSurface.withAlpha(102),
                  elevation:
                      _currentQuestionIndex < allQuestions.length - 1 ? 3 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
