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
    ConditionalTrigger.clearAllLastStates();
    ConditionalTrigger.clearAllMocks();
    instance.dispose();
  });
  group('Call initial', () {
    test('ConditionState.keepRemindDisabled', () async {
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

    test('ConditionState.noRequestVersion', () async {
      instance.setMockInitialValues(
        ConditionalMock(version: '1.0.0'),
      );
      final returned =
          await instance.copyWith(noRequestVersions: ['1.0.0']).check();
      expect(returned, ConditionalState.noRequestVersion);
    });

    test('ConditionState.dontSatisfyWithMinCallsAndDays', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime(0)),
      );
      final returned = await instance.copyWith(minCalls: 2, minDays: 2).check();
      expect(returned, ConditionalState.dontSatisfyWithMinCalls);
    });

    test('ConditionState.dontSatisfyWithMinCalls', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime.now()),
      );
      final returned = await instance.copyWith(minCalls: 2, minDays: 0).check();
      expect(returned, ConditionalState.dontSatisfyWithMinCalls);
    });

    test('ConditionState.dontSatisfyWithMinDays', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime.now()),
      );
      final returned = await instance.copyWith(minDays: 3, minCalls: 0).check();
      expect(returned, ConditionalState.dontSatisfyWithMinDays);
    });

    test('ConditionState.completed', () async {
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
      ConditionalTrigger.clearAllLastStates();
      expect(instance.lastState, null);
      await instance.check();
      expect(instance.lastState, isNot(null));
      expect(instance.lastState, isA<ConditionalState>());
    });

    /// Check will repeat checking when it's called
    test('Test `check`', () async {
      ConditionalTrigger.clearAllLastStates();
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
      expect(state1, ConditionalState.dontSatisfyWithMinCalls);

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

    /// `checkOnce` will keep the first value
    test('Test `checkOnce`', () async {
      ConditionalTrigger.clearAllLastStates();
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
      expect(state1, ConditionalState.dontSatisfyWithMinCalls);

      // Increase `calls` 1 after calling `check`
      SharedPreferences.setMockInitialValues({
        instance.stateKey: ConditionalMock(
          localVersion: '',
          firstDateTime: first,
          calls: 2,
        ).toJson(),
      });
      final state2 = await instance.checkOnce();
      expect(state2, ConditionalState.dontSatisfyWithMinCalls);
    });

    // TODO: Adapt with the deprecated version, remove when releasing to stable
    test(
        'Test with Mock == null and $name.FirstDateTime from SharedPref is not empty',
        () async {
      ConditionalTrigger.clearAllLastStates();
      ConditionalTrigger.clearAllMocks();
      final first = DateTime.now().subtract(const Duration(days: 4));
      SharedPreferences.setMockInitialValues({
        '$name.Version': '',
        '$name.FirstDateTime': first.toIso8601String(),
        '$name.CallThisFunction': 1,
      });
      final state1 = await instance.check();
      expect(state1, ConditionalState.dontSatisfyWithMinCalls);

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
      ConditionalTrigger.clearAllLastStates();
      ConditionalTrigger.clearAllMocks();
      SharedPreferences.setMockInitialValues({});
      final state = await instance.check();
      print(
          (await SharedPreferences.getInstance()).getString(instance.stateKey));
      expect(state, ConditionalState.dontSatisfyWithMinCallsAndDays);
    });
  });

  test('Test inDays', () {
    final past = DateTime.now().subtract(const Duration(days: 5));
    final now = DateTime.now();
    final difference = now.difference(past).inDays;

    expect(difference, equals(5));
  });
}
