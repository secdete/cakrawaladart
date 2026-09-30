import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/portal_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';
import '../../landing/screens/bimbel_landing_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  int _section = 0;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await PortalApiService.instance.dashboard('admin');
      if (mounted) setState(() => _data = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await PortalApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BimbelLandingScreen()), (_) => false,
    );
  }

  Future<void> _showCreateUser() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    var role = 'student';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat akun baru'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama lengkap'), validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Nama minimal 2 karakter.' : null),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()) ? 'Masukkan email yang valid.' : null),
                TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi (minimal 8 karakter)'), validator: (v) => (v?.length ?? 0) < 8 ? 'Kata sandi minimal 8 karakter.' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Peran akun'),
                  items: const [DropdownMenuItem(value: 'student', child: Text('Siswa')), DropdownMenuItem(value: 'parent', child: Text('Orang tua')), DropdownMenuItem(value: 'tutor', child: Text('Tutor')), DropdownMenuItem(value: 'admin', child: Text('Admin'))],
                  onChanged: (value) => setDialogState(() => role = value ?? 'student'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton.icon(onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, {'name': name.text.trim(), 'email': email.text.trim(), 'password': password.text, 'role': role});
            }, icon: const Icon(Icons.person_add_alt_1), label: const Text('Buat akun')),
          ],
        ),
      ),
    );
    name.dispose(); email.dispose(); password.dispose();
    if (result == null || !mounted) return;
    try {
      await PortalApiService.instance.createUser(name: result['name']!, email: result['email']!, password: result['password']!, role: result['role']!);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = PortalApiService.instance.user;
    final leads = List<Map<String, dynamic>>.from((_data['leads'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
    final users = List<Map<String, dynamic>>.from((_data['users'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
    final summary = Map<String, dynamic>.from(_data['summary'] as Map? ?? const {});
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.white,
        title: const BimbelLogo(size: 36),
        actions: [
          IconButton(tooltip: 'Muat ulang', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
          IconButton(tooltip: 'Keluar', onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 36), children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1160), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF132044), Color(0xFF2856A8)]), borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 27)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PUSAT KONTROL', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
                  const SizedBox(height: 4),
                  Text('Halo, ${admin?['name'] ?? 'Admin'}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('Kelola akun dan pantau permintaan konsultasi Cakrawala.', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13)),
                ])),
                if (MediaQuery.sizeOf(context).width > 650) FilledButton.icon(onPressed: _showCreateUser, icon: const Icon(Icons.person_add_alt_1), label: const Text('Tambah akun')),
              ]),
            ),
            const SizedBox(height: 18),
            if (_error != null) _errorPanel(),
            if (_loading && _data.isEmpty) const LinearProgressIndicator(),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _statCard('Total akun aktif', '${summary['totalUsers'] ?? 0}', Icons.groups_2_rounded, const Color(0xFF2563EB)),
              _statCard('Siswa', '${summary['students'] ?? 0}', Icons.school_rounded, const Color(0xFF0891B2)),
              _statCard('Tutor', '${summary['tutors'] ?? 0}', Icons.co_present_rounded, const Color(0xFF7C3AED)),
              _statCard('Leads baru', '${summary['newLeads'] ?? 0}', Icons.mark_email_unread_rounded, const Color(0xFFEA580C)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Text('Operasional', style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800, color: const Color(0xFF18243B)))),
              if (MediaQuery.sizeOf(context).width <= 650) IconButton.filledTonal(onPressed: _showCreateUser, tooltip: 'Tambah akun', icon: const Icon(Icons.person_add_alt_1)),
            ]),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 0, icon: Icon(Icons.inbox_outlined), label: Text('Permintaan')), ButtonSegment(value: 1, icon: Icon(Icons.manage_accounts_outlined), label: Text('Akun pengguna'))],
              selected: {_section}, onSelectionChanged: (value) => setState(() => _section = value.first),
            ),
            const SizedBox(height: 14),
            if (_loading && _data.isNotEmpty) const LinearProgressIndicator(),
            if (!_loading && _error == null && _section == 0) _buildLeads(leads),
            if (!_loading && _error == null && _section == 1) _buildUsers(users),
          ]))),
        ]),
      ),
    );
  }

  Widget _errorPanel() => Card(child: ListTile(leading: const Icon(Icons.wifi_off_rounded, color: Colors.red), title: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Coba lagi'))));

  Widget _statCard(String title, String value, IconData icon, Color color) => SizedBox(
    width: 265,
    child: Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE7ECF4))), child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
      const SizedBox(width: 13),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF18243B))), Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))) ]),
    ]))),
  );

  Widget _buildLeads(List<Map<String, dynamic>> leads) {
    if (leads.isEmpty) return _emptyState(Icons.inbox_outlined, 'Belum ada permintaan', 'Permintaan konsultasi dari calon siswa akan muncul di sini.');
    return Column(children: leads.map((lead) => Card(
      margin: const EdgeInsets.only(bottom: 10), color: Colors.white, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE7ECF4))),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(backgroundColor: Color(0xFFEAF2FF), child: Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${lead['name'] ?? 'Tanpa nama'}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('${lead['phone'] ?? '-'}${(lead['email'] ?? '').toString().isEmpty ? '' : ' · ${lead['email']}'}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text('${lead['grade'] ?? '-'}  ·  ${lead['source'] ?? 'Website'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ])),
        _statusBadge('${lead['status'] ?? 'new'}'),
      ])),
    )).toList());
  }

  Widget _buildUsers(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return _emptyState(Icons.group_outlined, 'Belum ada akun', 'Buat akun pertama untuk mulai mengelola pengguna.');
    return Column(children: users.map((user) {
      final role = '${user['role'] ?? ''}';
      final labels = {'student': 'Siswa', 'parent': 'Orang tua', 'tutor': 'Tutor', 'admin': 'Admin'};
      return Card(
        margin: const EdgeInsets.only(bottom: 9), color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE7ECF4))),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFFEAF2FF), child: Icon(role == 'tutor' ? Icons.co_present_rounded : role == 'admin' ? Icons.shield_outlined : Icons.person_outline_rounded, color: const Color(0xFF2563EB))),
          title: Text('${user['name'] ?? 'Pengguna'}', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${user['email'] ?? ''}'),
          trailing: _statusBadge(labels[role] ?? role),
        ),
      );
    }).toList());
  }

  Widget _statusBadge(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(30)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))));

  Widget _emptyState(IconData icon, String title, String description) => Card(color: Colors.white, elevation: 0, child: Padding(padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20), child: Column(children: [Icon(icon, size: 36, color: const Color(0xFF94A3B8)), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B)))])));
}
