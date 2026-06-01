# Design Document: Bottom Sheet Improvements and Version Management

## Overview

This design addresses two critical improvements to the Flutter employee management application:

1. **Bottom Sheet Behavior Enhancement**: Implementing auto-close on navigation, full-screen display with hidden app header, and consistent close icon styling across all bottom sheet implementations (Apply Leave, Expenditure Claim, Supply Requisition).

2. **Centralized Version Management**: Eliminating manual version synchronization between `pubspec.yaml` and Android build configuration by making `pubspec.yaml` the single source of truth for version information.

The current implementation has several issues:
- Bottom sheets remain open when users navigate away, causing UI conflicts
- Bottom sheets don't utilize full screen height and the app header remains visible
- Close icon styling is inconsistent across different bottom sheet pages
- Version numbers must be manually synchronized between `pubspec.yaml` (2.0.2+4) and `build.gradle` (versionCode 6, versionName "3.0"), leading to inconsistencies

This design provides a comprehensive solution that improves user experience, maintains UI consistency, and reduces developer maintenance burden.

## Architecture

### Component Structure

```
lib/
├── shared/
│   └── fullscreen_bottom_sheet.dart (Enhanced)
│       ├── FullscreenBottomSheet widget
│       ├── NavigationObserver for auto-close
│       ├── UnsavedChangesDetector mixin
│       └── showFullscreenBottomSheet() helper
│
├── features/
│   ├── leave/
│   │   └── apply_leave.dart (Updated)
│   ├── expenditure/
│   │   └── apply_claim.dart (Updated)
│   └── supply/
│       └── apply_supply.dart (Updated)
│
android/
└── app/
    └── build.gradle (Enhanced with version extraction)
```

### Key Design Patterns

1. **Observer Pattern**: NavigationObserver monitors route changes to trigger bottom sheet dismissal
2. **Mixin Pattern**: UnsavedChangesDetector provides reusable form state detection
3. **Builder Pattern**: Enhanced showFullscreenBottomSheet() with configuration options
4. **Single Source of Truth**: Pubspec.yaml as the authoritative version source

## Components and Interfaces

### 1. Enhanced FullscreenBottomSheet Widget

```dart
class FullscreenBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final bool showDragHandle;
  final bool enableUnsavedChangesCheck;
  final ValueGetter<bool>? hasUnsavedChanges;
  
  // Accessibility properties
  final String? semanticLabel;
  final FocusNode? initialFocusNode;
}
```

**Responsibilities**:
- Render full-screen bottom sheet with SafeArea
- Display consistent header with gradient background
- Provide standardized close icon (Icons.close_rounded, size 24, white color)
- Handle unsaved changes confirmation
- Support accessibility features (semantic labels, focus management)

### 2. BottomSheetNavigationObserver

```dart
class BottomSheetNavigationObserver extends NavigatorObserver {
  final VoidCallback onNavigationDetected;
  
  @override
  void didPush(Route route, Route? previousRoute);
  
  @override
  void didPop(Route route, Route? previousRoute);
  
  @override
  void didReplace({Route? newRoute, Route? oldRoute});
}
```

**Responsibilities**:
- Monitor navigation events in the app
- Trigger callback when navigation occurs while bottom sheet is open
- Distinguish between bottom sheet dismissal and actual navigation

### 3. UnsavedChangesDetector Mixin

```dart
mixin UnsavedChangesDetector {
  bool hasUnsavedFormData(List<TextEditingController> controllers);
  
  Future<bool> showUnsavedChangesDialog(BuildContext context);
}
```

**Responsibilities**:
- Check if any TextEditingController has non-empty text
- Display confirmation dialog for unsaved changes
- Return user's decision (confirm or cancel dismissal)

### 4. Enhanced showFullscreenBottomSheet() Helper

```dart
Future<T?> showFullscreenBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool enableUnsavedChangesCheck = false,
  ValueGetter<bool>? hasUnsavedChanges,
  String? semanticLabel,
  FocusNode? initialFocusNode,
  VoidCallback? onNavigationDetected,
})
```

**Responsibilities**:
- Configure and display bottom sheet with full-screen behavior
- Set up navigation observer if auto-close is needed
- Configure unsaved changes detection
- Apply accessibility settings
- Return result when bottom sheet is dismissed

### 5. Version Extraction in build.gradle

