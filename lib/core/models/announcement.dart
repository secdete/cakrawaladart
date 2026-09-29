class AcademicAnnouncement {
  final String id;
  final String category;
  final String title;
  final String date;
  final String summary;
  final bool isImportant;
  final String author;

  const AcademicAnnouncement({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.summary,
    this.isImportant = false,
    required this.author,
  });

  static List<AcademicAnnouncement> getSampleAnnouncements() {
    return const [
      AcademicAnnouncement(
        id: 'ANN-2025-01',
        category: 'AKADEMIK',
        title: 'Jadwal Pengisian & Konsultasi KRS Semester Ganjil 2025/2026',
        date: '28 Sep 2025',
        summary:
            'Pengisian Kartu Rencana Studi (KRS) daring dibuka mulai 25 September s/d 10 Oktober 2025 melalui portal SIAKAD. Mahasiswa diwajibkan melakukan bimbingan dengan Dosen Pembimbing Akademik (PA).',
        isImportant: true,
        author: 'Biro Administrasi Akademik & Kemahasiswaan (BAAK)',
      ),
      AcademicAnnouncement(
        id: 'ANN-2025-02',
        category: 'KEUANGAN',
        title: 'Informasi Pembayaran Biaya Kuliah & Virtual Account Bank Mitra',
        date: '24 Sep 2025',
        summary:
            'Batas akhir pelunasan UKT/SPP Tahap 1 adalah 05 Oktober 2025 pukul 23:59 WIB. Pembayaran dapat dilakukan via VA Bank Mandiri, BNI, BCA, dan BSI.',
        isImportant: true,
        author: 'Bagian Keuangan & Perbendaharaan',
      ),
      AcademicAnnouncement(
        id: 'ANN-2025-03',
        category: 'LAYANAN IT',
        title: 'Peningkatan Keamanan Akun SIAKAD & Himbauan Kewaspadaan Phishing',
        date: '20 Sep 2025',
        summary:
            'Pastikan Anda hanya mengakses SIAKAD melalui domain resmi cakrawala.ac.id. Pihak kampus TIDAK PERNAH meminta kata sandi melalui pesan WhatsApp atau tautan tidak resmi.',
        isImportant: false,
        author: 'Pusat Data & Sistem Informasi Cakrawala',
      ),
      AcademicAnnouncement(
        id: 'ANN-2025-04',
        category: 'BEASISWA',
        title: 'Pembukaan Seleksi Beasiswa Cakrawala Cendekia Prestasi 2025',
        date: '15 Sep 2025',
        summary:
            'Dibuka pendaftaran beasiswa prestasi akademik dan non-akademik bagi mahasiswa aktif semester 3 dan 5 dengan minimal IPK 3.50.',
        isImportant: false,
        author: 'Divisi Pembinaan Prestasi Mahasiswa',
      ),
    ];
  }
}
