# Auth Screen Routing Fix — Bugfix Design

## Overview

The BrewMaster app's `main.dart` hardcodes `MyHomePage` (a Flutter counter placeholder) as the home widget and never registers `AuthProvider` in the widget tree. This means all auth screens (`LoginScreen`, `SignupScreen`, `ProfileSetupScreen`) are unreachable, and any call to `context.read<AuthProvider>()` throws `ProviderNotFoundException`. The fix wraps the app in a `ChangeNotifierProvider<AuthProvider>`, introduces an `AuthGate` widget that listens to Firebase auth state, and routes to `LoginScreen` or the main content accordingly.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug — every app launch, because `MyHomePage` is unconditionally set as the home widget regardless of auth state.
- **Property (P)**: The desired behavior — unauthenticated users see `LoginScreen`; authenticated users see the main app content; `AuthProvider` is resolvable from the widget tree.
- **Preservation**: Firebase initialization, Firestore offline persistence settings, Material 3 brown theme, and all existing screen implementations must remain unchanged.
- **AuthProvider**: The `ChangeNotifier` in `lib/data/providers/auth_provider.dart` that manages auth state, exposes `isAuthenticated`, `authStateChanges`, and `init()`.
- **AuthGate**: A new widget to be created that listens to `AuthProvider.authStateChanges` and conditionally renders `LoginScreen` or the main app content.
- **MyHomePage**: The placeholder counter widget in `lib/main.dart` that must be replaced as the home widget.

## Bug Details

### Fault Condition

The bug manifests on every app launch. `MyApp.build()` unconditionally returns `MaterialApp(home: MyHomePage(...))`, ignoring auth state entirely. Additionally, `AuthProvider` is never registered via `ChangeNotifierProvider`, so any descendant widget calling `context.read<AuthProvider>()` crashes.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type AppLaunchState
  OUTPUT: boolean

  // The home widget is always MyHomePage — bug triggers on every launch
  RETURN TRUE
END FUNCTION
```

### Examples

- **Unauthenticated launch**: User opens app for the first time → sees counter placeholder instead of `LoginScreen`.
- **Authenticated launch**: User who previously signed in opens app → sees counter placeholder instead of main content.
- **LoginScreen navigation**: If a deep link or manual navigation somehow reaches `LoginScreen`, calling `context.read<AuthProvider>()` throws `ProviderNotFoundException` because no ancestor provides it.
- **Sign-out flow**: After signing out, the app has no mechanism to return to `LoginScreen` since auth-gating doesn't exist.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Firebase initialization with `DefaultFirebaseOptions.currentPlatform` and Firestore offline persistence settings must remain identical.
- The Material 3 brown color scheme theme must remain unchanged.
- `AuthProvider`, `AuthService`, `LoginScreen`, `SignupScreen`, and `ProfileSetupScreen` implementations must not be modified.
- Navigation between auth screens (Login → Signup, etc.) must continue to work as implemented.

**Scope:**
All non-routing behavior is unaffected by this fix. This includes:
- Firebase init logic in `main()`
- `ThemeData` configuration in `MyApp`
- All existing screen widget implementations
- `AuthService` Firebase operations
- `AuthProvider` state management logic

## Hypothesized Root Cause

Based on the bug description and code analysis, the root causes are:

1. **Missing Provider Registration**: `main.dart` never wraps the widget tree with `ChangeNotifierProvider<AuthProvider>`. Without this, any `context.read<AuthProvider>()` call throws `ProviderNotFoundException`.

2. **Hardcoded Home Widget**: `MyApp.build()` sets `home: const MyHomePage(title: 'BrewMaster Coffee Marketplace')` unconditionally. There is no conditional logic based on auth state.

3. **No Auth-Gating Widget**: There is no widget that listens to `AuthProvider.authStateChanges` or checks `AuthProvider.isAuthenticated` to decide which screen to show.

4. **AuthProvider.init() Never Called**: Even if `AuthProvider` were registered, its `init()` method (which sets up the auth state listener) is never invoked.

## Correctness Properties

Property 1: Fault Condition — Auth-Gated Routing on Launch

_For any_ app launch state, the fixed app SHALL display `LoginScreen` when the user is not authenticated and SHALL display the main app content when the user is authenticated, with `AuthProvider` resolvable from the widget tree without errors.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation — Non-Routing Behavior Unchanged

_For any_ aspect of the app that is not related to home widget selection or provider registration, the fixed app SHALL produce the same behavior as the original app, preserving Firebase initialization, theming, and all existing screen implementations.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/main.dart`