```groovy
// Extract version from pubspec.yaml
def getPubspecVersion() {
    def pubspecFile = file("../../pubspec.yaml")
    def pubspecContent = pubspecFile.text
    def versionMatch = (pubspecContent =~ /version:\s*(\d+\.\d+\.\d+)\+(\d+)/)
    
    if (versionMatch) {
        return [
            name: versionMatch[0][1],  // e.g., "2.0.2"
            code: versionMatch[0][2].toInteger()  // e.g., 4
        ]
    }
    throw new GradleException("Invalid version format in pubspec.yaml")
}

def version = getPubspecVersion()
```

**Responsibilities**:
- Parse pubspec.yaml during build time
- Extract semantic version (major.minor.patch)
- Extract build number
- Validate version format
- Fail build with descriptive error if format is invalid

## Data Models

### BottomSheetConfig

```dart
class BottomSheetConfig {
  final String title;
  final bool isScrollControlled;
  final bool useRootNavigator;
  final bool enableUnsavedChangesCheck;
  final bool enableAutoCloseOnNavigation;
  final String? semanticLabel;
  
  const BottomSheetConfig({
    required this.title,
    this.isScrollControlled = true,
    this.useRootNavigator = false,
    this.enableUnsavedChangesCheck = false,
    this.enableAutoCloseOnNavigation = true,
    this.semanticLabel,
  });
}
```

### Version Information

