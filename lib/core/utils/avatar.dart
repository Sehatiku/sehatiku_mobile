/// Deterministic real-person portrait photo for a given name, sourced from
/// randomuser.me's static portrait set. Same [seed] always resolves to the
/// same photo, so a given doctor/patient keeps a stable avatar.
String portraitUrlFor(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (sum, c) => sum + c);
  final gender = hash.isEven ? 'men' : 'women';
  final index = hash % 100;
  return 'https://randomuser.me/api/portraits/$gender/$index.jpg';
}
