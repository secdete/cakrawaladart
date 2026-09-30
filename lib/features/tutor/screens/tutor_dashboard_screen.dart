import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/portal_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';
import '../../landing/screens/bimbel_landing_screen.dart';
import '../../classes/screens/classes_screen.dart';
import '../../profile/screens/account_profile_screen.dart';
import '../../profile/widgets/account_menu_button.dart';

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

  Future<void> _openClasses() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen()));
    if (mounted) setState(_load);
  }

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
          tooltip: 'Muat ulang data',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => setState(_load),
        ),
        AccountMenuButton(
          onProfile: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountProfileScreen())),
          onClasses: () { _openClasses(); },
          onHome: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BimbelLandingScreen()), (_) => false),
          onLogout: () async {
            await PortalApiService.instance.logout();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BimbelLandingScreen()), (_) => false);
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded, size: 38, color: Color(0xFF64748B)),
                    const SizedBox(height: 12),
                    Text('Data tutor belum dapat dimuat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: () => setState(_load), icon: const Icon(Icons.refresh_rounded), label: const Text('Coba lagi')),
                  ]),
                ),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final profile = Map<String, dynamic>.from(data['profile'] as Map);
        final sessions = List<Map<String, dynamic>>.from(
          (data['sessions'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final classes = List<Map<String, dynamic>>.from(
          (data['classes'] as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)),
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
                            Row(children: [
                              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF93C5FD), size: 17),
                              const SizedBox(width: 7),
                              Text('RUANG KERJA TUTOR', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                            ]),
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
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
                              child: Text('${summary['upcomingSessions'] ?? 0} sesi mendatang', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                        'Kelas yang diajar',
                        style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (classes.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Belum ada kelas yang ditugaskan.'))),
                      ...classes.take(3).map((item) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE5EAF2))),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB))),
                          title: Text('${item['title'] ?? 'Kelas'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${item['subject'] ?? '-'} · ${item['dateTimeFormatted'] ?? '-'}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () { _openClasses(); },
                        ),
                      )),
                      if (classes.length > 3)
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () { _openClasses(); }, child: Text('Lihat semua ${classes.length} kelas'))),
                      const SizedBox(height: 20),
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                            side: const BorderSide(color: Color(0xFFE5EAF2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                                    if (session['status'] == 'Mendatang')
                                      OutlinedButton.icon(
                                        onPressed: () => _setStatus(
                                          session['id'] as String,
                                          'Dibatalkan',
                                        ),
                                        icon: const Icon(Icons.event_busy_rounded),
                                        label: const Text('Batalkan sesi'),
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
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Color(0xFFE5EAF2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: Icon(
                                question['status'] == 'Dijawab' ? Icons.check_rounded : Icons.question_answer_outlined,
                                color: question['status'] == 'Dijawab' ? Colors.green : AppColors.primaryBlue,
                              ),
                            ),
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
                      if (notes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Catatan sesi yang dibuat tutor akan tampil di sini.', style: TextStyle(color: Color(0xFF64748B))),
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