```dart
// Represented in pubspec.yaml as:
// version: major.minor.patch+build
// Example: version: 2.0.2+4

// Maps to Android as:
// versionName: "major.minor.patch"  // e.g., "2.0.2"
// versionCode: build                // e.g., 4
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Auto-close on navigation

*For any* bottom sheet (Apply Leave, Expenditure Claim, or Supply Requisition) that is currently open, when a navigation event occurs, the bottom sheet should be automatically closed before the navigation completes.

**Validates: Requirements 1.1, 1.4**

### Property 2: Navigation observer registration

*For any* bottom sheet displayed using showFullscreenBottomSheet(), the navigation observer should be properly registered and should receive navigation events (didPush, didPop, didReplace) from the Navigator.

**Validates: Requirements 1.2**

### Property 3: Full-screen height occupation

*For any* bottom sheet displayed, the bottom sheet widget should occupy the full available screen height (from top to bottom), accounting for system UI elements via SafeArea.

**Validates: Requirements 2.1**

### Property 4: App header visibility toggle

*For any* bottom sheet, when the bottom sheet is displayed the app header should be hidden, and when the bottom sheet is dismissed the app header should reappear. This is a round-trip property where show-then-dismiss restores the original header visibility state.

**Validates: Requirements 2.2, 2.4**

### Property 5: Close icon consistency

*For all* bottom sheet implementations (ApplyLeavePage, ApplyClaimPage, ApplySupplyPage), the close icon should use Icons.close_rounded with size 24, white color, be positioned in the top-right corner of the header, and be wrapped in an IconButton with consistent padding.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.6**

### Property 6: Close icon dismissal behavior

*For any* bottom sheet, when the close icon is tapped, the bottom sheet should dismiss by calling Navigator.pop() and the sheet should no longer be visible.

**Validates: Requirements 3.5**

### Property 7: Version extraction from pubspec

*For any* valid version string in pubspec.yaml following the format "major.minor.patch+build" (e.g., "2.0.2+4"), the version extraction logic should correctly parse and extract the semantic version ("2.0.2") and build number (4).

**Validates: Requirements 4.2, 4.4**

### Property 8: Version synchronization round-trip

*For any* valid version string, when the version in pubspec.yaml is updated and a build is performed, the Android build configuration should automatically reflect the new versionName (semantic version) and versionCode (build number) without requiring manual edits to build.gradle.

**Validates: Requirements 4.3**

### Property 9: Version mapping correctness

*For any* version in pubspec.yaml with format "major.minor.patch+build", the build system should map the build number to Android versionCode and the semantic version string to Android versionName.

**Validates: Requirements 4.5, 4.6**

### Property 10: Invalid version format handling

*For any* invalid version format in pubspec.yaml (missing components, wrong separators, non-numeric values), the build process should fail with a descriptive error message indicating the format problem.

**Validates: Requirements 4.7**

### Property 11: Unsaved changes confirmation

*For any* bottom sheet with form fields, when the user attempts to dismiss the sheet by dragging down and any TextEditingController contains non-empty text, a confirmation dialog should be displayed before dismissal.

**Validates: Requirements 5.1, 5.2**

### Property 12: Confirmed dismissal cleanup

*For any* bottom sheet with unsaved form data, when the user confirms dismissal in the confirmation dialog, all form state should be cleared (all TextEditingControllers should have empty text).

**Validates: Requirements 5.3**

### Property 13: Cancelled dismissal preservation

*For any* bottom sheet with unsaved form data, when the user cancels dismissal in the confirmation dialog, the bottom sheet should remain open and all form data should remain unchanged.

**Validates: Requirements 5.4**

### Property 14: Successful submission bypass

*For any* bottom sheet, when the submit button is pressed and the submission succeeds, the bottom sheet should dismiss without showing the unsaved changes confirmation dialog.

**Validates: Requirements 5.5**

### Property 15: Close icon accessibility label

*For all* bottom sheet implementations, the close icon should have a semantic label of "Close" for screen readers.

**Validates: Requirements 6.1**

### Property 16: Header accessibility label

*For any* bottom sheet with title text, the header should have a semantic label that matches the title text for screen reader accessibility.

**Validates: Requirements 6.2**

### Property 17: Initial focus management

*For any* bottom sheet that opens, the focus should automatically move to the first form field in the bottom sheet.

**Validates: Requirements 6.3**

### Property 18: Logical tab order

*For any* bottom sheet with multiple form fields, pressing the tab key should move focus through the form fields in a logical top-to-bottom order.

**Validates: Requirements 6.5**



## Error Handling

### Bottom Sheet Navigation Errors

**Scenario**: Navigation observer fails to detect navigation event
- **Detection**: Bottom sheet remains open after navigation
- **Handling**: Implement fallback mechanism using RouteAware mixin on bottom sheet pages
- **Recovery**: Manual close button remains functional
- **Logging**: Log navigation observer registration failures

**Scenario**: Bottom sheet dismissal during async operation
- **Detection**: User attempts to close while form submission is in progress
- **Handling**: Disable close button and drag-to-dismiss during submission
- **Recovery**: Re-enable after operation completes or fails
- **User Feedback**: Show loading indicator and "Please wait" message

### Form State Management Errors

**Scenario**: TextEditingController disposed before unsaved changes check
- **Detection**: Null pointer or disposed controller exception
- **Handling**: Wrap controller access in try-catch, assume no unsaved changes if error
- **Recovery**: Allow dismissal to proceed
- **Logging**: Log controller lifecycle issues for debugging

**Scenario**: Confirmation dialog dismissed by system (e.g., app backgrounded)
- **Detection**: Dialog returns null result
- **Handling**: Treat null as "cancel" - keep bottom sheet open
- **Recovery**: User can retry dismissal
- **User Feedback**: Bottom sheet remains visible with data intact

### Version Management Errors

**Scenario**: pubspec.yaml file not found
- **Detection**: File read exception during build
- **Handling**: Fail build immediately with clear error message
- **Error Message**: "pubspec.yaml not found at expected location: ../../pubspec.yaml"
- **Recovery**: Developer must ensure pubspec.yaml exists in project root

**Scenario**: Invalid version format in pubspec.yaml
- **Detection**: Regex match fails or parsing exception
- **Handling**: Fail build with descriptive error
- **Error Message**: "Invalid version format in pubspec.yaml. Expected format: major.minor.patch+build (e.g., 2.0.2+4). Found: [actual value]"
- **Recovery**: Developer must correct version format

**Scenario**: Non-numeric build number
- **Detection**: Integer parsing exception
- **Handling**: Fail build with specific error
- **Error Message**: "Build number must be numeric. Found: [value]"
- **Recovery**: Developer must use numeric build number

**Scenario**: Missing version field in pubspec.yaml
- **Detection**: Regex match returns null
- **Handling**: Fail build with clear guidance
- **Error Message**: "No version field found in pubspec.yaml. Add version field in format: version: major.minor.patch+build"
- **Recovery**: Developer must add version field

### Accessibility Errors

**Scenario**: Focus node not available when bottom sheet opens
- **Detection**: FocusNode is null or not attached
- **Handling**: Skip automatic focus, allow manual focus
- **Recovery**: User can manually tap form field
- **Logging**: Log focus management issues

**Scenario**: Semantic labels not properly set
- **Detection**: Accessibility testing or screen reader testing
- **Handling**: Provide default semantic labels if custom ones missing
- **Recovery**: Use widget title or type as fallback label
- **User Impact**: Reduced but functional accessibility

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs using randomized testing

Both testing approaches are complementary and necessary. Unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across a wide range of inputs.

### Property-Based Testing

**Framework**: Use `flutter_test` with custom property-based testing utilities or integrate a Dart property-based testing library.

**Configuration**:
- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `// Feature: bottom-sheet-improvements-and-version-management, Property {number}: {property_text}`

