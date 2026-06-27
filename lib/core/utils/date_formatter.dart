// Indonesian date formatting helpers shared across screens.

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Full Indonesian weekday name, e.g. "Senin".
String dayName(DateTime d) => _dayNames[d.weekday - 1];

/// Full Indonesian month name, e.g. "Juni".
String monthName(DateTime d) => _monthNames[d.month - 1];

/// e.g. "Senin, 23 Juni 2026".
String formatLongDate(DateTime d) =>
    '${dayName(d)}, ${d.day} ${monthName(d)} ${d.year}';

/// e.g. "Sen, 23 Jun".
String formatShortDate(DateTime d) =>
    '${dayName(d).substring(0, 3)}, ${d.day} ${monthName(d).substring(0, 3)}';

/// Time-aware Indonesian greeting.
String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}
