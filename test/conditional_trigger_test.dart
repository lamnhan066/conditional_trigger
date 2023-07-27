import 'package:conditional_trigger/conditional_trigger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const instance = ConditionalTrigger('ConditionHelper');
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

    test('ConditionState.dontSatisfyWithMinCallThisFunction', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 0, firstDateTime: DateTime(0)),
      );
      final returned = await instance.copyWith(minCalls: 2).check();
      expect(returned, ConditionalState.dontSatisfyWithMinCalls);
    });

    test('ConditionState.dontSatisfyWithMinDays', () async {
      instance.setMockInitialValues(
        ConditionalMock(calls: 5, firstDateTime: DateTime.now()),
      );
      final returned = await instance.copyWith(minDays: 2, minCalls: 3).check();
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

    test('Test with `ReviewMode.checkOnly`', () async {
      final returned = await instance
          .copyWith(
            minCalls: 0,
            minDays: 0,
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
  });

  test('Test inDays', () {
    final past = DateTime.now().subtract(const Duration(days: 5));
    final now = DateTime.now();
    final difference = now.difference(past).inDays;

    expect(difference, equals(5));
  });
}
