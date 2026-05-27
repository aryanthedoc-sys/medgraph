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

/// Editable fields differ by role.
/// Doctors see: specialty, hospital.
/// Students see: college, academic year.
/// Both see: full name, bio, city, state, phone, handle.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _collegeCtrl;
  late final TextEditingController _hospitalCtrl;

  // ── State ─────────────────────────────────────────────────────────────────────
  String? _selectedSpecialty;
  int? _selectedYear;
  bool _loading = false;
  String? _handleError;

  // ── Avatar pick ───────────────────────────────────────────────────────────────
  Uint8List? _pickedBytes;
  String     _pickedMime   = 'image/jpeg';
  bool       _uploadingAvatar = false;

  static const _specialties = [
    'General Medicine', 'Internal Medicine', 'Surgery',
    'Paediatrics', 'Obstetrics & Gynaecology', 'Cardiology',
    'Dermatology', 'Orthopaedics', 'Neurology', 'Psychiatry',
    'Radiology', 'Anaesthesia', 'Pathology', 'Ophthalmology',
    'ENT', 'Urology', 'Nephrology', 'Gastroenterology',
    'Pulmonology', 'Endocrinology',
  ];

  static const _years = [1, 2, 3, 4, 5];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider)!;
    _nameCtrl     = TextEditingController(text: u.fullName);
    _bioCtrl      = TextEditingController(text: u.bio ?? '');
    _cityCtrl     = TextEditingController(text: u.city ?? '');
    _stateCtrl    = TextEditingController(text: u.state ?? '');
    _phoneCtrl    = TextEditingController(text: u.phone ?? '');
    _handleCtrl   = TextEditingController(text: u.handle ?? '');
    _collegeCtrl  = TextEditingController(text: u.college ?? '');
    _hospitalCtrl = TextEditingController(text: u.hospital ?? '');
    _selectedSpecialty = u.specialty;
    _selectedYear      = u.academicYear;
    _bioCtrl.addListener(() => setState(() {}));
    _handleCtrl.addListener(_validateHandle);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _phoneCtrl.dispose();
    _handleCtrl.dispose();
    _collegeCtrl.dispose();
    _hospitalCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────────

  void _validateHandle() {
    final v = _handleCtrl.text;
    if (v.isEmpty) {
      setState(() => _handleError = null);
      return;
    }
    final valid = RegExp(r'^[a-z0-9-]{3,40}$').hasMatch(v);
    setState(() => _handleError = valid
        ? null
        : 'Lowercase letters, numbers and hyphens only (3–40 chars)');
  }

  // ── Avatar pick ───────────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes    = await picked.readAsBytes();
    final mimeType = picked.mimeType ?? 'image/jpeg';
    setState(() {
      _pickedBytes = bytes;
      _pickedMime  = mimeType;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Full name cannot be empty.');
      return;
    }
    if (_handleError != null) return;

    setState(() => _loading = true);
    try {
      String? newAvatarUrl;

      // Upload avatar first if the user picked a new one
      if (_pickedBytes != null) {
        setState(() => _uploadingAvatar = true);
        final ext      = _pickedMime.split('/').last;
        final filename = 'avatar.$ext';
        final result   = await ApiService.uploadFile(
          path: '/api/uploads/avatar',
          fieldName: 'file',
          fileBytes: _pickedBytes!,
          filename: filename,
          mimeType: _pickedMime,
        );
        newAvatarUrl = result['avatarUrl'] as String?;
        setState(() => _uploadingAvatar = false);
      }

      // PATCH profile fields
      final user = ref.read(currentUserProvider)!;
      final body = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'bio':       _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'city':      _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'state':     _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'handle':    _handleCtrl.text.trim().isEmpty ? null : _handleCtrl.text.trim(),
        if (user.isStudent) ...{
          'college':       _collegeCtrl.text.trim().isEmpty ? null : _collegeCtrl.text.trim(),
          'academic_year': _selectedYear,
        },
        if (user.isDoctor) ...{
          'specialty': _selectedSpecialty,
          'hospital':  _hospitalCtrl.text.trim().isEmpty ? null : _hospitalCtrl.text.trim(),
        },
      };

      final data   = await ApiService.patch('/api/profiles/me', body);
      final updated = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // If avatar was uploaded separately, merge the URL into the model.
      final finalUser = newAvatarUrl != null
          ? updated.copyWith(avatarUrl: newAvatarUrl)
          : updated;

      ref.read(currentUserProvider.notifier).setUser(finalUser);

      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        setState(() => _handleError = 'Handle is already taken');
      } else {
        _showSnack('Error: ${e.message}');
      }
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() { _loading = false; _uploadingAvatar = false; });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(currentUserProvider)!;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final text    = isDark ? Colors.white : Colors.black;
    final sub     = isDark ? AppColors.darkSecondary  : AppColors.lightSecondary;
    final surface = isDark ? AppColors.darkSurface    : AppColors.lightSurface;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark, text, sub),
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

                  const SizedBox(height: 32),

                  // ── About ───────────────────────────────────────────────
                  _SectionLabel('ABOUT', sub),
                  _Tile(
                    surface: surface,
                    child: Column(
                      children: [
                        _Field(
                          hint: 'Full name',
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        _Divider(isDark),
                        _Field(
                          hint: 'Bio — tell peers who you are',
                          controller: _bioCtrl,
                          maxLines: 4,
                          maxLength: 300,
                          textInputAction: TextInputAction.newline,
                        ),
                      ],
                    ),
                  ),
                  _BioCounter(_bioCtrl.text.length, sub),

                  const SizedBox(height: 24),

                  // ── Location ────────────────────────────────────────────
                  _SectionLabel('LOCATION', sub),
                  _Tile(
                    surface: surface,
                    child: Column(
                      children: [
                        _Field(
                          hint: 'City',
                          controller: _cityCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        _Divider(isDark),
                        _Field(
                          hint: 'State',
                          controller: _stateCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Contact ─────────────────────────────────────────────
                  _SectionLabel('CONTACT', sub),
                  _Tile(
                    surface: surface,
                    child: _Field(
                      hint: 'Phone number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Role-specific ────────────────────────────────────────
                  if (user.isDoctor) ...[
                    _SectionLabel('PROFESSIONAL', sub),
                    _Tile(
                      surface: surface,
                      child: Column(
                        children: [
                          _SpecialtyPicker(
                            value: _selectedSpecialty,
                            specialties: _specialties,
                            text: text,
                            sub: sub,
                            onChanged: (v) =>
                                setState(() => _selectedSpecialty = v),
                          ),
                          _Divider(isDark),
                          _Field(
                            hint: 'Hospital / Institution',
                            controller: _hospitalCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (user.isStudent) ...[
                    _SectionLabel('ACADEMIC', sub),
                    _Tile(
                      surface: surface,
                      child: _Field(
                        hint: 'College / University',
                        controller: _collegeCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _YearPicker(
                      selected: _selectedYear,
                      years: _years,
                      text: text,
                      sub: sub,
                      surface: surface,
                      onSelect: (y) => setState(() => _selectedYear = y),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Handle ──────────────────────────────────────────────
                  _SectionLabel('PROFILE HANDLE', sub),
                  _Tile(
                    surface: surface,
                    child: _Field(
                      hint: 'your-handle',
                      controller: _handleCtrl,
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        child: Text('@',
                            style: AppTextStyles.body.copyWith(color: sub)),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  if (_handleError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text(_handleError!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.danger)),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Text(
                      'medgraph.app/dr/${_handleCtrl.text.isNotEmpty ? _handleCtrl.text : 'your-handle'}',
                      style: AppTextStyles.caption.copyWith(color: sub),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      bool isDark, Color text, Color sub) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      leading: TextButton(
        onPressed: _loading ? null : () => context.pop(),
        child: Text('Cancel',
            style: AppTextStyles.body.copyWith(
                color: _loading ? sub : text)),
      ),
      leadingWidth: 80,
      title: Text('Edit Profile',
          style: AppTextStyles.headline.copyWith(color: text)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text('Save',
                      style: AppTextStyles.body.copyWith(
                          color: text, fontWeight: FontWeight.w600)),
                ),
        ),
      ],
    );
  }
}

// ─── Avatar picker ─────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.user,
    required this.pickedBytes,
    required this.uploading,
    required this.onTap,
  });

  final UserModel user;
  final Uint8List? pickedBytes;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                // Avatar circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: _avatarChild(isDark),
                  ),
                ),

                // Camera badge overlay
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? AppColors.darkBackground : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),

                // Loading overlay while uploading
                if (uploading)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Change photo',
            style: AppTextStyles.footnote.copyWith(
              color: isDark
                  ? AppColors.darkSecondary
                  : AppColors.lightSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarChild(bool isDark) {
    // Freshly-picked image (bytes not yet uploaded)
    if (pickedBytes != null) {
      return Image.memory(
        pickedBytes!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }
    // Existing network image
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return Image.network(
        user.avatarUrl!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        // Initials fallback on error
        errorBuilder: (_, __, ___) => _Initials(name: user.fullName),
      );
    }
    // Initials fallback
    return _Initials(name: user.fullName);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});
  final String name;

  String get _letters {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.darkSurface2,
      child: Center(
        child: Text(
          _letters,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Reusable helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.surface, required this.child});
  final Color surface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.textCapitalization = TextCapitalization.none,
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
    final text   = isDark ? Colors.white : Colors.black;
    final sub    = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: AppTextStyles.body.copyWith(color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: sub),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        counterText: '',
        prefixIcon: prefix,
        filled: false,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.isDark);
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      endIndent: 0,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class _BioCounter extends StatelessWidget {
  const _BioCounter(this.length, this.color);
  final int length;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 20, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$length / 300',
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      ),
    );
  }
}

// ─── Specialty picker ──────────────────────────────────────────────────────────

class _SpecialtyPicker extends StatelessWidget {
  const _SpecialtyPicker({
    required this.value,
    required this.specialties,
    required this.text,
    required this.sub,
    required this.onChanged,
  });

  final String? value;
  final List<String> specialties;
  final Color text;
  final Color sub;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('Specialty',
              style: AppTextStyles.body.copyWith(color: sub)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: sub, size: 20),
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : Colors.white,
          style: AppTextStyles.body.copyWith(color: text),
          items: specialties.map((s) =>
              DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Year picker ───────────────────────────────────────────────────────────────

class _YearPicker extends StatelessWidget {
  const _YearPicker({
    required this.selected,
    required this.years,
    required this.text,
    required this.sub,
    required this.surface,
    required this.onSelect,
  });

  final int? selected;
  final List<int> years;
  final Color text;
  final Color sub;
  final Color surface;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ...years.map((y) {
            final active = selected == y;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(active ? null : y),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: active
                        ? (isDark ? Colors.white : Colors.black)
                        : surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Year $y',
                    style: AppTextStyles.footnote.copyWith(
                      color: active
                          ? (isDark ? Colors.black : Colors.white)
                          : sub,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => onSelect(selected == 6 ? null : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected == 6
                    ? (isDark ? Colors.white : Colors.black)
                    : surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Intern',
                style: AppTextStyles.footnote.copyWith(
                  color: selected == 6
                      ? (isDark ? Colors.black : Colors.white)
                      : sub,
                  fontWeight: selected == 6
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
