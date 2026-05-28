import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/widgets/disclaimer_overlay.dart';
import '../../../shared/utils/content_safety.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  // _posts populated from API in future phases


  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Feed',
                        style: AppTextStyles.largeTitle.copyWith(color: text)),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: text, size: 28),
                    onPressed: () => _showCreatePost(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              labelColor: text,
              unselectedLabelColor:
                  isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
              indicatorColor: text,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Rounds'),
                Tab(text: 'Cases'),
                Tab(text: 'Life'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _RoundsTab(),
                  _CasesTab(),
                  _LifeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    final type = ['rounds', 'cases', 'life'][_tabCtrl.index];
    if (type == 'cases') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => DisclaimerOverlay(
          variant: DisclaimerVariant.casePost,
          onConfirm: () => _showCreatePostSheet(context, type),
        ),
      );
    } else {
      _showCreatePostSheet(context, type);
    }
  }

  void _showCreatePostSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(defaultType: type),
    );
  }
}

// ─── Rounds tab ────────────────────────────────────────────────────────────────
class _RoundsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Placeholder empty state
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.play_circle_outline, size: 64, color: sub),
              const SizedBox(height: 16),
              Text('No Rounds videos yet',
                  style: AppTextStyles.headline.copyWith(color: sub)),
              const SizedBox(height: 8),
              Text('Verified doctors share clinical videos here.',
                  style: AppTextStyles.subheadline.copyWith(color: sub),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Cases tab ─────────────────────────────────────────────────────────────────
class _CasesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // MCQ of the Day pinned card
        _McqDayCard(),
        const SizedBox(height: 16),
        // Empty state
        Center(
          child: Column(
            children: [
              Icon(Icons.article_outlined, size: 48, color: sub),
              const SizedBox(height: 12),
              Text('No case posts yet',
                  style: AppTextStyles.headline.copyWith(color: sub)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Life tab ──────────────────────────────────────────────────────────────────
class _LifeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Column(
          children: [
            Icon(Icons.photo_outlined, size: 64, color: sub),
            const SizedBox(height: 16),
            Text('No life posts yet',
                style: AppTextStyles.headline.copyWith(color: sub)),
            const SizedBox(height: 8),
            Text('Share moments from medical life.',
                style: AppTextStyles.subheadline.copyWith(color: sub),
                textAlign: TextAlign.center),
          ],
        ),
      ],
    );
  }
}

// ─── MCQ of the day in feed ────────────────────────────────────────────────────
class _McqDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('MCQ of the Day',
                      style: AppTextStyles.caption.copyWith(
                          color: fg, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today\'s clinical question is live. Can you get it right?',
                  style: AppTextStyles.subheadline.copyWith(color: fg, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz_outlined, color: fg, size: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Create post sheet ─────────────────────────────────────────────────────────
class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.defaultType});
  final String defaultType;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  late String _type;
  final _contentCtrl = TextEditingController();
  String? _topicTag;
  bool _loading = false;
  List<String> _safetyWarnings = [];
  Timer? _safetyDebounce;

  static const _topics = [
    'Cardiology', 'Medicine', 'Surgery', 'Paediatrics',
    'OBG', 'Pharmacology', 'Pathology', 'NEET PG',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  void dispose() {
    _safetyDebounce?.cancel();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    setState(() {});
    _safetyDebounce?.cancel();
    _safetyDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _safetyWarnings =
              ContentSafety.checkForPatientIdentifiers(text);
        });
      }
    });
  }

  Future<void> _post() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/api/posts/create', {
        'type': _type,
        'content': _contentCtrl.text.trim(),
        'topicTag': _topicTag,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Create post', style: AppTextStyles.title3.copyWith(color: text)),
            const SizedBox(height: 16),
            // Type selector
            Row(
              children: [
                _TypeChip(label: 'Rounds', value: 'rounds', current: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 8),
                _TypeChip(label: 'Case', value: 'cases', current: _type,
                    onTap: (v) => setState(() => _type = v)),
                const SizedBox(width: 8),
                _TypeChip(label: 'Life', value: 'life', current: _type,
                    onTap: (v) => setState(() => _type = v)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              maxLength: 1000,
              style: AppTextStyles.body.copyWith(color: text),
              decoration: InputDecoration(
                hintText: _type == 'rounds'
                    ? 'Describe the clinical case...'
                    : _type == 'cases'
                        ? 'Write your case post...'
                        : 'What\'s happening in medical life?',
                hintStyle: AppTextStyles.body.copyWith(color: sub),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onContentChanged,
            ),
            if (_safetyWarnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ This post may contain patient identifiers. Please review before posting.',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF856404)),
                    ),
                    const SizedBox(height: 6),
                    ..._safetyWarnings.map((w) => Text(
                          '• $w',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF856404)),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Topic tag
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _topics.map((t) => GestureDetector(
                onTap: () => setState(() => _topicTag = _topicTag == t ? null : t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _topicTag == t
                        ? text
                        : (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: AppTextStyles.caption.copyWith(
                      color: _topicTag == t
                          ? (isDark ? Colors.black : Colors.white)
                          : sub,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _contentCtrl.text.isNotEmpty ? _post : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label, required this.value,
    required this.current, required this.onTap,
  });
  final String label, value, current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value == current;
    final text = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? text : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? text
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.subheadline.copyWith(
            color: isActive
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