**Property Test Examples**:

```dart
// Feature: bottom-sheet-improvements-and-version-management, Property 1: Auto-close on navigation
testProperty('Bottom sheets auto-close on any navigation event', iterations: 100, () {
  // Generate random bottom sheet type (Leave, Claim, Supply)
  // Generate random navigation event (push, pop, replace)
  // Open bottom sheet
  // Trigger navigation
  // Assert bottom sheet is closed
});

// Feature: bottom-sheet-improvements-and-version-management, Property 7: Version extraction from pubspec
testProperty('Version extraction correctly parses valid version strings', iterations: 100, () {
  // Generate random valid version (e.g., "1.2.3+45", "10.0.0+1")
  // Parse version string
  // Assert semantic version and build number extracted correctly
});

// Feature: bottom-sheet-improvements-and-version-management, Property 11: Unsaved changes confirmation
testProperty('Confirmation shown when dismissing with unsaved data', iterations: 100, () {
  // Generate random form data (some fields filled, some empty)
  // Open bottom sheet with form data
  // Attempt dismissal
  // If any field non-empty, assert confirmation dialog shown
  // If all fields empty, assert no confirmation dialog
});
```

### Unit Testing

**Focus Areas**:
- Specific navigation scenarios (tab change, back button, deep link)
- Edge cases (empty forms, all fields filled, mixed state)
- Error conditions (invalid version formats, missing files)
- Integration points (navigation observer registration, focus management)

**Unit Test Examples**:

```dart
testWidgets('Close icon has correct styling', (tester) async {
  await tester.pumpWidget(testApp);
  await openBottomSheet(tester, BottomSheetType.leave);
  
  final closeIcon = find.byIcon(Icons.close_rounded);
  expect(closeIcon, findsOneWidget);
  
  final iconWidget = tester.widget<Icon>(closeIcon);
  expect(iconWidget.size, 24);
  expect(iconWidget.color, Colors.white);
});

test('Invalid version format fails build', () {
  final invalidVersions = [
    'invalid',
    '1.2',
    '1.2.3',  // missing build number
    '1.2.3+',  // empty build number
    '1.2.3+abc',  // non-numeric build
  ];
  
  for (final version in invalidVersions) {
    expect(
      () => parseVersion(version),
      throwsA(isA<GradleException>()),
    );
  }
});

testWidgets('Successful submission dismisses without confirmation', (tester) async {
  await tester.pumpWidget(testApp);
  await openBottomSheet(tester, BottomSheetType.leave);
  
  // Fill form
  await fillLeaveForm(tester, hasData: true);
  
  // Mock successful API response
  mockSuccessfulSubmission();
  
  // Submit
  await tester.tap(find.text('Submit Leave Request'));
  await tester.pumpAndSettle();
  
  // Assert no confirmation dialog shown
  expect(find.text('Unsaved Changes'), findsNothing);
  
  // Assert bottom sheet dismissed
  expect(find.byType(FullscreenBottomSheet), findsNothing);
});
```

### Widget Testing

**Focus**: Visual consistency and layout verification

```dart
testWidgets('Bottom sheet occupies full screen height', (tester) async {
  await tester.pumpWidget(testApp);
  await openBottomSheet(tester, BottomSheetType.claim);
  
  final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
  final sheetHeight = tester.getSize(find.byType(FullscreenBottomSheet)).height;
  
  expect(sheetHeight, equals(screenHeight));
});

testWidgets('App header hidden when bottom sheet shown', (tester) async {
  await tester.pumpWidget(testApp);
  
  // Verify header visible initially
  expect(find.byType(AppBar), findsOneWidget);
  
  await openBottomSheet(tester, BottomSheetType.supply);
  await tester.pumpAndSettle();
  
  // Verify header not visible
  expect(find.byType(AppBar), findsNothing);
});
```

### Integration Testing

**Focus**: End-to-end workflows and cross-component interactions

```dart
testWidgets('Navigation from dashboard closes open bottom sheet', (tester) async {
  await tester.pumpWidget(testApp);
  
  // Navigate to leave page
  await navigateTo(tester, '/leave');
  
  // Open apply leave bottom sheet
  await tester.tap(find.text('Apply Leave'));
  await tester.pumpAndSettle();
  
  expect(find.byType(FullscreenBottomSheet), findsOneWidget);
  
  // Navigate to different page
  await navigateTo(tester, '/dashboard');
  await tester.pumpAndSettle();
  
  // Assert bottom sheet closed
  expect(find.byType(FullscreenBottomSheet), findsNothing);
});
```

