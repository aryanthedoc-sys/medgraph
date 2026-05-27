import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';
import '../../../shared/widgets/mg_text_field.dart';
import '../../../shared/services/api_service.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Sessions',
                        style: AppTextStyles.largeTitle.copyWith(color: text)),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: text),
                    onPressed: () => _showBookSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: text,
              unselectedLabelColor:
                  isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
              indicatorColor: text,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _SessionsList(upcoming: true),
                  _SessionsList(upcoming: false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookSheet(context),
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book a session'),
      ),
    );
  }

  void _showBookSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BookSessionSheet(),
    );
  }
}

class _SessionsList extends StatelessWidget {
  const _SessionsList({required this.upcoming});
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    // Placeholder — real data comes from API
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Icon(
                upcoming
                    ? Icons.calendar_today_outlined
                    : Icons.history,
                size: 48,
                color: sub,
              ),
              const SizedBox(height: 16),
              Text(
                upcoming
                    ? 'No upcoming sessions'
                    : 'No past sessions yet',
                style: AppTextStyles.headline.copyWith(color: sub),
              ),
              const SizedBox(height: 8),
              Text(
                upcoming
                    ? 'Book a session to get matched with a peer.'
                    : 'Completed sessions will appear here.',
                style: AppTextStyles.subheadline.copyWith(color: sub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookSessionSheet extends StatefulWidget {
  const _BookSessionSheet();

  @override
  State<_BookSessionSheet> createState() => _BookSessionSheetState();
}

class _BookSessionSheetState extends State<_BookSessionSheet> {
  final _topicCtrl = TextEditingController();
  final String _mode = 'study';
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;

  static const _topicSuggestions = [
    'Cardiology', 'Pharmacology', 'Anatomy', 'Surgery',
    'NEET PG', 'Pathology', 'Medicine', 'Microbiology',
    'Biochemistry', 'Physiology',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    if (_topicCtrl.text.trim().isEmpty || _date == null || _time == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/api/sessions/request', {
        'topic': _topicCtrl.text.trim(),
        'mode': _mode,
        'date': _date!.toIso8601String().substring(0, 10),
        'time':
            '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session requested! You\'ll be notified when matched.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
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
    final sub =
        isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Book a session',
                style: AppTextStyles.title3.copyWith(color: text)),
            const SizedBox(height: 20),
            MGTextField(
              hint: 'Topic (e.g. Cardiology, NEET PG)',
              controller: _topicCtrl,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            // Topic suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topicSuggestions.map((t) => GestureDetector(
                onTap: () => setState(() => _topicCtrl.text = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface2
                        : AppColors.lightSurface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(t,
                      style:
                          AppTextStyles.footnote.copyWith(color: text)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Date picker
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: sub, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _date == null
                          ? 'Select date'
                          : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: AppTextStyles.subheadline.copyWith(
                        color: _date == null ? sub : text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Time picker
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: sub, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _time == null
                          ? 'Select time'
                          : _time!.format(context),
                      style: AppTextStyles.subheadline.copyWith(
                        color: _time == null ? sub : text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Booking is free for all users. You\'ll be notified when matched.',
                    style: AppTextStyles.caption.copyWith(color: sub),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MGButton(
              label: 'Request session',
              onPressed:
                  (_topicCtrl.text.isNotEmpty && _date != null && _time != null)
                      ? _book
                      : null,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
