import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/api_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _collegeNameCtrl;
  late final TextEditingController _universityCtrl;
  late final TextEditingController _collegeCityCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _neetTargetCtrl;

  String? _selectedSpecialty;
  String? _yearOfStudy;
  String? _collegeState;
  List<String> _tags = [];
  List<String> _languages = [];
  bool _loading = false;
  String? _handleError;

  Uint8List? _pickedBytes;
  String _pickedMime   = 'image/jpeg';
  bool _uploadingAvatar = false;

  static const _specialties = [
    'General Medicine', 'Internal Medicine', 'Surgery',
    'Paediatrics', 'Obstetrics & Gynaecology', 'Cardiology',
    'Dermatology', 'Orthopaedics', 'Neurology', 'Psychiatry',
    'Radiology', 'Anaesthesia', 'Pathology', 'Ophthalmology',
    'ENT', 'Urology', 'Nephrology', 'Gastroenterology',
    'Pulmonology', 'Endocrinology', 'Oncology', 'Rheumatology',
    'Other',
  ];

  static const _yearOptions = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', 'Intern',
  ];

  static const _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
    'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh',
    'Chandigarh', 'Puducherry',
  ];

  static const _allLanguages = [
    'English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam',
    'Bengali', 'Marathi', 'Gujarati', 'Punjabi', 'Urdu',
  ];

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider)!;
    _nameCtrl       = TextEditingController(text: u.fullName);
    _bioCtrl        = TextEditingController(text: u.bio ?? '');
    _phoneCtrl      = TextEditingController(text: u.phone ?? '');
    _handleCtrl     = TextEditingController(text: u.handle ?? '');
    _collegeNameCtrl= TextEditingController(text: u.collegeName ?? u.college ?? '');
    _universityCtrl = TextEditingController(text: u.university ?? '');
    _collegeCityCtrl= TextEditingController(text: u.collegeCity ?? u.city ?? '');
    _hospitalCtrl   = TextEditingController(text: u.hospital ?? '');
    _neetTargetCtrl = TextEditingController();
    _selectedSpecialty = u.specialty;
    _yearOfStudy    = u.yearOfStudy;
    _collegeState   = u.collegeState ?? u.state;
    _tags           = List<String>.from(u.tags);
    _languages      = List<String>.from(u.languages);
    _bioCtrl.addListener(() => setState(() {}));
    _handleCtrl.addListener(_validateHandle);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _handleCtrl.dispose();
    _collegeNameCtrl.dispose();
    _universityCtrl.dispose();
    _collegeCityCtrl.dispose();
    _hospitalCtrl.dispose();
    _neetTargetCtrl.dispose();
    super.dispose();
  }

  void _validateHandle() {
    final v = _handleCtrl.text;
    if (v.isEmpty) { setState(() => _handleError = null); return; }
    setState(() => _handleError = RegExp(r'^[a-z0-9-]{3,40}$').hasMatch(v)
        ? null
        : 'Lowercase letters, numbers and hyphens only (3–40 chars)');
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery,
        maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _pickedBytes = bytes; _pickedMime = picked.mimeType ?? 'image/jpeg'; });
  }

  void _addTag() {
    if (_tags.length >= 5) return;
    showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add tag'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Cardiology, NEET PG'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((tag) {
      if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
        setState(() => _tags.add(tag));
      }
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) { _showSnack('Full name cannot be empty.'); return; }
    if (_handleError != null) return;

    setState(() => _loading = true);
    try {
      String? newAvatarUrl;
      if (_pickedBytes != null) {
        setState(() => _uploadingAvatar = true);
        final ext = _pickedMime.split('/').last;
        final result = await ApiService.uploadFile(
          path: '/api/uploads/avatar',
          fieldName: 'file',
          fileBytes: _pickedBytes!,
          filename: 'avatar.$ext',
          mimeType: _pickedMime,
        );
        newAvatarUrl = result['avatarUrl'] as String?;
        setState(() => _uploadingAvatar = false);
      }

      final user = ref.read(currentUserProvider)!;
      final body = <String, dynamic>{
        'full_name':     _nameCtrl.text.trim(),
        'bio':           _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'phone':         _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'handle':        _handleCtrl.text.trim().isEmpty ? null : _handleCtrl.text.trim(),
        'college_name':  _collegeNameCtrl.text.trim().isEmpty ? null : _collegeNameCtrl.text.trim(),
        'university':    _universityCtrl.text.trim().isEmpty ? null : _universityCtrl.text.trim(),
        'college_city':  _collegeCityCtrl.text.trim().isEmpty ? null : _collegeCityCtrl.text.trim(),
        'college_state': _collegeState,
        'tags':          _tags,
        'languages':     _languages,
        if (user.isStudent) ...{
          'year_of_study': _yearOfStudy,
          if (_neetTargetCtrl.text.isNotEmpty)
            'neet_pg_target_year': int.tryParse(_neetTargetCtrl.text),
        },
        if (user.isDoctor) ...{
          'specialty': _selectedSpecialty,
          'hospital':  _hospitalCtrl.text.trim().isEmpty ? null : _hospitalCtrl.text.trim(),
        },
      };

      final data    = await ApiService.patch('/api/profiles/me', body);
      final updated = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final finalUser = newAvatarUrl != null ? updated.copyWith(avatarUrl: newAvatarUrl) : updated;
      ref.read(currentUserProvider.notifier).setUser(finalUser);

      if (mounted) {
        _showSnack('Profile updated ✓');
        context.pop();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 409) setState(() => _handleError = 'Handle is already taken');
      else _showSnack('Error: ${e.message}');
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() { _loading = false; _uploadingAvatar = false; });
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(currentUserProvider)!;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bg      = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: TextButton(
          onPressed: _loading ? null : () => context.pop(),
          child: Text('Cancel', style: AppTextStyles.body.copyWith(
              color: _loading ? sub : text)),
        ),
        leadingWidth: 80,
        title: Text('Edit Profile', style: AppTextStyles.headline.copyWith(color: text)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _loading
                ? const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : TextButton(
                    onPressed: _save,
                    child: Text('Save', style: AppTextStyles.body.copyWith(
                        color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Avatar ──────────────────────────────────────────────
                  _AvatarPicker(
                    user: user,
                    pickedBytes: _pickedBytes,
                    uploading: _uploadingAvatar,
                    onTap: _pickAvatar,
                  ),
                  const SizedBox(height: 28),

                  // ── Basic info ──────────────────────────────────────────
                  _SectionLabel('BASIC INFO', sub),
                  _Tile(surface: surface, child: Column(children: [
                    _Field(hint: 'Full name', controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next),
                    _Divider(isDark),
                    _Field(hint: 'Bio — tell peers who you are',
                        controller: _bioCtrl, maxLines: 4, maxLength: 300,
                        textInputAction: TextInputAction.newline),
                  ])),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 20, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('${_bioCtrl.text.length} / 300',
                          style: AppTextStyles.caption.copyWith(color: sub)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tags ────────────────────────────────────────────────
                  _SectionLabel('INTERESTS & TAGS', sub),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ..._tags.map((tag) => Chip(
                          label: Text(tag, style: TextStyle(fontSize: 13, color: AppColors.teal)),
                          backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.3)),
                          deleteIconColor: AppColors.teal,
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                        )),
                        if (_tags.length < 5)
                          ActionChip(
                            label: Text('+ Add tag',
                                style: AppTextStyles.footnote.copyWith(color: sub)),
                            backgroundColor: surface,
                            onPressed: _addTag,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Academic / Professional ──────────────────────────────
                  if (user.isStudent) ...[
                    _SectionLabel('ACADEMIC', sub),
                    _Tile(surface: surface, child: Column(children: [
                      _Field(hint: 'College name', controller: _collegeNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next),
                      _Divider(isDark),
                      _Field(hint: 'University / Affiliation', controller: _universityCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next),
                    ])),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: _yearOfStudy,
                        decoration: InputDecoration(
                          labelText: 'Year of study',
                          labelStyle: AppTextStyles.body.copyWith(color: sub),
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: _yearOptions.map((y) => DropdownMenuItem(
                          value: y, child: Text(y))).toList(),
                        onChanged: (v) => setState(() => _yearOfStudy = v),
                        dropdownColor: surface,
                        style: AppTextStyles.body.copyWith(color: text),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Tile(surface: surface, child: _Field(
                        hint: 'NEET PG target year (optional)',
                        controller: _neetTargetCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      )),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (user.isDoctor) ...[
                    _SectionLabel('PROFESSIONAL', sub),
                    _Tile(surface: surface, child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSpecialty,
                            hint: Text('Specialty', style: AppTextStyles.body.copyWith(color: sub)),
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down, color: sub, size: 20),
                            dropdownColor: surface,
                            style: AppTextStyles.body.copyWith(color: text),
                            items: _specialties.map((s) =>
                                DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedSpecialty = v),
                          ),
                        ),
                      ),
                      _Divider(isDark),
                      _Field(hint: 'Hospital / Institution', controller: _hospitalCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next),
                    ])),
                    const SizedBox(height: 24),
                  ],

                  // ── Location ────────────────────────────────────────────
                  _SectionLabel('LOCATION', sub),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      DropdownButtonFormField<String>(
                        value: _collegeState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          labelStyle: AppTextStyles.body.copyWith(color: sub),
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: _indianStates.map((s) => DropdownMenuItem(
                          value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _collegeState = v),
                        dropdownColor: surface,
                        style: AppTextStyles.body.copyWith(color: text),
                      ),
                      const SizedBox(height: 12),
                      _Tile(surface: surface, child: _Field(
                        hint: 'City', controller: _collegeCityCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Languages ───────────────────────────────────────────
                  _SectionLabel('LANGUAGES', sub),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _allLanguages.map((lang) {
                        final selected = _languages.contains(lang);
                        return FilterChip(
                          label: Text(lang,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: selected ? AppColors.teal : sub)),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) _languages.add(lang);
                            else _languages.remove(lang);
                          }),
                          selectedColor: AppColors.teal.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.teal,
                          backgroundColor: surface,
                          side: BorderSide(
                            color: selected
                                ? AppColors.teal.withValues(alpha: 0.5)
                                : isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Contact ─────────────────────────────────────────────
                  _SectionLabel('CONTACT', sub),
                  _Tile(surface: surface, child: _Field(
                    hint: 'Phone number',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  )),
                  const SizedBox(height: 24),

                  // ── Profile handle ──────────────────────────────────────
                  _SectionLabel('PROFILE HANDLE', sub),
                  _Tile(surface: surface, child: _Field(
                    hint: 'your-handle',
                    controller: _handleCtrl,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Text('@', style: AppTextStyles.body.copyWith(color: sub)),
                    ),
                    textInputAction: TextInputAction.done,
                  )),
                  if (_handleError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text(_handleError!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Text(
                      'medgraph.in/dr/${_handleCtrl.text.isNotEmpty ? _handleCtrl.text : 'your-handle'}',
                      style: AppTextStyles.caption.copyWith(color: sub),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.user, required this.pickedBytes,
    required this.uploading, required this.onTap,
  });
  final UserModel user;
  final Uint8List? pickedBytes;
  final bool uploading;
  final VoidCallback onTap;

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
              child: ClipOval(child: _avatarChild()),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBackground : Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, size: 14,
                    color: isDark ? Colors.black : Colors.white),
              ),
            ),
            if (uploading)
              Positioned.fill(child: ClipOval(
                child: Container(color: Colors.black54,
                  child: const Center(child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
              )),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Change photo', style: AppTextStyles.footnote.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSecondary : AppColors.lightSecondary)),
      ]),
    );
  }

  Widget _avatarChild() {
    if (pickedBytes != null) return Image.memory(pickedBytes!, fit: BoxFit.cover);
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return Image.network(user.avatarUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsWidget());
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() => Container(color: AppColors.teal,
    child: Center(child: Text(_initials, style: const TextStyle(
        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600))));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, color: color, letterSpacing: 0.6)),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.surface, required this.child});
  final Color surface;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14)),
      child: child,
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.hint, required this.controller,
    this.keyboardType, this.maxLines = 1, this.maxLength,
    this.prefix, this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final Widget? prefix;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines, maxLength: maxLength,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: AppTextStyles.body.copyWith(
          color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(
            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary),
        border: InputBorder.none, enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '', prefixIcon: prefix, filled: false,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.isDark);
  final bool isDark;

  @override
  Widget build(BuildContext context) => Divider(
    height: 0.5, thickness: 0.5, indent: 16, endIndent: 0,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );
}
