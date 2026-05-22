import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Represents a single created session.
class _Session {
  final String title;
  final String description;
  final String platform; // 'Discord' | 'Teams' | 'Meet'
  final String link;
  final DateTime dateTime;

  _Session({
    required this.title,
    required this.description,
    required this.platform,
    required this.link,
    required this.dateTime,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedPlatform = 'Discord';
  DateTime? _selectedDateTime;

  final List<_Session> _sessions = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ── Platform helpers ──

  static const _platforms = ['Discord', 'Teams', 'Meet'];

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'Discord':
        return Icons.headset_mic_rounded;
      case 'Teams':
        return Icons.groups_rounded;
      case 'Meet':
        return Icons.video_camera_front_rounded;
      default:
        return Icons.public;
    }
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'Discord':
        return const Color(0xFF5865F2);
      case 'Teams':
        return const Color(0xFF6264A7);
      case 'Meet':
        return const Color(0xFF00897B);
      default:
        return Colors.grey;
    }
  }

  String _platformHint(String platform) {
    switch (platform) {
      case 'Discord':
        return 'https://discord.gg/...';
      case 'Teams':
        return 'https://teams.microsoft.com/l/meetup-join/...';
      case 'Meet':
        return 'https://meet.google.com/...';
      default:
        return 'https://...';
    }
  }

  // ── Date picker ──

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }

  // ── URL launcher ──

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible d\'ouvrir le lien'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  // ── Submit ──

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez choisir une date et une heure'),
          backgroundColor: context.appColors.error,
        ),
      );
      return;
    }

    setState(() {
      _sessions.insert(
        0,
        _Session(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          platform: _selectedPlatform,
          link: _linkController.text.trim(),
          dateTime: _selectedDateTime!,
        ),
      );
      _titleController.clear();
      _descriptionController.clear();
      _linkController.clear();
      _selectedPlatform = 'Discord';
      _selectedDateTime = null;
      _formKey.currentState!.reset();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session créée avec succès!'),
        backgroundColor: context.appColors.primary,
      ),
    );
  }

  // ── Input decoration factory ──

  InputDecoration _inputDecoration(String label, AppPalette c,
      {String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: c.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
      labelStyle: TextStyle(color: c.onSurfaceVariant, fontSize: 13),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.surface,
      appBar: AppBar(
        backgroundColor: appColors.surfaceContainerLow.withOpacity(0.7),
        elevation: 0,
        title: Text(
          'Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: appColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ──
            Text(
              'Créer une session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Planifiez une réunion sur Discord, Teams ou Meet.',
              style: TextStyle(
                fontSize: 13,
                color: appColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // ── Form card ──
            Container(
              decoration: AppTheme.cardDecoration(appColors),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: appColors.onSurface, fontSize: 14),
                      decoration: _inputDecoration('Titre de la session', appColors),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: appColors.onSurface, fontSize: 14),
                      maxLines: 3,
                      decoration: _inputDecoration(
                          'Description / Sujet à discuter', appColors),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Platform selector
                    Text(
                      'Plateforme',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: appColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _platforms.map((p) {
                        final isActive = _selectedPlatform == p;
                        final color = _platformColor(p);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPlatform = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                  right: p != _platforms.last ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? color.withOpacity(0.15)
                                    : appColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? color
                                      : appColors.outlineVariant,
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _platformIcon(p),
                                    color: isActive
                                        ? color
                                        : appColors.onSurfaceVariant,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isActive
                                          ? color
                                          : appColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Session link
                    TextFormField(
                      controller: _linkController,
                      style: TextStyle(color: appColors.onSurface, fontSize: 14),
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration(
                        'Lien de la session',
                        appColors,
                        hint: _platformHint(_selectedPlatform),
                        prefixIcon: Icon(Icons.link_rounded,
                            color: appColors.primary, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Veuillez entrer le lien';
                        }
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) {
                          return 'Lien invalide (commencez par https://)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date / time picker
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: appColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: appColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDateTime != null
                                    ? _formatDateTime(_selectedDateTime!)
                                    : 'Choisir la date et l\'heure',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedDateTime != null
                                      ? appColors.onSurface
                                      : appColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Créer la session',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: appColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sessions list ──
            if (_sessions.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Sessions planifiées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ..._sessions.map((s) => _buildSessionCard(s, appColors)),
            ],

            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(_Session session, AppPalette appColors) {
    final color = _platformColor(session.platform);
    return GestureDetector(
      onTap: () => _openLink(session.link),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: appColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appColors.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_platformIcon(session.platform),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: appColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Date row + platform badge
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: appColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(session.dateTime),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: appColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      session.platform,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Join button
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _openLink(session.link),
                  icon: Icon(_platformIcon(session.platform), size: 16),
                  label: Text(
                    'Rejoindre sur ${session.platform}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
