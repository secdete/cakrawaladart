import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum AccountMenuAction { profile, classes, dashboard, home, logout }

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({
    super.key,
    required this.onProfile,
    required this.onClasses,
    required this.onLogout,
    this.onDashboard,
    this.onHome,
    this.label,
  });

  final VoidCallback onProfile;
  final VoidCallback onClasses;
  final VoidCallback onLogout;
  final VoidCallback? onDashboard;
  final VoidCallback? onHome;
  final String? label;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AccountMenuAction>(
    tooltip: 'Profil dan menu akun',
    icon: label == null ? const Icon(Icons.account_circle_outlined) : null,
    onSelected: (action) {
      switch (action) {
        case AccountMenuAction.profile:
          onProfile();
          break;
        case AccountMenuAction.classes:
          onClasses();
          break;
        case AccountMenuAction.dashboard:
          onDashboard?.call();
          break;
        case AccountMenuAction.home:
          onHome?.call();
          break;
        case AccountMenuAction.logout:
          onLogout();
          break;
      }
    },
    itemBuilder: (context) => [
      _item(AccountMenuAction.profile, Icons.person_outline_rounded, 'Profil saya'),
      _item(AccountMenuAction.classes, Icons.menu_book_outlined, 'Kelas saya'),
      if (onDashboard != null) _item(AccountMenuAction.dashboard, Icons.space_dashboard_outlined, 'Dashboard'),
      if (onHome != null) _item(AccountMenuAction.home, Icons.home_outlined, 'Kembali ke beranda'),
      const PopupMenuDivider(),
      _item(AccountMenuAction.logout, Icons.logout_rounded, 'Keluar dari akun', isDestructive: true),
    ],
    child: label == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.primaryBlue), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.account_circle_outlined, size: 17, color: AppColors.primaryBlue),
              const SizedBox(width: 7),
              Text(label!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryBlue)),
            ]),
          ),
  );

  PopupMenuItem<AccountMenuAction> _item(
    AccountMenuAction action,
    IconData icon,
    String title, {
    bool isDestructive = false,
  }) => PopupMenuItem(
    value: action,
    child: Row(children: [
      Icon(icon, size: 19, color: isDestructive ? const Color(0xFFDC2626) : null),
      const SizedBox(width: 11),
      Text(title, style: TextStyle(color: isDestructive ? const Color(0xFFDC2626) : null)),
    ]),
  );
}
