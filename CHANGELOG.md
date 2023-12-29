## 0.4.0

* Removes all deprecated `ConditionalState` to avoid the `switch` issue.
* Removes deprecated methods.

## 0.3.1

* Marks `ConditionalTrigger.clearAllLastStates()` as deprecated with `ConditionalTrigger.clearAllStates()`.
* Marks `ConditionalState.dontSatisfyWithMinCalls`, `ConditionalState.dontSatisfyWithMinDays` and `ConditionalState.dontSatisfyWithMinCallsAndDays` as deprecated with `ConditionalState.notSatisfiedWithMinCalls`, `ConditionalState.notSatisfiedWithMinDays` and `ConditionalState.notSatisfiedWithMinCallsAndDays`.
* Improves the `ConditionalState` descriptions.
* Updates dependencies.

## 0.3.0

* Bump dependencies.

## 0.2.1

* Change `package_info_plus version` to `^4.2.0`.

## 0.2.0

* Upgrade dependencies.

## 0.1.1

* Update dependencies.
* Update comment.
* Update homepage URL.

## 0.1.0

* Bump dependencies.

## 0.0.7

* Added `checkOnce` method.
* Changed the prefix of logs to `ConditionalTrigger`.

## 0.0.6

* Update README.

## 0.0.5

* Add `ConditionalState.dontSatisfyWithMinCallsAndDays`.
* Remove `duration` parameter.

## 0.0.4

* Bump dependencies

## 0.0.3

* Add `lastState` to `ConditionalTrigger` to get the last state of the `check()`.
* Add `dispose` method as an optional to free the memory.
* Able to clear all last states by using `ConditionalTrigger.clearAllStates`.
* Update README.

## 0.0.2

* Initial release.
