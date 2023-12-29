import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:satisfied_version/satisfied_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/conditional_state.dart';

part 'models/conditional_mocks.dart';

class ConditionalTrigger {
  /// Save the current state of the conditional trigger.
  static final Map<String, ConditionalState?> _states = {};

  /// Set state.
  static void _setState(String name, ConditionalState state) {
    _states[name] = state;
  }

  /// Get state.
  static ConditionalState? _getState(String name) {
    return _states[name];
  }

  /// Remove a state.
  static void _removeState(String name) => _states.remove(name);

  /// Clear all states.
  static void clearAllStates() => _states.clear();

  /// Clear all mocks.
  static void clearAllMocks() => ConditionalMock._clearAllMocks();

  /// Create the conditions that help you to control the conditions before doing something.
  const ConditionalTrigger(
    this.name, {
    this.minDays = 3,
    this.minCalls = 3,
    this.noRequestVersions = const [],
    this.remindedVersions = const [],
    this.keepRemind = false,
    this.debugLog = false,
  });

  /// Name of this contidion. This is also known as prefix of the SharedPreferences.
  final String name;

  /// Min days since this method is called.
  final int minDays;

  /// Min calls of this method (increase counter when this method is executed)
  /// If you add this line in your main(), it's same as app opening count.
  final int minCalls;

  /// If the current version is satisfied with this than not showing the request
  /// this value use plugin `satisfied_version` to compare.
  final List<String> noRequestVersions;

  /// List of version that allow the app to remind the in-app review.
  final List<String> remindedVersions;

  /// If true, it'll keep asking for the ConditionalTrigger on each new version
  /// (and satisfied with all the above ConditionalTrigger). If false, it only requests
  /// for the first time the ConditionalTrigger are satisfied.
  final bool keepRemind;

  /// Print the debug log if this value is `true`.
  final bool debugLog;

  /// You can use [lastState] to get the [ConditionalState] if you already ran `check()` somewhere else.
  ///
  /// This value will be `null` if there is no ran `check()`.
  ConditionalState? get lastState => _getState(name);

  @visibleForTesting
  String get stateKey => _stateKey;

  /// Key of the ConditionalState for SharedPreferences.
  String get _stateKey => 'ConditionalTrigger.State.$name';

  /// Set mock values.
  void setMockInitialValues([ConditionalMock? mock]) {
    ConditionalMock._setMock(name, mock);
  }

  /// Create a copy of Condition.
  ConditionalTrigger copyWith({
    String? name,
    String? version,
    int? minDays,
    int? minCalls,
    List<String>? noRequestVersions,
    List<String>? remindedVersions,
    bool? keepRemind,
    bool? debugLog,
  }) {
    return ConditionalTrigger(
      name ?? this.name,
      minDays: minDays ?? this.minDays,
      minCalls: minCalls ?? this.minCalls,
      noRequestVersions: noRequestVersions ?? this.noRequestVersions,
      remindedVersions: remindedVersions ?? this.remindedVersions,
      keepRemind: keepRemind ?? this.keepRemind,
      debugLog: debugLog ?? this.debugLog,
    );
  }

  /// This function will check whether the conditions are satisfied, the conditions
  /// will be check only one time even multiple `checkOnce` is called. Main different is
  /// this method will NOT insrease the `calls` counter.
  ///
  /// Use `check()` if you want to repeat to check the conditions everytime it is
  /// called.
  Future<ConditionalState> checkOnce() async {
    if (lastState != null) return lastState!;

    return check();
  }

  /// This method will check whether the conditions are satisfied, the conditions
  /// will be repeated to check everytime this method is called. Main different is
  /// this method will insrease the `calls` counter.
  ///
  /// Use `checkOnce()` if you want to check the conditions only one time, the `lastState`
  /// will be returned if it has been checked.
  Future<ConditionalState> check() async {
    final mock = ConditionalMock._getMock(name);

    ConditionalMock state;
    if (mock != null) {
      state = mock;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);

      // Check if there is a saved state for the current `ConditionalTrigger`.
      if (stateJson != null) {
        // Get the data saved from Pref.
        state = ConditionalMock.fromJson(stateJson);

        // Update the new data.
        state = state.copyWith(
          version: (await PackageInfo.fromPlatform()).version,
          nowDateTime: DateTime.now(),
        );
      } else {
        // Get the saved data for older version.
        final firstDateTimeString =
            prefs.getString('$name.FirstDateTime') ?? '';
        if (firstDateTimeString != '') {
          // TODO: Remove this method when releasing to stable.
          state = ConditionalMock(
            version: (await PackageInfo.fromPlatform()).version,
            localVersion: prefs.getString('$name.Version') ?? '0.0.0',
            isRequested: prefs.getBool('$name.Requested') ?? false,
            firstDateTime: DateTime.tryParse(firstDateTimeString),
            nowDateTime: DateTime.now(),
            calls: prefs.getInt('$name.CallThisFunction') ?? 0,
          );
        } else {
          // For newer version.
          state = ConditionalMock(
            version: (await PackageInfo.fromPlatform()).version,
            isRequested: false,
            nowDateTime: DateTime.now(),
            calls: 0,
          );
        }
      }
    }

    // Compare version.
    if (state.isRequested) {
      final getKeepRemind =
          keepRemind || state.version.satisfiedWith(remindedVersions);
      if (!getKeepRemind) {
        return _print(ConditionalState.keepRemindDisabled)!;
      }
    }

    // Compare with noRequestVersions.
    if (state.version.satisfiedWith(noRequestVersions)) {
      return _print(ConditionalState.noRequestVersion)!;
    }

    // Reset variables.
    if (state.localVersion != state.version) {
      state = state.copyWith(
        calls: 0,
        firstDateTime: DateTime.now(),
        isRequested: false,
      );
    }

    // Increase call counter.
    state = state.copyWith(calls: state.calls + 1);
    int days = state.nowDateTime.difference(state.firstDateTime).inDays;

    // Save data back to prefs.
    if (mock != null) {
      final prefs = await SharedPreferences.getInstance();

      if (state.calls >= minCalls && days >= minDays) {
        state = state.copyWith(isRequested: true);
      }

      prefs.setString(_stateKey, state.toJson());
    }

    // Print debug.
    _print(
        'prefs version: ${state.localVersion}, currentVersion: ${state.version}');
    _print('Call this function ${state.calls} times');
    _print('First time open this app was $days days before');

    // Compare values.
    if (state.calls >= minCalls && days >= minDays) {
      _print('Satisfy with all conditions');

      return _print(ConditionalState.satisfied)!;
    } else {
      if (state.calls < minCalls && days < minDays) {
        return _print(ConditionalState.notSatisfiedWithMinCallsAndDays)!;
      }

      if (state.calls < minCalls) {
        return _print(ConditionalState.notSatisfiedWithMinCalls)!;
      }

      return _print(ConditionalState.notSatisfiedWithMinDays)!;
    }
  }

  /// [Optional] Free the memory if there is no longer used.
  void dispose() {
    _removeState(name);
    ConditionalMock._removeMock(name);
  }

  /// Print the debug log.
  ConditionalState? _print(Object log) {
    if (log is ConditionalState) {
      _setState(name, log);
      if (debugLog) {
        // ignore: avoid_print
        print('[ConditionalTrigger-$name] ${log.text}');
      }
      return log;
    }
    if (debugLog) {
      // ignore: avoid_print
      print('[ConditionalTrigger-$name] $log');
    }
    return null;
  }
}
