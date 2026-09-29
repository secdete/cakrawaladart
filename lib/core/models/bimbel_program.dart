import 'package:flutter/material.dart';

class BimbelProgram {
  final String id;
  final String title;
  final String categoryTag;
  final String gradeLevel;
  final String description;
  final String badgeText;
  final IconData badgeIcon;
  final String priceFormatted;
  final String? originalPriceFormatted;
  final String? discountPercentage;
  final String periodFormatted;
  final String packageSubtitle;
  final String? packageDetail;
  final Color cardBgColor;
  final Color badgeBgColor;
  final double rating;
  final int totalReviews;
  final List<String> features;
  final bool isPopular;
  final String illustrationType;

  const BimbelProgram({
    required this.id,
    required this.title,
    required this.categoryTag,
    required this.gradeLevel,
    required this.description,
    required this.badgeText,
    required this.badgeIcon,
    required this.priceFormatted,
    this.originalPriceFormatted,
    this.discountPercentage,
    this.periodFormatted = '',
    required this.packageSubtitle,
    this.packageDetail,
    required this.cardBgColor,
    this.badgeBgColor = const Color(0xFF2563EB),
    required this.rating,
    required this.totalReviews,
    required this.features,
    this.isPopular = false,
    required this.illustrationType,
  });

  factory BimbelProgram.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic value, Color fallback) {
      if (value is! String) return fallback;
      final hex = value.replaceFirst('#', '');
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed == null) return fallback;
      return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
    }

    IconData parseIcon(dynamic value) => switch (value) {
      'calendar_month_rounded' => Icons.calendar_month_rounded,
      'thumb_up_alt_rounded' => Icons.thumb_up_alt_rounded,
      'card_membership_rounded' => Icons.card_membership_rounded,
      'co_present_rounded' => Icons.co_present_rounded,
      'account_balance_rounded' => Icons.account_balance_rounded,
      _ => Icons.school_rounded,
    };

    return BimbelProgram(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryTag: json['categoryTag'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      description: json['description'] as String? ?? '',
      badgeText: json['badgeText'] as String? ?? '',
      badgeIcon: parseIcon(json['badgeIcon']),
      priceFormatted: json['priceFormatted'] as String? ?? '',
      originalPriceFormatted: json['originalPriceFormatted'] as String?,
      discountPercentage: json['discountPercentage'] as String?,
      periodFormatted: json['periodFormatted'] as String? ?? '',
      packageSubtitle: json['packageSubtitle'] as String? ?? '',
      packageDetail: json['packageDetail'] as String?,
      cardBgColor: parseColor(json['cardBgColor'], const Color(0xFFF8FAFC)),
      badgeBgColor: parseColor(json['badgeBgColor'], const Color(0xFF2563EB)),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      features: (json['features'] as List<dynamic>? ?? const []).cast<String>(),
      isPopular: json['isPopular'] as bool? ?? false,
      illustrationType: json['illustrationType'] as String? ?? 'default',
    );
  }

  static List<BimbelProgram> get dummyPrograms => [
        const BimbelProgram(
          id: 'prog-snbt-1',
          title: 'Video belajar lengkap dan latihan soal Tes Skolastik',
          categoryTag: 'ruangbelajar + UTBK-SNBT',
          gradeLevel: 'SMA - Kelas 12',
          description:
              'Video animasi 3D, bank soal HOTS, dan pembahasan latihan Tes Skolastik lengkap.',
          badgeText: 'SNBT 2026 Terbaru',
          badgeIcon: Icons.calendar_month_rounded,
          priceFormatted: 'Rp 39.542',
          periodFormatted: '/bulan',
          packageSubtitle: 'Paket Tahun Ajaran 2026/2027',
          cardBgColor: Color(0xFFE0F2FE),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.9,
          totalReviews: 1420,
          isPopular: true,
          illustrationType: 'snbt',
          features: [
            'Ratusan video konsep & latihan soal',
            'Tryout IRT Nasional berkala',
            'Modul rangkuman rumus cepat',
          ],
        ),
        const BimbelProgram(
          id: 'prog-privat-2',
          title: 'Les privat eksklusif bersama pengajar terbaik',
          categoryTag: 'Cakrawala Privat',
          gradeLevel: 'SMA - Kelas 12',
          description:
              '1-on-1 bersama tutor pilihan lulusan PTN favorit. Jadwal dan lokasi fleksibel.',
          badgeText: 'Tutor Profesional',
          badgeIcon: Icons.thumb_up_alt_rounded,
          priceFormatted: 'Rp 175.000',
          originalPriceFormatted: 'Rp 250.000',
          discountPercentage: '30%',
          packageSubtitle: 'Paket 1-70 sesi kursus Privat',
          packageDetail: 'Online',
          cardBgColor: Color(0xFFDCFCE7),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.96,
          totalReviews: 890,
          isPopular: true,
          illustrationType: 'privat',
          features: [
            'Bebas pilih & ganti tutor',
            'Kurikulum disesuaikan kebutuhan siswa',
            'Laporan presensi & grafik perkembangan',
          ],
        ),
        const BimbelProgram(
          id: 'prog-english-3',
          title: 'Kursus bahasa Inggris bersama Native Teacher',
          categoryTag: 'English Academy Online',
          gradeLevel: 'SMA - Kelas 12',
          description:
              'Kurikulum internasional Cambridge untuk tingkatkan kelancaran speaking & TOEFL/IELTS.',
          badgeText: 'Standar Internasional',
          badgeIcon: Icons.card_membership_rounded,
          priceFormatted: 'Rp 2.240.000',
          originalPriceFormatted: 'Rp 2.800.000',
          discountPercentage: '20%',
          periodFormatted: '',
          packageSubtitle: 'Premium Ranger (15-18 Tahun)',
          packageDetail: '3 Bulan',
          cardBgColor: Color(0xFFF3E8FF),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.92,
          totalReviews: 630,
          isPopular: false,
          illustrationType: 'english',
          features: [
            'Live teaching bersama pengajar Asing (Native)',
            'Sertifikat berstandar Cambridge',
            'Interactive speaking lab',
          ],
        ),
        const BimbelProgram(
          id: 'prog-live-4',
          title: 'Live Teaching interaktif + konsultasi PR',
          categoryTag: 'Brain Academy Online',
          gradeLevel: 'SMA - Kelas 12',
          description:
              'Belajar interaktif 2 arah via Zoom dengan Master Tutor dan klinik PR harian.',
          badgeText: 'Live Teaching',
          badgeIcon: Icons.co_present_rounded,
          priceFormatted: 'Rp 476.000',
          originalPriceFormatted: 'Rp 1.783.000',
          discountPercentage: '20%',
          periodFormatted: '/bulan',
          packageSubtitle: 'Paket Tahun Ajaran 2026/2027',
          cardBgColor: Color(0xFFFFEDD5),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.88,
          totalReviews: 1100,
          isPopular: true,
          illustrationType: 'liveteaching',
          features: [
            'Live class interaktif 2 arah',
            'Klinik PR tanya jawab matematika/IPA',
            'Konseling jurusan & Beasiswa',
          ],
        ),
        const BimbelProgram(
          id: 'prog-kedinasan-5',
          title: 'Belajar materi seleksi Sekolah Kedinasan',
          categoryTag: 'Kedinasan Online',
          gradeLevel: 'SMA - Kelas 12',
          description:
              'Persiapan khusus SKD (TKP, TIU, TWK), Tes Fisik, dan Psikotes masuk PKN STAN, IPDN, STIS.',
          badgeText: 'Live Teaching',
          badgeIcon: Icons.account_balance_rounded,
          priceFormatted: 'Rp 2.600.000',
          periodFormatted: '',
          packageSubtitle: 'KEDINASAN LIVE ONLINE',
          packageDetail: 'MASTER Regular 1 tahun',
          cardBgColor: Color(0xFFEEF2FF),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.97,
          totalReviews: 950,
          isPopular: false,
          illustrationType: 'kedinasan',
          features: [
            'Simulasi CAT SKD sesuai standar BKN',
            'Modul khusus TPA & Psikotes Kedinasan',
            'Bimbingan kesamaptaan & fisik',
          ],
        ),
      ];
}

