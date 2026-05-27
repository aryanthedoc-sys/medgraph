import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// MCQ of the Day card shown on the Home screen.
class MCQCard extends StatefulWidget {
  const MCQCard({super.key});

  @override
  State<MCQCard> createState() => _MCQCardState();
}

class _MCQCardState extends State<MCQCard> {
  String? _selectedAnswer;
  bool _revealed = false;

  // Placeholder — will be fetched from API
  final _q = 'A 45-year-old patient presents with chest pain radiating to the left arm. ECG shows ST elevation in leads II, III, and aVF. Which artery is most likely occluded?';
  final _options = {
    'a': 'Left Anterior Descending',
    'b': 'Right Coronary Artery',
    'c': 'Left Circumflex',
    'd': 'Posterior Descending',
  };
  final _correct = 'b';
  final _explanation = 'Inferior STEMI (II, III, aVF) is classically caused by RCA occlusion. The RCA supplies the inferior wall of the left ventricle in ~85% of patients.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MCQ of the Day',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _q,
            style: AppTextStyles.subheadline.copyWith(
              color: isDark ? Colors.black : Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._options.entries.map((e) => _OptionButton(
            letter: e.key.toUpperCase(),
            text: e.value,
            state: _selectedAnswer == null
                ? _OptionState.idle
                : _selectedAnswer == e.key
                    ? (e.key == _correct ? _OptionState.correct : _OptionState.wrong)
                    : (e.key == _correct && _revealed ? _OptionState.correct : _OptionState.dimmed),
            isDark: isDark,
            onTap: _selectedAnswer == null
                ? () => setState(() {
                    _selectedAnswer = e.key;
                    _revealed = true;
                  })
                : null,
          )),
          if (_revealed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _explanation,
                style: AppTextStyles.footnote.copyWith(
                  color: isDark ? Colors.black87 : Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.text,
    required this.state,
    required this.isDark,
    this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final bool isDark;
  final VoidCallback? onTap;

  Color get _bg {
    switch (state) {
      case _OptionState.correct: return AppColors.success.withValues(alpha: 0.2);
      case _OptionState.wrong:   return AppColors.danger.withValues(alpha: 0.2);
      case _OptionState.dimmed:  return Colors.transparent;
      case _OptionState.idle:
        return isDark
            ? Colors.black.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1);
    }
  }

  Color get _fg {
    if (state == _OptionState.dimmed) {
      return isDark ? Colors.black38 : Colors.white38;
    }
    return isDark ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.black.withAlpha(40) : Colors.white.withAlpha(40),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(letter,
                    style: AppTextStyles.caption
                        .copyWith(color: _fg, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.subheadline.copyWith(color: _fg)),
            ),
          ],
        ),
      ),
    );
  }
}
