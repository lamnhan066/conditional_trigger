# Conditional Trigger

This plugin will make it easier for you to set the conditions for specific method.

## Usage

``` dart
final condition = ConditionalTrigger('SurveyBanner');
```

<details>

<summary>Full parameters</summary>

``` dart
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

/// Debug
final bool debugLog;
```

</details>

Use this method to check the conditions:

``` dart
final state = await condition.check();

if (state == ConditionalState.satisfied) {
    // Do something
}
```

You can also get the state if you already ran `check()` somewhere else:

``` dart
final state = condition.lastState;
```

<details>

<summary>Full ConditionalState</summary>

``` dart
/// The conditions have been satisfied but the `keepRemind` was disabled
ConditionalState.keepRemindDisabled

/// This version is satisfied with `noRequestVersions` => Don't satisfied
ConditionalState.noRequestVersion

/// Don't satisfy with minCalls and minDays
ConditionalState.dontSatisfyWithMinCallsAndDays

/// Don't satisfy with minCalls condition
ConditionalState.dontSatisfyWithMinCalls

/// Don't satisfy with minDays condition
ConditionalState.dontSatisfyWithMinDays

/// Satisfied with all conditions
ConditionalState.satisfied
```

</details>

Or if you want to show a Widget

``` dart
FutureBuilder(
    future: ConditionalTrigger('SurveyBanner').check(),
    build: (context, snapshot) {
        if (snapshot.data != ConditionalState.satisfied) {
            return SizedBox.shrink();
        }

        return SurveyBanner();
    }
);
```

## Testing

``` dart
/// Set mock values
condition.setMockInitialValues(ConditionalMock());

/// Remove mock values
condition.setMockInitialValues();
```

## Contributions

Contributions to this project are welcome! If you would like to contribute, please feel free to submit pull requests or open issues. However, please note that this project is in early development and may not have well-defined contribution guidelines yet. We appreciate your patience and understanding as we work to build a strong and inclusive community around this package.
