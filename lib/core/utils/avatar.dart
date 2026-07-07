/// Deterministic local avatar assets. Same [seed] always resolves to the
/// same picture, so a given doctor/patient keeps a stable avatar.
const _doctorAvatarCount = 6;
const _userAvatarCount = 9;

int _seedIndex(String seed, int count) {
  final hash = seed.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return (hash % count) + 1;
}

/// Path to a bundled doctor avatar image.
String doctorAvatarAssetFor(String seed) {
  final index = _seedIndex(seed, _doctorAvatarCount);
  return 'lib/shared/assets-profile/doctor/$index.png';
}

/// Path to a bundled patient/user avatar image.
String userAvatarAssetFor(String seed) {
  final index = _seedIndex(seed, _userAvatarCount);
  return 'lib/shared/assets-profile/user/$index.png';
}
