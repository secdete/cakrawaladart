import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/portal_api_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _tutors = [];
  String get _role => PortalApiService.instance.user?['role']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final classes = await PortalApiService.instance.fetchClasses();
      List<Map<String, dynamic>> tutors = _tutors;
      if (_role == 'admin') {
        final dashboard = await PortalApiService.instance.dashboard('admin');
        tutors = List<Map<String, dynamic>>.from(
          (dashboard['users'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((user) => user['role'] == 'tutor' && user['active'] != false),
        );
      }
      if (mounted) setState(() { _classes = classes; _tutors = tutors; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass() async {
    if (_tutors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buat akun tutor terlebih dahulu dari dashboard admin.')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final subject = TextEditingController();
    final description = TextEditingController();
    final duration = TextEditingController(text: '60');
    final meetingUrl = TextEditingController();
    var tutorId = '${_tutors.first['id']}';
    var scheduledAt = DateTime.now().add(const Duration(days: 1));

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat kelas belajar'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Nama kelas'), validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Nama kelas minimal 3 karakter.' : null),
                  TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'Mata pelajaran'), validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Mata pelajaran wajib diisi.' : null),
                  TextFormField(controller: description, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tutorId,
                    decoration: const InputDecoration(labelText: 'Tutor pengajar'),
                    items: _tutors.map((tutor) => DropdownMenuItem(value: '${tutor['id']}', child: Text('${tutor['name'] ?? tutor['email']}'))).toList(),
                    onChanged: (value) => setDialogState(() => tutorId = value ?? tutorId),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Jadwal kelas'),
                    subtitle: Text(MaterialLocalizations.of(context).formatFullDate(scheduledAt) + ' · ' + scheduledAt.toLocal().toString().substring(11, 16)),
                    onTap: () async {
                      final date = await showDatePicker(context: dialogContext, initialDate: scheduledAt, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 730)));
                      if (date == null || !dialogContext.mounted) return;
                      final time = await showTimePicker(context: dialogContext, initialTime: TimeOfDay.fromDateTime(scheduledAt));
                      if (time == null) return;
                      setDialogState(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    },
                  ),
                  TextFormField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durasi (menit)'), validator: (v) { final value = int.tryParse(v ?? ''); return value == null || value < 15 || value > 300 ? 'Durasi 15–300 menit.' : null; }),
                  TextFormField(controller: meetingUrl, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Link kelas (opsional)')),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, {
                  'title': title.text.trim(), 'subject': subject.text.trim(),
                  'description': description.text.trim(), 'tutorId': tutorId,
                  'scheduledAt': scheduledAt.toIso8601String(),
                  'durationMinutes': int.parse(duration.text), 'meetingUrl': meetingUrl.text.trim(),
                });
              },
              icon: const Icon(Icons.add_rounded), label: const Text('Simpan kelas'),
            ),
          ],
        ),
      ),
    );
    title.dispose(); subject.dispose(); description.dispose(); duration.dispose(); meetingUrl.dispose();
    if (data == null || !mounted) return;
    try {
      await PortalApiService.instance.createClass(data);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelas berhasil dibuat dan tersedia untuk siswa.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _enroll(Map<String, dynamic> item) async {
    try {
      await PortalApiService.instance.enrollInClass('${item['id']}');
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamu sudah bergabung di kelas ini.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == 'admin';
    final isStudent = _role == 'student';
    final title = isAdmin ? 'Kelola kelas' : isStudent ? 'Kelas belajar' : 'Kelas saya';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), actions: [IconButton(tooltip: 'Muat ulang', onPressed: _load, icon: const Icon(Icons.refresh_rounded)), const SizedBox(width: 8)]),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(onPressed: _createClass, icon: const Icon(Icons.add_rounded), label: const Text('Buat kelas')) : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 920), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF132044), Color(0xFF2856A8)]), borderRadius: BorderRadius.circular(21)),
              child: Row(children: [
                const CircleAvatar(backgroundColor: Color(0x263B82F6), child: Icon(Icons.menu_book_rounded, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 5),
                  Text(isAdmin ? 'Atur kelas dan tutor pengajar.' : isStudent ? 'Temukan kelas, lihat jadwal, dan bergabung untuk belajar.' : 'Jadwal kelas yang ditugaskan kepadamu.', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14)),
                ])),
              ]),
            ),
            const SizedBox(height: 18),
            if (_error != null) Card(child: ListTile(leading: const Icon(Icons.error_outline_rounded, color: Colors.red), title: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Coba lagi')))),
            if (_loading && _classes.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(36), child: CircularProgressIndicator())),
            if (!_loading && _error == null && _classes.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(26), child: Center(child: Text(isStudent ? 'Belum ada kelas tersedia.' : 'Belum ada kelas yang ditugaskan.')))),
            ..._classes.map((item) => _classCard(item, isStudent)),
            const SizedBox(height: 70),
          ]))),
        ]),
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> item, bool isStudent) {
    final enrolled = item['enrolled'] == true;
    final meetingUrl = '${item['meetingUrl'] ?? ''}';
    return Card(
      color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFE5EAF2))),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item['title'] ?? 'Kelas belajar'}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF18243B))),
            const SizedBox(height: 3),
            Text('${item['subject'] ?? ''} · Tutor ${item['tutorName'] ?? '-'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ])),
          if (enrolled) const Chip(label: Text('Diikuti'), visualDensity: VisualDensity.compact),
        ]),
        if ('${item['description'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('${item['description']}', style: const TextStyle(color: Color(0xFF475569))),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: [
          _detail(Icons.event_outlined, '${item['dateTimeFormatted'] ?? '-'}'),
          _detail(Icons.timelapse_rounded, '${item['durationMinutes'] ?? 60} menit'),
        ]),
        if (isStudent || meetingUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (isStudent && !enrolled) FilledButton.icon(onPressed: () => _enroll(item), icon: const Icon(Icons.add_rounded), label: const Text('Gabung kelas')),
            if (meetingUrl.isNotEmpty && (!isStudent || enrolled)) OutlinedButton.icon(onPressed: () async { final uri = Uri.tryParse(meetingUrl); if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.video_call_outlined), label: const Text('Buka kelas')),
          ]),
        ],
      ])),
    );
  }

  Widget _detail(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: const Color(0xFF64748B)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))]);
}
