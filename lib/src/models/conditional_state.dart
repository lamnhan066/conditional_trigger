/// Result of the review request.
enum ConditionalState {
  keepRemindDisabled(
      'The conditions have been satisfied but the `keepRemind` was disabled'),
  noRequestVersion(
      'This version is satisfied with `noRequestVersions` => Don\'t satisfied'),
  dontSatisfyWithMinCalls('Don\'t satisfy with minCallThisFunction condition'),
  dontSatisfyWithMinDays('Don\'t satisfy with minDays condition'),
  satisfied('Completed request review');

  /// Describe the conditional state
  final String text;

  /// Result of the review request.
  const ConditionalState(this.text);
}
