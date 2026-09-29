import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/screens/siakad_dashboard_screen.dart';
import '../widgets/auth_card.dart';
import '../widgets/campus_bulletin_panel.dart';
import '../widgets/campus_footer.dart';
import '../widgets/campus_header.dart';

class SiakadLoginScreen extends StatelessWidget {
  const SiakadLoginScreen({super.key});

  void _onLoginSuccess(BuildContext context, Map<String, String> userData) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SiakadDashboardScreen(userData: userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Campus Top Bar
            const CampusHeader(),

            // Main Content Area (Scrollable with integrated Campus Footer)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1220),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 36 : 18,
                          vertical: isDesktop ? 36 : 20,
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Academic Announcements & Bulletin
                                  const Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 32),
                                      child: CampusBulletinPanel(),
                                    ),
                                  ),
                                  // Right: SIAKAD Authentication Card
                                  Expanded(
                                    flex: 5,
                                    child: AuthCard(
                                      onLoginSuccess: (userData) =>
                                          _onLoginSuccess(context, userData),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // On Mobile: Authentication card is placed first for great UX
                                  AuthCard(
                                    onLoginSuccess: (userData) =>
                                        _onLoginSuccess(context, userData),
                                  ),
                                  const SizedBox(height: 36),
                                  // Followed by Campus Bulletin
                                  const CampusBulletinPanel(),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Official Campus Footer
                    const CampusFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
