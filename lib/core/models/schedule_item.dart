class AcademicScheduleItem {
  final String courseCode;
  final String courseName;
  final int sks;
  final String day;
  final String time;
  final String room;
  final String lecturer;
  final String mode;

  const AcademicScheduleItem({
    required this.courseCode,
    required this.courseName,
    required this.sks,
    required this.day,
    required this.time,
    required this.room,
    required this.lecturer,
    required this.mode,
  });

  static List<AcademicScheduleItem> getSampleSchedule() {
    return const [
      AcademicScheduleItem(
        courseCode: 'TIF310',
        courseName: 'Pemrograman Aplikasi Bergerak & Multiplatform',
        sks: 3,
        day: 'Selasa',
        time: '08:00 - 10:30 WIB',
        room: 'Lab Komputasi Gedung B - R.304',
        lecturer: 'Dr. Ir. Hendra Saputra, M.T.',
        mode: 'Praktikum Lab',
      ),
      AcademicScheduleItem(
        courseCode: 'TIF312',
        courseName: 'Arsitektur Perangkat Lunak Terdistribusi',
        sks: 3,
        day: 'Selasa',
        time: '13:00 - 15:30 WIB',
        room: 'Ruang Teori 201 - Gedung Rektorat',
        lecturer: 'Ahmad Fauzi, M.Cs.',
        mode: 'Tatap Muka',
      ),
      AcademicScheduleItem(
        courseCode: 'TIF315',
        courseName: 'Keamanan Siber & Kriptografi Terapan',
        sks: 3,
        day: 'Rabu',
        time: '09:00 - 11:30 WIB',
        room: 'Smart Classroom C.102',
        lecturer: 'Prof. Diana Anggraeni, Ph.D.',
        mode: 'Hybrid',
      ),
      AcademicScheduleItem(
        courseCode: 'TIF318',
        courseName: 'Kecerdasan Buatan & Pembelajaran Mesin',
        sks: 4,
        day: 'Kamis',
        time: '10:00 - 12:45 WIB',
        room: 'Auditorium Cakrawala Utama',
        lecturer: 'Budi Santoso, S.T., M.Kom.',
        mode: 'Tatap Muka',
      ),
      AcademicScheduleItem(
        courseCode: 'TIF320',
        courseName: 'Manajemen Proyek Teknologi Informasi',
        sks: 2,
        day: 'Jumat',
        time: '08:30 - 10:10 WIB',
        room: 'Ruang Seminar 402',
        lecturer: 'Nurul Hidayati, M.M., M.Kom.',
        mode: 'Online LMS',
      ),
    ];
  }
}
