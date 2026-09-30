import 'package:flutter/material.dart';

import '../../../core/services/portal_api_service.dart';
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
  List<Map<String, dynamic>> _leads = [];

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PortalApiService.instance.dashboard('admin');
      if (!mounted) return;
      setState(() => _leads = (data['leads'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList());
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
      MaterialPageRoute(builder: (_) => const BimbelLandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = PortalApiService.instance.user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const BimbelLogo(size: 38),
        actions: [
          IconButton(tooltip: 'Muat ulang', onPressed: _loadLeads, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Keluar', onPressed: _logout, icon: const Icon(Icons.logout)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeads,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Dashboard Admin', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Selamat datang, ${admin?['name'] ?? 'Admin'}'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const CircleAvatar(child: Icon(Icons.inbox_outlined)),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Permintaan konsultasi masuk')),
                  Text('${_leads.length}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('Daftar Leads', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (!_loading && _error != null)
              Card(child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: Text(_error!), trailing: TextButton(onPressed: _loadLeads, child: const Text('Coba lagi')))),
            if (!_loading && _error == null && _leads.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada permintaan konsultasi.')))),
            if (!_loading && _error == null)
              ..._leads.map((lead) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text('${lead['name'] ?? 'Tanpa nama'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    '${lead['phone'] ?? '-'}',
                    if ((lead['email'] ?? '').toString().isNotEmpty) '${lead['email']}',
                    '${lead['grade'] ?? '-'} • ${lead['source'] ?? '-'}',
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: Text('${lead['status'] ?? 'new'}'),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
