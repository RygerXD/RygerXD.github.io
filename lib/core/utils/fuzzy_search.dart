int? fuzzyScore(String candidate, String query) {
  if (candidate.contains(query)) {
    return candidate.indexOf(query);
  }

  int candidateIndex = 0;
  int score = 0;
  for (final int queryCodeUnit in query.codeUnits) {
    final int matchIndex =
        candidate.indexOf(String.fromCharCode(queryCodeUnit), candidateIndex);
    if (matchIndex < 0) {
      return null;
    }
    score += matchIndex - candidateIndex + 1;
    candidateIndex = matchIndex + 1;
  }
  return score + candidate.length;
}
