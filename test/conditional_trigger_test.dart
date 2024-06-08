import 'package:conditional_trigger/conditional_trigger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const name = 'ConditionHelper';
  const instance = ConditionalTrigger(name, debugLog: true);
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
      buildSignature: '',
    );
  });
  tearDownAll(() {
    SharedPreferences.setMockInitialValues({});
    ConditionalTrigger.clearAllStates();
    ConditionalTrigger.clearAllMocks();
    instance.dispose();
  });
  group('Call initial', () {
    test('ConditionalState.keepRemindDisabled', () async {
      instance.setMockInitialValues(
        ConditionalMock(version: '1.0.0', isRequested: true),
      );

      final returned1 = await instance.check();
      expect(returned1, ConditionalState.keepRemindDisabled);

      final returned2 = await instance.copyWith(keepRemind: true).check();
      expect(returned2, isNot(ConditionalState.keepRemindDisabled));
      final returned3 =
          await instance.copyWith(remindedVersions: ['1.0.0']).check();
      expect(returned3, isNot(ConditionalState.keepRemindDisabled));
    });

    test('ConditionalState.noRequestVersion', () async {
      instance.setMockInitialValues(
        ConditionalMock(version: '1.0.0'),
      );
      final returned =
          await instance.copyWith(noRequestVersions: ['1.0.0']).check();
      expect(returned, ConditionalState.noRequestVersion);
    });

    test('ConditionalState.notSatisfiedWithMinCallsAndDays', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime(0)),
      );
      final returned = await instance.copyWith(minCalls: 2, minDays: 2).check();
      expect(returned, ConditionalState.notSatisfiedWithMinCalls);
    });

    test('ConditionalState.notSatisfiedWithMinCalls', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime.now()),
      );
      final returned = await instance.copyWith(minCalls: 2, minDays: 0).check();
      expect(returned, ConditionalState.notSatisfiedWithMinCalls);
    });

    test('ConditionalState.notSatisfiedWithMinDays', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime.now()),
      );
      final returned = await instance.copyWith(minDays: 3, minCalls: 0).check();
      expect(returned, ConditionalState.notSatisfiedWithMinDays);
    });

    test('ConditionalState.completed', () async {
      instance.setMockInitialValues(
        ConditionalMock(
          calls: 5,
          firstDateTime: DateTime.now().subtract(const Duration(days: 5)),
        ),
      );
      final returned = await instance
          .copyWith(
            minCalls: 5,
            minDays: 5,
            debugLog: false,
          )
          .check();
      expect(returned, ConditionalState.satisfied);
    });

    test('Test `lastState`', () async {
      ConditionalTrigger.clearAllStates();
      expect(instance.lastState, null);
      await instance.check();
      expect(instance.lastState, isNot(null));
      expect(instance.lastState, isA<ConditionalState>());
    });

    /// Check will repeat checking when it's called
    test('Test `check`', () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      final first = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 1,
        ).toJson(),
      });
      final state1 = await instance.check();
      expect(state1, ConditionalState.notSatisfiedWithMinCalls);

      // Increase `calls` 1 after calling `check`
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 2,
        ).toJson(),
      });
      final state2 = await instance.check();
      expect(state2, ConditionalState.satisfied);
    });

    test('Test `check` call increment', () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      SharedPreferences.setMockInitialValues({});
      await instance.check();
      await instance.check();
      final state = await instance.check();
      expect(state, ConditionalState.notSatisfiedWithMinDays);
    });

    test('Test `check` day increment', () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      final first = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 1,
        ).toJson(),
      });

      // calls + 1 = 2
      await instance.check();

      // calls + 1 = 3
      final state = await instance.check();
      expect(state, ConditionalState.satisfied);
    });

    /// `checkOnce` will keep the first value
    test('Test `checkOnce`', () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      final first = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 1,
        ).toJson(),
      });
      final state1 = await instance.checkOnce();
      expect(state1, ConditionalState.notSatisfiedWithMinCalls);

      // Increase `calls` 1 after calling `check`
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 2,
        ).toJson(),
      });
      final state2 = await instance.checkOnce();
      expect(state2, ConditionalState.notSatisfiedWithMinCalls);
    });

    // TODO: Adapt with the deprecated version, remove when releasing to stable
    test(
        'Test with Mock == null and $name.FirstDateTime from SharedPref is not empty',
        () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      final first = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        '$name.Version': '',
        '$name.FirstDateTime': first.toIso8601String(),
        '$name.CallThisFunction': 1,
      });
      final state1 = await instance.check();
      expect(state1, ConditionalState.notSatisfiedWithMinCalls);

      SharedPreferences.setMockInitialValues({
        '$name.Version': '',
        '$name.FirstDateTime': first.toIso8601String(),
        '$name.CallThisFunction': 2,
      });
      final state2 = await instance.check();
      expect(state2, ConditionalState.satisfied);
    });

    test(
        'Test with Mock == null and $name.FirstDateTime from SharedPref is empty',
        () async {
      ConditionalTrigger.clearAllStates();
      ConditionalTrigger.clearAllMocks();
      SharedPreferences.setMockInitialValues({});
      final state = await instance.check();

      expect(state, ConditionalState.notSatisfiedWithMinCallsAndDays);
    });
  });

  test('Test inDays', () {
    final past = DateTime.now().subtract(const Duration(days: 5));
    final now = DateTime.now();
    final difference = now.difference(past).inDays;

    expect(difference, equals(5));
  });
}
