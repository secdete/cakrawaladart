import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/portal_api_service.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = PortalApiService.instance.fetchProfile();
  }

  Future<void> _reload() async {
    setState(() => _profile = PortalApiService.instance.fetchProfile());
    await _profile;
  }

  Future<void> _edit(Map<String, dynamic> profile) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: '${profile['name'] ?? ''}');
    final phone = TextEditingController(text: '${profile['phone'] ?? ''}');
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah profil'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Nama minimal 2 karakter.'
                    : null,
              ),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor telepon (opsional)'),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if ((value ?? '').trim().isNotEmpty && (digits.length < 8 || digits.length > 15)) {
                    return 'Nomor harus berisi 8–15 digit.';
                  }
                  return null;
                },
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, {'name': name.text.trim(), 'phone': phone.text.trim()});
            },
            child: const Text('Simpan perubahan'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
    if (values == null || !mounted) return;
    try {
      final updated = await PortalApiService.instance.updateProfile(
        name: values['name']!,
        phone: values['phone']!,
      );
      if (!mounted) return;
      setState(() => _profile = Future.value(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text('Profil saya', style: TextStyle(fontWeight: FontWeight.w700)),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF64748B)),
                const SizedBox(height: 12),
                const Text('Profil belum dapat dimuat.', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba lagi')),
              ]),
            ),
          );
        }
        final profile = snapshot.data!;
        final role = '${profile['role'] ?? ''}';
        final displayName = '${profile['name'] ?? ''}'.trim();
        final initial = displayName.isEmpty ? 'U' : displayName.substring(0, 1).toUpperCase();
        final roleNames = {'student': 'Siswa', 'parent': 'Orang tua', 'tutor': 'Tutor', 'admin': 'Admin'};
        final details = <String, String>{
          'grade': 'Jenjang', 'school': 'Sekolah', 'targetPtn': 'Target kampus',
          'activePackage': 'Paket belajar', 'childName': 'Nama anak',
          'childGrade': 'Jenjang anak', 'subscriptionStatus': 'Status paket',
          'specialization': 'Spesialisasi', 'rating': 'Rating tutor',
        };
        final extra = details.entries
            .where((entry) => profile[entry.key]?.toString().trim().isNotEmpty == true)
            .toList();
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF132044), Color(0xFF2856A8)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 31,
                          backgroundColor: Colors.white.withValues(alpha: .15),
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${profile['name'] ?? 'Pengguna'}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(roleNames[role] ?? 'Pengguna Cakrawala', style: const TextStyle(color: Colors.white70)),
                        ])),
                        IconButton.filledTonal(
                          tooltip: 'Ubah profil',
                          onPressed: () => _edit(profile),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _infoCard('Informasi akun', [
                      _infoRow(Icons.email_outlined, 'Email', '${profile['email'] ?? '-'}'),
                      _infoRow(Icons.phone_outlined, 'Nomor telepon', '${profile['phone'] ?? 'Belum diisi'}'),
                      _infoRow(Icons.verified_user_outlined, 'Peran', roleNames[role] ?? role),
                    ]),
                    if (extra.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _infoCard('Informasi pembelajaran', extra.map((entry) => _infoRow(Icons.school_outlined, entry.value, '${profile[entry.key]}')).toList()),
                    ],
                    const SizedBox(height: 14),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                          SizedBox(width: 12),
                          Expanded(child: Text('Gunakan tombol kembali untuk kembali ke dashboard. Sesi akun tetap aktif sampai kamu memilih Keluar di dashboard.')),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _infoCard(String title, List<Widget> rows) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFE5EAF2))),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        ...rows,
      ]),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 19, color: const Color(0xFF64748B)),
      const SizedBox(width: 12),
      SizedBox(width: 145, child: Text(label, style: const TextStyle(color: Color(0xFF64748B)))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
}
