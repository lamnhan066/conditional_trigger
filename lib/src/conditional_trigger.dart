import 'package:package_info_plus/package_info_plus.dart';
import 'package:satisfied_version/satisfied_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/conditional_mocks.dart';
import 'models/conditional_state.dart';

class ConditionalTrigger {
  /// Clear all mocks
  static void clearAllMocks() => ConditionalMock.clearAllMocks();

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

  /// Request with delayed duaration
  final Duration? duration;

  /// Debug
  final bool debugLog;

  /// Set mock values.
  void setMockInitialValues([ConditionalMock? mock]) {
    ConditionalMock.setMock(name, mock);
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

  /// This function will check whether the conditions is satisfied.
  Future<ConditionalState> check() async {
    final mock = ConditionalMock.getMock(name);

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
      if (state.calls < minCalls) {
        return _print(ConditionalState.dontSatisfyWithMinCalls)!;
      }

      return _print(ConditionalState.dontSatisfyWithMinDays)!;
    }
  }

  /// Print the debug log
  ConditionalState? _print(Object log) {
    if (log is ConditionalState) {
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
