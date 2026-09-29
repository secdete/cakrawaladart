class TryoutExam {
  final String id;
  final String title;
  final String category;
  final int totalQuestions;
  final int durationMinutes;
  final int? score;
  final int? rank;
  final int? totalParticipants;
  final String status;
  final String deadlineFormatted;

  const TryoutExam({
    required this.id,
    required this.title,
    required this.category,
    required this.totalQuestions,
    required this.durationMinutes,
    this.score,
    this.rank,
    this.totalParticipants,
    required this.status,
    required this.deadlineFormatted,
  });

  static List<TryoutExam> get dummyExams => [
        const TryoutExam(
          id: 'to-01',
          title: 'Tryout Akbar UTBK-SNBT 2026 Seri #04 (Sistem IRT)',
          category: 'TPS & Literasi PTN',
          totalQuestions: 155,
          durationMinutes: 195,
          score: 724,
          rank: 14,
          totalParticipants: 8420,
          status: 'Selesai',
          deadlineFormatted: 'Dikerjakan pada 25 September 2026',
        ),
        const TryoutExam(
          id: 'to-02',
          title: 'Simulasi Drill Penalaran Matematika & TPS Kuantitatif',
          category: 'Drill Soal Harian',
          totalQuestions: 40,
          durationMinutes: 50,
          score: null,
          status: 'Tersedia',
          deadlineFormatted: 'Berakhir dalam 3 hari (02 Okt 2026)',
        ),
        const TryoutExam(
          id: 'to-03',
          title: 'Ujian Pemantapan Penilaian Tengah Semester (PTS) Fisika SMA',
          category: 'Kurikulum Merdeka Kelas 12',
          totalQuestions: 30,
          durationMinutes: 60,
          score: 88,
          rank: 5,
          totalParticipants: 320,
          status: 'Selesai',
          deadlineFormatted: 'Dikerjakan pada 18 September 2026',
        ),
      ];
}
