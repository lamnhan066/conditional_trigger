import 'package:package_info_plus/package_info_plus.dart';
import 'package:satisfied_version/satisfied_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/conditional_state.dart';

part 'models/conditional_mocks.dart';

class ConditionalTrigger {
  /// Save the current state of the conditional trigger
  static final Map<String, ConditionalState?> _states = {};

  /// Set state
  static void _setState(String name, ConditionalState state) {
    _states[name] = state;
  }

  /// Get state
  static ConditionalState? _getState(String name) {
    return _states[name];
  }

  /// Remove the state
  static void _removeState(String name) => _states.remove(name);

  /// Clear all states
  static void clearAllLastStates() => _states.clear();

  /// Clear all mocks
  static void clearAllMocks() => ConditionalMock._clearAllMocks();

  /// Create the conditions that help you to control the conditions before doing something.
  const ConditionalTrigger(
    this.name, {
    this.minDays = 3,
    this.minCalls = 3,
    this.noRequestVersions = const [],
    this.remindedVersions = const [],
    this.keepRemind = false,
    this.duration,
    this.debugLog = false,
  });

  /// Name of this contidion. This is also known as prefix of the SharedPreferences.
  final String name;

  /// Min days since this method is called
  final int minDays;

  /// Min calls of this method (increase counter when this method is executed)
  /// If you add this line in your main(), it's same as app opening count
  final int minCalls;

  /// If the current version is satisfied with this than not showing the request
  /// this value use plugin `satisfied_version` to compare.
  final List<String> noRequestVersions;

  /// List of version that allow the app to remind the in-app review.
  final List<String> remindedVersions;

  /// If true, it'll keep asking for the Case on each new version (and satisfy with all the above Case).
  /// If false, it only requests for the first time the Case are satisfied.
  final bool keepRemind;

  /// Set a delayed when the `ConditionalState.satisfied` is returned.
  final Duration? duration;

  /// Debug
  final bool debugLog;

  /// You can use [lastState] to get the ConditionState if you already ran `check()` somewhere else.
  ///
  /// This value will be `null` if there is no ran `check()`.
  ConditionalState? get lastState => _getState(name);

  /// Set mock values.
  void setMockInitialValues([ConditionalMock? mock]) {
    ConditionalMock._setMock(name, mock);
  }

  /// Create a copy of Condition
  ConditionalTrigger copyWith({
    String? name,
    String? version,
    int? minDays,
    int? minCalls,
    List<String>? noRequestVersions,
    List<String>? remindedVersions,
    bool? keepRemind,
    Duration? duration,
    bool? debugLog,
  }) {
    return ConditionalTrigger(
      name ?? this.name,
      minDays: minDays ?? this.minDays,
      minCalls: minCalls ?? this.minCalls,
      noRequestVersions: noRequestVersions ?? this.noRequestVersions,
      remindedVersions: remindedVersions ?? this.remindedVersions,
      keepRemind: keepRemind ?? this.keepRemind,
      duration: duration ?? this.duration,
      debugLog: debugLog ?? this.debugLog,
    );
  }

  /// This function will check whether the conditions is satisfied and save the state.
  ///
  /// Use `checkOnce()` if you don't want to save the state for later use with `lastState`.
  Future<ConditionalState> check() async {
    final mock = ConditionalMock._getMock(name);

    ConditionalMock state;
    if (mock != null) {
      state = mock;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final firstDateTimeString = prefs.getString('$name.FirstDateTime') ?? '';

      state = ConditionalMock(
        version: (await PackageInfo.fromPlatform()).version,
        localVersion: prefs.getString('$name.Version') ?? '0.0.0',
        isRequested: prefs.getBool('$name.Requested') ?? false,
        firstDateTime: DateTime.tryParse(firstDateTimeString),
        nowDateTime: DateTime.now(),
        calls: prefs.getInt('$name.CallThisFunction') ?? 0,
      );
    }

    // Compare version
    if (state.isRequested) {
      final getKeepRemind =
          keepRemind || state.version.satisfiedWith(remindedVersions);
      if (!getKeepRemind) {
        return _print(ConditionalState.keepRemindDisabled)!;
      }
    }

    // Compare with noRequestVersions
    if (state.version.satisfiedWith(noRequestVersions)) {
      return _print(ConditionalState.noRequestVersion)!;
    }

    // Reset variables
    if (state.localVersion != state.version) {
      state = state.copyWith(
        calls: 0,
        firstDateTime: DateTime.now(),
        isRequested: false,
      );
    }

    // Increase data
    state = state.copyWith(calls: state.calls + 1);
    int days = state.nowDateTime.difference(state.firstDateTime).inDays;

    // Save data back to prefs
    if (mock != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('$name.Version', state.version);
      prefs.setInt('$name.CallThisFunction', state.calls);
      prefs.setString(
        '$name.FirstDateTime',
        state.nowDateTime.toIso8601String(),
      );

      if (state.calls >= minCalls && days >= minDays) {
        prefs.setBool('$name.Requested', true);
      }
    }

    // Print debug
    _print(
        'prefs version: ${state.localVersion}, currentVersion: ${state.version}');
    _print('Call this function ${state.calls} times');
    _print('First time open this app was $days days before');

    // Compare
    if (state.calls >= minCalls && days >= minDays) {
      _print('Satisfy with all conditions');

      if (duration != null) await Future.delayed(duration!);

      return _print(ConditionalState.satisfied)!;
    } else {
      if (state.calls < minCalls && days < minDays) {
        return _print(ConditionalState.dontSatisfyWithMinCallsAndDays)!;
      }

      if (state.calls < minCalls) {
        return _print(ConditionalState.dontSatisfyWithMinCalls)!;
      }

      return _print(ConditionalState.dontSatisfyWithMinDays)!;
    }
  }

  /// [Optional] Free the memory if there is no longer used
  void dispose() {
    _removeState(name);
    ConditionalMock._removeMock(name);
  }

  /// Print the debug log
  ConditionalState? _print(Object log) {
    if (log is ConditionalState) {
      _setState(name, log);
      if (debugLog) {
        // ignore: avoid_print
        print('[Condition Helper - $name] ${log.text}');
      }
      return log;
    }
    if (debugLog) {
      // ignore: avoid_print
      print('[Condition Helper - $name] $log');
    }
    return null;
  }
}
