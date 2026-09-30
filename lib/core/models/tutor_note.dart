class TutorNote {
  final String id;
  final String dateFormatted;
  final String subject;
  final String tutorName;
  final String topicCovered;
  final String studentComprehension;
  final String homeworkAssigned;
  final String notesForParents;

  const TutorNote({
    required this.id,
    required this.dateFormatted,
    required this.subject,
    required this.tutorName,
    required this.topicCovered,
    required this.studentComprehension,
    required this.homeworkAssigned,
    required this.notesForParents,
  });

  factory TutorNote.fromJson(Map<String, dynamic> json) => TutorNote(
    id: json['id'] as String,
    dateFormatted: json['dateFormatted'] as String,
    subject: json['subject'] as String,
    tutorName: json['tutorName'] as String,
    topicCovered: json['topicCovered'] as String,
    studentComprehension: json['studentComprehension'] as String,
    homeworkAssigned: json['homeworkAssigned'] as String,
    notesForParents: json['notesForParents'] as String,
  );

  static List<TutorNote> get dummyNotes => [
    const TutorNote(
      id: 'note-01',
      dateFormatted: '27 September 2026',
      subject: 'Fisika SMA (Privat Sesi 12)',
      tutorName: 'Kak Dimas Prasetyo, S.Si.',
      topicCovered: 'Torsi, Momen Gaya, dan Titik Berat Benda Homogen',
      studentComprehension: 'Sangat Baik (95%)',
      homeworkAssigned:
          'Latihan 5 soal variasi UTBK 2024 di buku modul hal. 74',
      notesForParents:
          'Farhan sangat cepat memahami konsep penurunan rumus torsi. Sudah bisa menyelesaikan soal tipe HOTS tanpa bantuan rumus cepat.',
    ),
    const TutorNote(
      id: 'note-02',
      dateFormatted: '24 September 2026',
      subject: 'Matematika Peminatan (Privat Sesi 11)',
      tutorName: 'Kak Sarah Nabilla, M.Sc.',
      topicCovered: 'Turunan Fungsi Trigonometri & Garis Singgung Kurva',
      studentComprehension: 'Baik (85%)',
      homeworkAssigned: 'Drill 3 soal pembuktian identitas turunan',
      notesForParents:
          'Perlu lebih teliti pada tanda minus saat menurunkan fungsi cosinus dan cotangen. Konsep dasar aljabar sudah sangat solid.',
    ),
  ];
}
