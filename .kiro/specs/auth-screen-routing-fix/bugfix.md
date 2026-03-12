# Bugfix Requirements Document

## Introduction

The BrewMaster app does not show authentication screens when it launches. Instead, it displays a default Flutter counter placeholder widget (`MyHomePage`). The root cause is that `main.dart` hardcodes `MyHomePage` as the home widget and never wires up `AuthProvider` or any auth-gating logic. Auth screens (LoginScreen, SignupScreen, ProfileSetupScreen) and the AuthProvider are fully implemented but unreachable from the app's entry point.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app launches and the user is not authenticated THEN the system displays the MyHomePage placeholder counter widget instead of the LoginScreen

1.2 WHEN the app launches and the user is already authenticated THEN the system still displays the MyHomePage placeholder counter widget instead of the main app content

1.3 WHEN AuthProvider is used by auth screens (LoginScreen, SignupScreen) via `context.read<AuthProvider>()` THEN the system throws a ProviderNotFoundException because AuthProvider is not registered in the widget tree

### Expected Behavior (Correct)

2.1 WHEN the app launches and the user is not authenticated THEN the system SHALL display the LoginScreen as the initial screen

2.2 WHEN the app launches and the user is already authenticated THEN the system SHALL display the main app screen (bypassing the login flow)

2.3 WHEN auth screens access AuthProvider via Provider THEN the system SHALL resolve AuthProvider from the widget tree without errors because it is registered as an ancestor widget

### Unchanged Behavior (Regression Prevention)

3.1 WHEN Firebase is initialized at app startup THEN the system SHALL CONTINUE TO initialize Firebase with the current platform options and Firestore offline persistence settings

3.2 WHEN the user successfully signs in via LoginScreen THEN the system SHALL CONTINUE TO navigate away from the auth flow to the main app content

3.3 WHEN the user signs out THEN the system SHALL CONTINUE TO return to the LoginScreen

3.4 WHEN the app theme is applied THEN the system SHALL CONTINUE TO use the brown color scheme with Material 3

---

### Bug Condition (Formal)

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type AppLaunchState
  OUTPUT: boolean

  // The bug triggers on every app launch because the home widget
  // is unconditionally set to MyHomePage regardless of auth state
  RETURN TRUE
END FUNCTION
```

The bug condition is trivially true for all launches — the app always shows the placeholder.

### Property Specification

```pascal
// Property: Fix Checking — Auth-gated routing on launch
FOR ALL X WHERE isBugCondition(X) DO
  screen ← launchApp'(X)
  IF NOT X.isAuthenticated THEN
    ASSERT screen = LoginScreen
  ELSE
    ASSERT screen = MainAppScreen
  END IF
END FOR
```

### Preservation Goal

```pascal
// Property: Preservation Checking — Non-routing behavior unchanged
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT launchApp(X) = launchApp'(X)
END FOR
```

Since the bug condition covers all launches, preservation focuses on ensuring that Firebase initialization, theming, auth service behavior, and existing screen implementations remain unchanged.
