/// Result of the review request.
enum ConditionalState {
  /// The conditions have been satisfied but the `keepRemind` was disabled
  keepRemindDisabled(
      'The conditions have been satisfied but the `keepRemind` was disabled'),

  /// This version is satisfied with `noRequestVersions` => Don't satisfied
  noRequestVersion(
      'This version is satisfied with `noRequestVersions` => Don\'t satisfied'),

  /// Don't satisfy with minCalls condition
  dontSatisfyWithMinCalls('Don\'t satisfy with minCalls condition'),

  /// Don't satisfy with minDays condition
  dontSatisfyWithMinDays('Don\'t satisfy with minDays condition'),

  /// Don't satisfy with minCalls and minDays
  dontSatisfyWithMinCallsAndDays("Don't satisfy with minCalls and minDays"),

  /// Satisfied with all conditions
  satisfied('Satisfied with all conditions');

  /// Describe the conditional state
  final String text;

  /// Result of the review request.
  const ConditionalState(this.text);
}