**Specific Changes**:

1. **Add Provider Import**: Add `import 'package:provider/provider.dart';` and `import 'package:brewmaster/data/providers/auth_provider.dart';` and `import 'package:brewmaster/presentation/screens/auth/login_screen.dart';`.

2. **Wrap with ChangeNotifierProvider**: In `main()`, wrap `MyApp` with `ChangeNotifierProvider<AuthProvider>` that creates an `AuthProvider` instance and calls `init()`.
   ```dart
   runApp(
     ChangeNotifierProvider(
       create: (_) => AuthProvider()..init(),
       child: const MyApp(),
     ),
   );
   ```

3. **Create AuthGate Widget**: Add a new `AuthGate` `StatelessWidget` in `main.dart` (or a separate file) that uses `Consumer<AuthProvider>` to check `isAuthenticated` and returns `LoginScreen` or a placeholder main content widget.
   ```dart
   class AuthGate extends StatelessWidget {
     const AuthGate({super.key});
     @override
     Widget build(BuildContext context) {
       return Consumer<AuthProvider>(
         builder: (context, auth, _) {
           if (auth.isAuthenticated) {
             return const Scaffold(
               body: Center(child: Text('BrewMaster Home')),
             );
           }
           return const LoginScreen();
         },
       );
     }
   }
   ```

4. **Replace Home Widget**: Change `home: const MyHomePage(...)` to `home: const AuthGate()` in `MyApp.build()`.

5. **Remove MyHomePage**: Delete the `MyHomePage` and `_MyHomePageState` classes since they are placeholder code being replaced.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Fault Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis.

**Test Plan**: Write widget tests that build `MyApp` and verify what widget is rendered as the home screen, and whether `AuthProvider` is resolvable. Run on UNFIXED code to observe failures.

**Test Cases**:
1. **Provider Resolution Test**: Attempt `context.read<AuthProvider>()` from within the widget tree — will throw `ProviderNotFoundException` on unfixed code.
2. **Unauthenticated Home Test**: Launch app with no signed-in user, assert `LoginScreen` is rendered — will fail on unfixed code (finds `MyHomePage` instead).
3. **Authenticated Home Test**: Launch app with a mocked authenticated user, assert main content is rendered — will fail on unfixed code.

**Expected Counterexamples**:
- `ProviderNotFoundException` when accessing `AuthProvider`
- `MyHomePage` rendered instead of `LoginScreen` regardless of auth state

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  app := buildFixedApp(input)
  IF NOT input.isAuthenticated THEN
    ASSERT findWidget(app, LoginScreen) EXISTS
  ELSE
    ASSERT findWidget(app, MainContent) EXISTS
  END IF
  ASSERT context.read<AuthProvider>() DOES NOT THROW
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT buildOriginalApp(input).theme = buildFixedApp(input).theme
  ASSERT buildOriginalApp(input).firebaseInit = buildFixedApp(input).firebaseInit
END FOR
```

**Testing Approach**: Since the bug condition is trivially true for all launches, preservation checking focuses on verifying that non-routing aspects (theme, Firebase init) remain identical. Widget tests can verify theme properties and that the MaterialApp configuration is unchanged.

**Test Plan**: Verify on UNFIXED code that theme and Firebase settings are correct, then write tests asserting the same after the fix.

**Test Cases**:
1. **Theme Preservation**: Verify the brown color scheme with Material 3 is applied in the fixed app.
2. **App Title Preservation**: Verify `MaterialApp.title` remains `'BrewMaster'`.
3. **Auth Screen Implementation Preservation**: Verify `LoginScreen`, `SignupScreen` source code is not modified.

### Unit Tests

- Test that `AuthGate` renders `LoginScreen` when `AuthProvider.isAuthenticated` is false
- Test that `AuthGate` renders main content when `AuthProvider.isAuthenticated` is true
- Test that `AuthProvider` is accessible via `context.read<AuthProvider>()` from within the widget tree

### Property-Based Tests

- Generate random auth states (authenticated/unauthenticated with various user properties) and verify `AuthGate` routes correctly
- Generate random theme configurations and verify theme is passed through unchanged

### Integration Tests

- Test full launch → LoginScreen → sign in → main content flow
- Test full launch → main content (already authenticated) flow
- Test sign out → returns to LoginScreen flow