### Build Testing

**Focus**: Version management automation

```bash
# Test version extraction
./gradlew :app:dependencies | grep version

# Test build with different version formats
echo "version: 1.0.0+1" > pubspec.yaml
./gradlew assembleDebug
# Verify versionCode=1, versionName="1.0.0"

echo "version: 2.5.3+42" > pubspec.yaml
./gradlew assembleDebug
# Verify versionCode=42, versionName="2.5.3"

# Test invalid version format
echo "version: invalid" > pubspec.yaml
./gradlew assembleDebug
# Expect build failure with descriptive error
```

### Accessibility Testing

**Focus**: Screen reader compatibility and keyboard navigation

```dart
testWidgets('Close icon has semantic label', (tester) async {
  await tester.pumpWidget(testApp);
  await openBottomSheet(tester, BottomSheetType.leave);
  
  final semantics = tester.getSemantics(find.byIcon(Icons.close_rounded));
  expect(semantics.label, 'Close');
});

testWidgets('Tab order follows logical sequence', (tester) async {
  await tester.pumpWidget(testApp);
  await openBottomSheet(tester, BottomSheetType.claim);
  
  // Simulate tab key presses
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(focusedWidget(), isA<DropdownButton>()); // Category
  
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(focusedWidget(), isA<DropdownButton>()); // Payment method
  
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(focusedWidget(), isA<GestureDetector>()); // Date picker
  
  // Continue through all fields...
});
```

### Test Coverage Goals

- **Line Coverage**: Minimum 85% for new/modified code
- **Branch Coverage**: Minimum 80% for conditional logic
- **Widget Coverage**: 100% for all bottom sheet implementations
- **Property Coverage**: All 18 correctness properties must have corresponding property tests
- **Error Path Coverage**: All error scenarios in Error Handling section must be tested

### Continuous Integration

**Pre-commit Checks**:
- Run unit tests
- Run widget tests
- Verify code formatting

**CI Pipeline**:
- Run full test suite (unit + widget + integration)
- Run property-based tests with 100 iterations
- Build Android APK to verify version extraction
- Run accessibility tests
- Generate coverage report
- Fail build if coverage below thresholds

**Manual Testing Checklist**:
- [ ] Open each bottom sheet type and verify full-screen display
- [ ] Navigate away from each open bottom sheet and verify auto-close
- [ ] Fill forms and attempt dismissal to verify unsaved changes prompt
- [ ] Submit forms successfully and verify no confirmation prompt
- [ ] Test with screen reader to verify semantic labels
- [ ] Test keyboard navigation through all form fields
- [ ] Update pubspec.yaml version and build to verify automatic sync
- [ ] Test invalid version formats and verify build failures

## Implementation Notes

### Navigation Observer Setup

The navigation observer must be registered in the main MaterialApp:

```dart
MaterialApp(
  navigatorObservers: [
    BottomSheetNavigationObserver(),
  ],
  // ...
);
```

### Full-Screen Configuration

To achieve full-screen bottom sheets with hidden app header:

1. Use `isScrollControlled: true` in showModalBottomSheet
2. Use `useRootNavigator: false` to show below app bar
3. Wrap content in SafeArea with `top: false` to extend to top
4. Set bottom sheet height to full screen height
5. The app bar will be naturally hidden by the full-screen bottom sheet overlay

### Version Format Requirements

The pubspec.yaml version must follow this exact format:
- Pattern: `major.minor.patch+build`
- Example: `2.0.2+4`
- All components must be numeric
- The `+` separator is required between semantic version and build number
- Build number must be monotonically increasing for Play Store uploads

### Gradle Version Extraction

The version extraction happens at build configuration time, not runtime. This means:
- Changes to pubspec.yaml require a rebuild to take effect
- The extraction is performed by Gradle during the configuration phase
- No runtime dependencies or overhead
- Build fails fast if version format is invalid

### Form State Detection

The unsaved changes detection uses a simple heuristic:
- Check all TextEditingController instances
- If any controller has non-empty text (after trimming), consider data unsaved
- This works for text fields but not for dropdowns, date pickers, or file uploads
- For comprehensive detection, pages should implement custom `hasUnsavedChanges` callback

### Accessibility Considerations

- Semantic labels should be concise and descriptive
- Focus management should be automatic but not disruptive
- Tab order should follow visual layout (top to bottom, left to right)
- Screen reader announcements should indicate when bottom sheet opens/closes
- All interactive elements must be keyboard accessible

