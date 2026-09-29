class BimbelProgram {
  final String id;
  final String title;
  final String gradeLevel;
  final String description;
  final String badgeText;
  final String priceFormatted;
  final String periodFormatted;
  final double rating;
  final int totalReviews;
  final List<String> features;
  final bool isPopular;
  final String iconType;

  const BimbelProgram({
    required this.id,
    required this.title,
    required this.gradeLevel,
    required this.description,
    required this.badgeText,
    required this.priceFormatted,
    required this.periodFormatted,
    required this.rating,
    required this.totalReviews,
    required this.features,
    this.isPopular = false,
    required this.iconType,
  });

  static List<BimbelProgram> get dummyPrograms => [
        const BimbelProgram(
          id: 'prog-privat-1',
          title: 'Cakrawala Privat 1-on-1 (Home / Online)',
          gradeLevel: 'SD, SMP, SMA & UTBK',
          description:
              'Guru datang langsung ke rumah atau tatap muka online eksklusif satu guru satu murid. Jadwal fleksibel sesuai kebutuhan.',
          badgeText: 'Paling Diminati',
          priceFormatted: 'Rp 145.000',
          periodFormatted: '/ sesi (90 Menit)',
          rating: 4.96,
          totalReviews: 890,
          isPopular: true,
          iconType: 'person',
          features: [
            'Bebas pilih jadwal & ganti tutor jika kurang cocok',
            'Kurikulum Nasional (Merdeka), Cambridge, atau IB',
            'Konsultasi PR harian & bedah soal ujian',
            'Laporan presensi & perkembangan belajar ke WhatsApp Orang Tua',
          ],
        ),
        const BimbelProgram(
          id: 'prog-utbk-intensif',
          title: 'Intensif Supercamp UTBK-SNBT 2026',
          gradeLevel: 'Kelas 12 SMA & Alumni',
          description:
              'Program akselerasi tembus PTN Favorit (ITB, UI, UGM, Unair). Bimbingan TPS, Literasi, Penalaran Matematika, & Tryout IRT Nasional.',
          badgeText: 'Jaminan Siap PTN',
          priceFormatted: 'Rp 1.450.000',
          periodFormatted: '/ paket lengkap 3 bulan',
          rating: 4.98,
          totalReviews: 1240,
          isPopular: true,
          iconType: 'trophy',
          features: [
            '16x Sesi Live Class Interaktif Master Tutor lulusan PTN Top',
            '8x Simulasi Tryout Nasional dengan sistem IRT resmi',
            'Analisis rasionalisasi peluang lolos jurusan & PTN pilihan',
            'Modul Sakti Bedah Pola Soal SNBT 5 tahun terakhir',
          ],
        ),
        const BimbelProgram(
          id: 'prog-group-class',
          title: 'Live Interactive Class (Grup Kecil 3-5 Siswa)',
          gradeLevel: 'SMP (7-9) & SMA (10-12)',
          description:
              'Belajar seru dan kolaboratif via live streaming bersama teman sebaya. Diskusi dua arah tanpa rasa canggung.',
          badgeText: 'Hemat & Efektif',
          priceFormatted: 'Rp 390.000',
          periodFormatted: '/ bulan (8 sesi)',
          rating: 4.88,
          totalReviews: 450,
          isPopular: false,
          iconType: 'group',
          features: [
            'Maksimal 5 siswa per kelas agar interaksi tetap intensif',
            'Rekaman sesi belajar dapat ditonton ulang tanpa batas',
            'Kuis berhadiah dan papan peringkat (gamifikasi)',
            'Grup diskusi WhatsApp eksklusif dengan Tutor',
          ],
        ),
        const BimbelProgram(
          id: 'prog-calistung-tk',
          title: 'Fun Calistung & Bahasa Inggris Anak',
          gradeLevel: 'TK / PAUD & SD Kelas 1-2',
          description:
              'Metode belajar bermain yang menyenangkan untuk melatih kemampuan membaca cepat tanpa mengeja, menulis rapi, dan berhitung ceria.',
          badgeText: 'Anak Ceria',
          priceFormatted: 'Rp 120.000',
          periodFormatted: '/ sesi tatap muka',
          rating: 4.95,
          totalReviews: 310,
          isPopular: false,
          iconType: 'child',
          features: [
            'Metode multisensori dengan flashcard dan alat peraga edukatif',
            'Tutor ramah, sabar, dan tersertifikasi psikologi anak',
            'Laporan jurnal harian perkembangan anak',
            'Modul bergambar eksklusif Cakrawala Kids',
          ],
        ),
      ];
}
