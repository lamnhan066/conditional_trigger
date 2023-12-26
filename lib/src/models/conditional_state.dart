/// Result of the review request.
enum ConditionalState {
  /// The conditions have been satisfied but the `keepRemind` has been disabled.
  keepRemindDisabled(
      'The conditions have been satisfied but the `keepRemind` has been disabled'),

  /// This version is satisfied with `noRequestVersions` => Not satisfied.
  noRequestVersion(
      'This version is satisfied with `noRequestVersions` => Not satisfied'),

  /// Not satisfied with minCalls condition.
  @Deprecated('Use `ConditionalState.notSatisfiedWithMinCalls instead`')
  dontSatisfyWithMinCalls('Not satisfied with minCalls condition'),

  /// Not satisfied with minCalls condition.
  notSatisfiedWithMinCalls('Not satisfied with minCalls condition'),

  /// Not satisfied with minDays condition.
  @Deprecated('Use `ConditionalState.notSatisfiedWithMinDays instead`')
  dontSatisfyWithMinDays('Not satisfied with minDays condition'),

  /// Not satisfied with minDays condition.
  notSatisfiedWithMinDays('Not satisfied with minDays condition'),

  /// Not satisfied with minCalls and minDays.
  @Deprecated('Use `ConditionalState.notSatisfiedWithMinCallsAndDays instead`')
  dontSatisfyWithMinCallsAndDays("Not satisfied with minCalls and minDays"),

  /// Not satisfied with minCalls and minDays.
  notSatisfiedWithMinCallsAndDays("Not satisfied with minCalls and minDays"),

  /// Satisfied with all conditions.
  satisfied('Satisfied with all conditions');

  /// Describes the conditional state.
  ///
  /// Useful for printing logs.
  final String text;

  /// Result of the review request..
  const ConditionalState(this.text);
}
