/// Deterministic real-photo avatars sourced from LoremFlickr, which serves
/// actual tagged stock photos (not illustrations). The `lock` param pins a
/// single photo per seed so a given doctor/patient keeps a stable avatar.
int _seedLock(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return hash % 100;
}

/// A real photo of a person in doctor/medical attire.
String doctorPortraitUrlFor(String seed) {
  return 'https://loremflickr.com/300/300/doctor,uniform?lock=${_seedLock(seed)}';
}

/// A real portrait photo of a person, for patient/profile avatars.
String patientPortraitUrlFor(String seed) {
  return 'https://loremflickr.com/300/300/person,portrait?lock=${_seedLock(seed)}';
}
