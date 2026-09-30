import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/portal_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';
import '../../landing/screens/bimbel_landing_screen.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _data = PortalApiService.instance.dashboard('tutor');

  Future<void> _writeNote(Map<String, dynamic> session) async {
    final topic = TextEditingController();
    final homework = TextEditingController();
    final parentNote = TextEditingController();
    final form = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan sesi siswa'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: topic,
                  decoration: const InputDecoration(
                    labelText: 'Materi yang dibahas',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Wajib diisi'
                      : null,
                ),
                TextField(
                  controller: homework,
                  decoration: const InputDecoration(
                    labelText: 'Pekerjaan rumah',
                  ),
                ),
                TextField(
                  controller: parentNote,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan untuk orang tua',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      await PortalApiService.instance.saveTutorNote({
        'studentId': session['studentId'],
        'sessionId': session['id'],
        'subject': session['subject'],
        'topicCovered': topic.text.trim(),
        'homework': homework.text.trim(),
        'parentNote': parentNote.text.trim(),
        'comprehension': 'Baik',
      });
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan tersimpan dan bisa dilihat orang tua.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      topic.dispose();
      homework.dispose();
      parentNote.dispose();
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await PortalApiService.instance.updateSession(id, status);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _replyToQuestion(Map<String, dynamic> question) async {
    final controller = TextEditingController();
    final reply = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Balas ${question['studentName']}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Tulis pembahasan atau arahan belajar',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kirim balasan'),
          ),
        ],
      ),
    );
    if (reply == null || reply.trim().length < 2) {
      controller.dispose();
      return;
    }
    try {
      await PortalApiService.instance.replyToQuestion(
        question['id'] as String,
        reply,
      );
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgCanvas,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const BimbelLogo(size: 34),
      actions: [
        IconButton(
          tooltip: 'Keluar',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            await PortalApiService.instance.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BimbelLandingScreen()),
                (_) => false,
              );
            }
          },
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Data tutor gagal dimuat: ${snapshot.error}'),
          );
        }
        final data = snapshot.data!;
        final profile = Map<String, dynamic>.from(data['profile'] as Map);
        final sessions = List<Map<String, dynamic>>.from(
          (data['sessions'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final notes = List<Map<String, dynamic>>.from(
          (data['notes'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final questions = List<Map<String, dynamic>>.from(
          (data['questions'] as List? ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final summary = Map<String, dynamic>.from(data['summary'] as Map);
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF101A3A), Color(0xFF25458E)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard Tutor',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile['name'] ?? 'Tutor Cakrawala',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile['specialization'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _stat(
                            'Sesi terjadwal',
                            '${summary['totalSessions'] ?? 0}',
                            Icons.calendar_month,
                          ),
                          _stat(
                            'Sesi mendatang',
                            '${summary['upcomingSessions'] ?? 0}',
                            Icons.upcoming,
                          ),
                          _stat(
                            'Siswa dampingan',
                            '${summary['totalStudents'] ?? 0}',
                            Icons.school,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Jadwal dan siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (sessions.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Belum ada sesi yang ditugaskan.'),
                          ),
                        ),
                      ...sessions.map(
                        (session) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${session['studentName']} · ${session['subject']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${session['title']} · ${session['dateTimeFormatted']} · ${session['timeRange']}',
                                ),
                                Text('Status: ${session['status']}'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _writeNote(session),
                                      icon: const Icon(Icons.note_add_outlined),
                                      label: const Text('Buat catatan'),
                                    ),
                                    if (session['status'] == 'Mendatang')
                                      FilledButton.tonal(
                                        onPressed: () => _setStatus(
                                          session['id'] as String,
                                          'Selesai',
                                        ),
                                        child: const Text('Tandai selesai'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Pertanyaan siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (questions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Belum ada pertanyaan dari siswa.'),
                        ),
                      ...questions.map(
                        (question) => Card(
                          child: ListTile(
                            title: Text(
                              '${question['studentName']} · ${question['status']}',
                            ),
                            subtitle: Text(question['question'] as String),
                            trailing: question['status'] == 'Dijawab'
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : IconButton(
                                    tooltip: 'Balas',
                                    icon: const Icon(Icons.reply),
                                    onPressed: () => _replyToQuestion(question),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Catatan pembelajaran terbaru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ...notes.map(
                        (note) => ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.menu_book),
                          ),
                          title: Text(
                            '${note['studentName']} · ${note['topicCovered']}',
                          ),
                          subtitle: Text(
                            '${note['dateFormatted']} · PR: ${note['homeworkAssigned']}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _stat(String title, String value, IconData icon) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
