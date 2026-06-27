/// High-level app lifecycle stage driving the root navigator.
enum Stage { splash, onboarding, login, app }

/// Every destination reachable from the authenticated shell. The first five are
/// tabs in the bottom navigation; the rest are pushed full-screen views.
enum MainView {
  beranda,
  catatan,
  ai,
  progres,
  profil,
  dokter,
  riwayat,
  notifikasi,
  edukasi,
}
