# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Fault Condition** - Dropdown Visibility in Dark Mode
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Manual Testing Approach**: Since this is a visual bug, use manual testing on device/emulator in dark mode
  - Test that dropdowns display with readable contrast in dark mode (from Fault Condition in design)
  - Test all 5 affected dropdowns: Task Status, Leave Type, Expenditure Claim, Supply Request, Payslip Filter
  - The test assertions should verify: background color uses Theme.of(context).colorScheme.surface AND text color uses Theme.of(context).colorScheme.onSurface
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (dropdowns show black text on black background in dark mode)
  - Document counterexamples found: which dropdowns are invisible, what colors are being used
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Light Mode Appearance and Functionality
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for light mode rendering and dropdown interactions
  - Write tests capturing observed behavior patterns from Preservation Requirements:
    - Light mode dropdowns have white backgrounds and dark text
    - Dropdown selection triggers onChanged callbacks correctly
    - Dropdown state updates correctly when values change
    - Visual design (borders, shadows, padding) remains unchanged
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 2.2, 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix dropdown dark mode visibility

  - [x] 3.1 Modify lib/features/tasks/task_view.dart
    - Replace `dropdownColor: TaskViewPage._cardWhite` with `dropdownColor: Theme.of(context).colorScheme.surface`
    - Replace hardcoded text colors with `Theme.of(context).colorScheme.onSurface`
    - Replace hardcoded icon colors with `Theme.of(context).colorScheme.onSurface`
    - _Bug_Condition: isBugCondition(input) where input.themeMode == ThemeMode.dark AND input.dropdownColor IN [hardcodedLightColors]_
    - _Expected_Behavior: dropdowns use Theme.of(context).colorScheme.surface for background and colorScheme.onSurface for text_
    - _Preservation: Light mode appearance (white background, dark text) and all dropdown functionality unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Modify lib/features/leave/apply_leave.dart
    - Replace `dropdownColor: _surfaceColor` with `dropdownColor: Theme.of(context).colorScheme.surface`
    - Replace `TextStyle(color: _textDark)` with `TextStyle(color: Theme.of(context).colorScheme.onSurface)`
    - Replace hint text colors with `Theme.of(context).colorScheme.onSurface.withOpacity(0.6)`
    - _Bug_Condition: isBugCondition(input) where input.themeMode == ThemeMode.dark AND input.dropdownColor IN [hardcodedLightColors]_
    - _Expected_Behavior: dropdowns use Theme.of(context).colorScheme.surface for background and colorScheme.onSurface for text_
    - _Preservation: Light mode appearance (white background, dark text) and all dropdown functionality unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.3 Modify lib/features/expenditure/apply_claim.dart
    - Replace `dropdownColor: _surface` with `dropdownColor: Theme.of(context).colorScheme.surface`
    - Replace `TextStyle(color: _textDark)` with `TextStyle(color: Theme.of(context).colorScheme.onSurface)`
    - Replace hint text colors with `Theme.of(context).colorScheme.onSurface.withOpacity(0.6)`
    - _Bug_Condition: isBugCondition(input) where input.themeMode == ThemeMode.dark AND input.dropdownColor IN [hardcodedLightColors]_
    - _Expected_Behavior: dropdowns use Theme.of(context).colorScheme.surface for background and colorScheme.onSurface for text_
    - _Preservation: Light mode appearance (white background, dark text) and all dropdown functionality unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.4 Modify lib/features/supply/apply_supply.dart
    - Replace hardcoded dropdownColor with `dropdownColor: Theme.of(context).colorScheme.surface`
    - Replace hardcoded text colors with `Theme.of(context).colorScheme.onSurface`
    - Replace hint text colors with `Theme.of(context).colorScheme.onSurface.withOpacity(0.6)`
    - _Bug_Condition: isBugCondition(input) where input.themeMode == ThemeMode.dark AND input.dropdownColor IN [hardcodedLightColors]_
    - _Expected_Behavior: dropdowns use Theme.of(context).colorScheme.surface for background and colorScheme.onSurface for text_
    - _Preservation: Light mode appearance (white background, dark text) and all dropdown functionality unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.5 Modify lib/features/payslip/payslip_page.dart
    - Replace hardcoded text colors with `Theme.of(context).colorScheme.onSurface`
    - Replace `_textGray` with `Theme.of(context).colorScheme.onSurface.withOpacity(0.6)` for hint text
    - Ensure dropdown background uses `Theme.of(context).colorScheme.surface`
    - _Bug_Condition: isBugCondition(input) where input.themeMode == ThemeMode.dark AND input.dropdownColor IN [hardcodedLightColors]_
    - _Expected_Behavior: dropdowns use Theme.of(context).colorScheme.surface for background and colorScheme.onSurface for text_
    - _Preservation: Light mode appearance (white background, dark text) and all dropdown functionality unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.6 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Dropdown Visibility in Dark Mode
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1 on device/emulator in dark mode
    - Verify all 5 dropdowns now display with readable contrast (light text on dark background)
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: 2.1, 2.3, 2.4_

  - [x] 3.7 Verify preservation tests still pass
    - **Property 2: Preservation** - Light Mode Appearance and Functionality
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - Verify light mode appearance unchanged (white backgrounds, dark text)
    - Verify dropdown functionality unchanged (selection, callbacks, state updates)
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)

- [x] 4. Checkpoint - Ensure all tests pass
  - Verify all dropdowns are readable in dark mode
  - Verify all dropdowns maintain original appearance in light mode
  - Verify all dropdown functionality works correctly (selection, callbacks, state)
  - Ensure all tests pass, ask the user if questions arise
