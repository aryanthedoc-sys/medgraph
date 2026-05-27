import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mg_button.dart';

/// Holds the currently active filter state.
class SessionFilters {
  String? college;   // 'same' | 'outside' | null (any)
  String? location;  // 'city' | 'state' | null (anywhere)
  int?    year;      // academic year 1-7
  String? specialty; // specialty name (Pro only)
}

/// Bottom sheet that slides up to let the user configure session filters.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.filters,
    required this.onApply,
    required this.isPro,
  });

  final SessionFilters filters;
  final ValueChanged<SessionFilters> onApply;
  final bool isPro;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _college;
  late String? _location;
  late int?    _year;
  late String? _specialty;

  static const _years = [
    '1st', '2nd', '3rd', '4th', '5th', 'Intern', 'PG',
  ];

  static const _specialties = [
    'General Medicine', 'Surgery', 'Paediatrics', 'OBG',
    'Cardiology', 'Neurology', 'Orthopaedics', 'Psychiatry',
    'Dermatology', 'ENT', 'Radiology', 'Anaesthesia',
    'Pathology', 'Emergency', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _college   = widget.filters.college;
    _location  = widget.filters.location;
    _year      = widget.filters.year;
    _specialty = widget.filters.specialty;
  }

  void _apply() {
    final f = SessionFilters()
      ..college   = _college
      ..location  = _location
      ..year      = _year
      ..specialty = _specialty;
    widget.onApply(f);
    Navigator.pop(context);
  }

  void _reset() => setState(() {
    _college = _location = _specialty = null;
    _year = null;
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkSurface  : Colors.white;
    final text   = isDark ? Colors.white            : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: sub.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Find your match',
                      style: AppTextStyles.title3.copyWith(color: text)),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text('Reset', style: TextStyle(color: sub)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── College ─────────────────────────────────────────────
            _SectionLabel(label: 'College', color: text),
            const SizedBox(height: 10),
            _PillRow(
              options: const ['Same college', 'Outside college', 'Any'],
              values:  const ['same', 'outside', null],
              selected: _college,
              onSelect: (v) => setState(() => _college = v),
              text: text,
            ),
            const SizedBox(height: 20),

            // ── Location ─────────────────────────────────────────────
            _SectionLabel(label: 'Location', color: text),
            const SizedBox(height: 10),
            _PillRow(
              options: const ['Same city', 'Same state', 'Anywhere'],
              values:  const ['city', 'state', null],
              selected: _location,
              onSelect: (v) => setState(() => _location = v),
              text: text,
            ),
            const SizedBox(height: 20),

            // ── Year ─────────────────────────────────────────────────
            _SectionLabel(label: 'Year', color: text),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _years.length + 1, // +1 for "Any"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _Pill(
                      label: 'Any',
                      isSelected: _year == null,
                      onTap: () => setState(() => _year = null),
                      text: text,
                    );
                  }
                  return _Pill(
                    label: _years[i - 1],
                    isSelected: _year == i,
                    onTap: () => setState(() => _year = i),
                    text: text,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Specialty (Pro only) ──────────────────────────────────
            Row(
              children: [
                _SectionLabel(label: 'Specialty', color: text),
                const SizedBox(width: 8),
                if (!widget.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.proGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 11, color: AppColors.proGold),
                        const SizedBox(width: 4),
                        Text('Pro',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.proGold,
                                    fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!widget.isPro)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to upgrade from parent
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.proGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.proGold.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.proGold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Upgrade to Pro to filter by specialty',
                          style: AppTextStyles.subheadline
                              .copyWith(color: AppColors.proGold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _specialties.map((s) => _Pill(
                  label: s,
                  isSelected: _specialty == s,
                  onTap: () => setState(
                      () => _specialty = _specialty == s ? null : s),
                  text: text,
                )).toList(),
              ),

            const SizedBox(height: 28),
            MGButton(label: 'Apply filters', onPressed: _apply),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.headline.copyWith(color: color));
}

class _PillRow extends StatelessWidget {
  const _PillRow({
    required this.options,
    required this.values,
    required this.selected,
    required this.onSelect,
    required this.text,
  });

  final List<String> options;
  final List<String?> values;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final Color text;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(options.length, (i) => Padding(
      padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
      child: _Pill(
        label: options[i],
        isSelected: selected == values[i],
        onTap: () => onSelect(values[i]),
        text: text,
      ),
    )),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.text,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? text : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? text
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.subheadline.copyWith(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
