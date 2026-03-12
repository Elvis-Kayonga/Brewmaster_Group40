# Auth Screen Routing Fix — Tasks

## Task 1: Add Provider Registration to main.dart
- [x] 1.1 Add imports for `provider`, `AuthProvider`, and `LoginScreen` to `lib/main.dart`
- [x] 1.2 Wrap `MyApp` with `ChangeNotifierProvider<AuthProvider>` in `main()`, calling `init()` on creation

## Task 2: Create AuthGate Widget
- [x] 2.1 Create `AuthGate` widget in `lib/main.dart` that uses `Consumer<AuthProvider>` to check `isAuthenticated`
- [x] 2.2 Return `LoginScreen` when not authenticated, placeholder main content when authenticated

## Task 3: Replace Home Widget
- [x] 3.1 Change `home:` in `MyApp.build()` from `MyHomePage(...)` to `AuthGate()`
- [x] 3.2 Remove `MyHomePage` and `_MyHomePageState` classes from `lib/main.dart`

## Task 4: Write Exploratory Tests (Bugfix Exploration)
- [x] 4.1 [PBT-exploration] Write property test verifying `AuthProvider` is resolvable from widget tree — expect failure on unfixed code
- [x] 4.2 [PBT-exploration] Write property test verifying unauthenticated launch shows `LoginScreen` — expect failure on unfixed code

## Task 5: Write Fix Verification Tests
- [x] 5.1 [PBT-fix] Write property test: for any auth state, `AuthGate` renders `LoginScreen` when unauthenticated and main content when authenticated (Property 1)
- [x] 5.2 [PBT-fix] Write property test: `AuthProvider` is always resolvable from the widget tree without errors (Property 1)

## Task 6: Write Preservation Tests
- [x] 6.1 [PBT-preservation] Write property test: Material 3 brown color scheme theme is unchanged after fix (Property 2)
- [x] 6.2 [PBT-preservation] Write property test: MaterialApp title remains 'BrewMaster' and Firebase init logic is preserved (Property 2)

## Task 7: Write Integration Tests
- [x] 7.1 Write widget test for full unauthenticated launch → LoginScreen flow
- [x] 7.2 Write widget test for authenticated launch → main content flow
