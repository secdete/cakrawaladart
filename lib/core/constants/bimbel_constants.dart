class BimbelConstants {
  static const String appName = 'Cakrawala Educentre';
  static const String appTagline = 'Bimbingan Belajar & Les Privat Terpadu';
  static const String companyName = 'PT Indo Prestasi Utama';
  static const String moto = 'Wujudkan Impian Akademik & Tembus Sekolah / PTN Impian';

  static const String contactPhone = '+62 812-8899-7700';
  static const String contactWhatsApp = '6281288997700';
  static const String contactEmail = 'halo@cakrawalaeducentre.com';
  static const String websiteUrl = 'www.cakrawalaeducentre.com';
  static const String operationalHeadquarters = 'Mustika Jaya, Kota Bekasi & Layanan Seluruh Indonesia';

  // Program Categories
  static const List<String> gradeCategories = [
    'Semua Jenjang',
    'TK & Calistung',
    'SD (Kelas 1-6)',
    'SMP (Kelas 7-9)',
    'SMA (Kelas 10-12)',
    'Persiapan UTBK & Kedinasan',
  ];

  static const List<String> curriculums = [
    'Kurikulum Merdeka',
    'Kurikulum 2013 Revisi',
    'Cambridge (IGCSE / A-Level)',
    'International Baccalaureate (IB)',
  ];

  // Demo Credentials
  static const Map<String, dynamic> demoStudent = {
    'role': 'Siswa',
    'id': 'CKR-2026-0812',
    'name': 'Farhan Arya Nugraha',
    'grade': 'Kelas 12 SMA - IPA (Target SNBT)',
    'school': 'SMAN Unggulan 1',
    'targetPtn': 'STEI Institut Teknologi Bandung (Pilihan 1) & FK UI (Pilihan 2)',
    'activePackage': 'Intensif Supercamp SNBT + Privat Fisika 1-on-1',
    'remainingSessions': 12,
    'totalSessions': 24,
    'averageTryoutScore': 724,
    'nationalRank': 'Peringkat 14 dari 8.420 Peserta',
    'email': 'farhan.arya@gmail.com',
    'password': 'cakrawala2026',
  };

  static const Map<String, dynamic> demoParent = {
    'role': 'Orang Tua',
    'id': 'PRN-9904-812',
    'name': 'Ibu Rina Kusuma Dewi',
    'childName': 'Farhan Arya Nugraha',
    'childGrade': 'Kelas 12 SMA',
    'phone': '0812-9876-5432',
    'subscriptionStatus': 'Aktif (Paket Semester Ganjil)',
    'nextPaymentDate': '15 November 2026',
    'email': 'rina.kusuma@gmail.com',
    'password': 'cakrawala2026',
  };

  static const Map<String, dynamic> demoTutor = {
    'role': 'Master Tutor',
    'id': 'TTR-0412-DIMAS',
    'name': 'Kak Dimas Prasetyo, S.Si.',
    'specialization': 'Master Tutor Fisika & Penalaran Matematika (Alumnus ITB)',
    'rating': 4.95,
    'totalReviews': 148,
    'activeStudents': 18,
    'teachingHours': '340+ Jam Mengajar',
    'email': 'dimas.prasetyo@cakrawalaeducentre.com',
    'password': 'cakrawala2026',
  };
}
