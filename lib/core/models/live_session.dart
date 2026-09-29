class LiveSession {
  final String id;
  final String title;
  final String subject;
  final String tutorName;
  final String tutorTitle;
  final String dateTimeFormatted;
  final String timeRange;
  final String type;
  final String status;
  final String meetLink;
  final String topic;

  const LiveSession({
    required this.id,
    required this.title,
    required this.subject,
    required this.tutorName,
    required this.tutorTitle,
    required this.dateTimeFormatted,
    required this.timeRange,
    required this.type,
    required this.status,
    required this.meetLink,
    required this.topic,
  });

  static List<LiveSession> get dummySessions => [
        const LiveSession(
          id: 'ses-01',
          title: 'Bedah Trik Cepat Dinamika Rotasi & Momen Inersia',
          subject: 'Fisika SMA (Kelas 12)',
          tutorName: 'Kak Dimas Prasetyo, S.Si.',
          tutorTitle: 'Master Tutor Fisika (Alumnus ITB)',
          dateTimeFormatted: 'Hari ini, 29 September 2026',
          timeRange: '16.00 - 17.30 WIB',
          type: 'Privat 1-on-1 (Online)',
          status: 'Sedang Berlangsung',
          meetLink: 'https://meet.google.com/ckr-fsk-12b',
          topic: 'Hukum Kekekalan Momentum Sudut & Aplikasi Katrol Pejal',
        ),
        const LiveSession(
          id: 'ses-02',
          title: 'Strategi 60 Detik Tembus Penalaran Kuantitatif SNBT',
          subject: 'TPS UTBK-SNBT',
          tutorName: 'Kak Sarah Nabilla, M.Sc.',
          tutorTitle: 'Spesialis Penalaran Matematika (Alumna UI)',
          dateTimeFormatted: 'Besok, 30 September 2026',
          timeRange: '19.00 - 20.30 WIB',
          type: 'Live Class Grup Supercamp',
          status: 'Mendatang',
          meetLink: 'https://meet.google.com/ckr-snbt-tps',
          topic: 'Aljabar Lanjut, Operasi Aritmetika Baru, & Himpunan',
        ),
        const LiveSession(
          id: 'ses-03',
          title: 'Tutor Datang ke Rumah: Stoikiometri & Larutan Asam-Basa',
          subject: 'Kimia SMA',
          tutorName: 'Kak Fikri Ramadhan, S.Pd.',
          tutorTitle: 'Tutor Kimia Terbaik Cakrawala',
          dateTimeFormatted: 'Kamis, 02 Oktober 2026',
          timeRange: '15.30 - 17.00 WIB',
          type: 'Privat Home Tutoring (Offline)',
          status: 'Mendatang',
          meetLink: 'Lokasi: Rumah Siswa (Tutor Siap Hadir)',
          topic: 'Titrasi Asam Basa dan Perhitungan pH Larutan Penyangga',
        ),
      ];
}
