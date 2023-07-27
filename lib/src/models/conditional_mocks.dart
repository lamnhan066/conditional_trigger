part of '../conditional_trigger.dart';

class ConditionalMock {
  /// Map of mocks
  static final Map<String, ConditionalMock?> _mocks = {};

  /// Set ConditionalMock
  static void _setMock(String name, ConditionalMock? mock) {
    _mocks.remove(name);
    if (mock != null) _mocks[name] = mock;
  }

  /// Get ConditionalMock
  static ConditionalMock? _getMock(String name) => _mocks[name];

  /// Remove mock
  static void _removeMock(String name) => _mocks.remove(name);

  /// Clear all mocks
  static void _clearAllMocks() => _mocks.clear();

  /// Current version of the app
  final String version;

  /// Version that is in shared preferences
  final String localVersion;

  /// Mark as requested
  final bool isRequested;

  /// Mock value for the first time the app opened.
  final DateTime firstDateTime;

  /// Mock value for now DateTime.
  final DateTime nowDateTime;

  /// Mock value from preferences.
  final int calls;

  /// Set mock values for testing
  ConditionalMock({
    /// Current version of the app
    this.version = '0.0.0',

    /// Version of the app in shared preferences
    this.localVersion = '0.0.0',

    /// Mark as requested
    this.isRequested = false,

    /// Mock value for the first time the app is opened.
    DateTime? firstDateTime,

    /// Mock value for current DateTime.
    DateTime? nowDateTime,

    /// Mock value from preferences.
    this.calls = 0,
  })  : firstDateTime = firstDateTime ?? DateTime.now(),
        nowDateTime = nowDateTime ?? DateTime.now();

  /// Copy the ConditionalMock with specific changes
  ConditionalMock copyWith({
    String? version,
    String? localVersion,
    bool? isRequested,
    DateTime? firstDateTime,
    DateTime? nowDateTime,
    int? calls,
  }) =>
      ConditionalMock(
        version: version ?? this.version,
        localVersion: localVersion ?? this.localVersion,
        isRequested: isRequested ?? this.isRequested,
        firstDateTime: firstDateTime ?? this.firstDateTime,
        nowDateTime: nowDateTime ?? this.nowDateTime,
        calls: calls ?? this.calls,
      );
}
