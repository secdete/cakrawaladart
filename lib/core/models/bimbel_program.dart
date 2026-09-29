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
  final String imageAsset;

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
    required this.imageAsset,
  });

  static List<BimbelProgram> get dummyPrograms => [
        const BimbelProgram(
          id: 'prog-snbt-1',
          title: 'Pendidikan untuk Investasi di Masa Depan',
          categoryTag: 'Promo Spesial',
          gradeLevel: 'Semua Jenjang',
          description:
              'Rencanakan masa depan yang cerah dengan investasi pendidikan terbaik dari sekarang.',
          badgeText: 'Promo Spesial',
          badgeIcon: Icons.star_rounded,
          priceFormatted: 'Mulai Rp 50.000',
          periodFormatted: '/bulan',
          packageSubtitle: 'Paket Investasi Edukasi',
          cardBgColor: Color(0xFFE0F2FE),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.9,
          totalReviews: 1420,
          isPopular: true,
          illustrationType: 'snbt',
          imageAsset: 'assets/images/promo1.jpg',
          features: [
            'Ratusan video konsep & latihan soal',
            'Tryout IRT Nasional berkala',
            'Modul rangkuman rumus cepat',
          ],
        ),
        const BimbelProgram(
          id: 'prog-privat-2',
          title: 'SPMB SD Negeri Lancar Jaya 2026',
          categoryTag: 'Penerimaan Siswa Baru',
          gradeLevel: 'SD',
          description:
              'Pendaftaran telah dibuka untuk periode 1 Mei - 29 Juni. Daftarkan sekarang juga!',
          badgeText: 'Pendaftaran SD',
          badgeIcon: Icons.school_rounded,
          priceFormatted: 'Gratis Biaya Pendaftaran',
          originalPriceFormatted: 'Rp 100.000',
          discountPercentage: '100%',
          packageSubtitle: 'Syarat: Akta, KK, Pas Foto, Formulir',
          packageDetail: 'Online',
          cardBgColor: Color(0xFFDCFCE7),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.96,
          totalReviews: 890,
          isPopular: true,
          illustrationType: 'privat',
          imageAsset: 'assets/images/promo2.jpg',
          features: [
            'Bebas pilih & ganti tutor',
            'Kurikulum disesuaikan kebutuhan siswa',
            'Laporan presensi & grafik perkembangan',
          ],
        ),
        const BimbelProgram(
          id: 'prog-english-3',
          title: 'SPMB SMAN 1 Glagah 2026/2027',
          categoryTag: 'Penerimaan Siswa Baru',
          gradeLevel: 'SMA - Kelas 10',
          description:
              'Sistem Penerimaan Murid Baru Tahun Ajaran 2026/2027. Jatim Cerdas!',
          badgeText: 'Pendaftaran SMA',
          badgeIcon: Icons.location_city_rounded,
          priceFormatted: 'Info Lebih Lanjut Hubungi Panitia',
          originalPriceFormatted: null,
          discountPercentage: null,
          periodFormatted: '',
          packageSubtitle: 'SMAN 1 Glagah Banyuwangi',
          packageDetail: '3 Bulan',
          cardBgColor: Color(0xFFF3E8FF),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.92,
          totalReviews: 630,
          isPopular: false,
          illustrationType: 'english',
          imageAsset: 'assets/images/promo3.jpg',
          features: [
            'Live teaching bersama pengajar Asing (Native)',
            'Sertifikat berstandar Cambridge',
            'Interactive speaking lab',
          ],
        ),
        const BimbelProgram(
          id: 'prog-live-4',
          title: 'Cegah Malas Demi Masa Depan',
          categoryTag: 'Motivasi Belajar',
          gradeLevel: 'Semua Jenjang',
          description:
              'Ayo semangat belajar dan raih cita-citamu setinggi langit. Jangan biarkan malas menghalangimu!',
          badgeText: 'Motivasi',
          badgeIcon: Icons.local_fire_department_rounded,
          priceFormatted: 'Gratis Akses Materi',
          originalPriceFormatted: 'Rp 50.000',
          discountPercentage: '100%',
          periodFormatted: '',
          packageSubtitle: 'Paket Semangat Belajar',
          cardBgColor: Color(0xFFFFEDD5),
          badgeBgColor: Color(0xFF2563EB),
          rating: 4.88,
          totalReviews: 1100,
          isPopular: true,
          illustrationType: 'liveteaching',
          imageAsset: 'assets/images/promo4.jpg',
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
          imageAsset: 'assets/images/promo1.jpg',
          features: [
            'Simulasi CAT SKD sesuai standar BKN',
            'Modul khusus TPA & Psikotes Kedinasan',
            'Bimbingan kesamaptaan & fisik',
          ],
        ),
      ];
}

