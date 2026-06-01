# Implementation Plan: Bottom Sheet Improvements and Version Management

## Overview

This implementation plan addresses two critical improvements: enhancing bottom sheet behavior with auto-close on navigation, full-screen display, and consistent styling; and centralizing version management by making pubspec.yaml the single source of truth. The implementation follows a bottom-up approach, starting with core infrastructure, then updating individual bottom sheet pages, and finally implementing version management automation.

## Tasks

- [ ] 1. Enhance core bottom sheet infrastructure
  - [ ] 1.1 Create BottomSheetNavigationObserver class
    - Implement NavigatorObserver with didPush, didPop, and didReplace overrides
    - Add callback mechanism to notify when navigation is detected
    - Distinguish between bottom sheet dismissal and actual navigation events
    - _Requirements: 1.2_

  - [ ] 1.2 Create UnsavedChangesDetector mixin
    - Implement hasUnsavedFormData() method to check TextEditingController states
    - Implement showUnsavedChangesDialog() to display confirmation dialog
    - Return user's decision (confirm or cancel dismissal)
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [ ] 1.3 Enhance FullscreenBottomSheet widget
    - Add properties: title, child, onClose, showDragHandle, enableUnsavedChangesCheck, hasUnsavedChanges
    - Add accessibility properties: semanticLabel, initialFocusNode
    - Implement full-screen layout with SafeArea
    - Render consistent header with gradient background
    - Display standardized close icon (Icons.close_rounded, size 24, white color) in top-right
    - Handle unsaved changes confirmation when closing
    - Support focus management for accessibility
    - _Requirements: 2.1, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 6.1, 6.2, 6.3_

  - [ ]* 1.4 Write property test for FullscreenBottomSheet widget
    - **Property 3: Full-screen height occupation**
    - **Property 5: Close icon consistency**
    - **Validates: Requirements 2.1, 3.1, 3.2, 3.3, 3.4, 3.6**

  - [ ] 1.5 Enhance showFullscreenBottomSheet() helper function
    - Add parameters: context, title, child, isScrollControlled, useRootNavigator
    - Add parameters: enableUnsavedChangesCheck, hasUnsavedChanges, semanticLabel, initialFocusNode
    - Add onNavigationDetected callback parameter
    - Configure and display bottom sheet with full-screen behavior
    - Set up navigation observer if auto-close is needed
    - Configure unsaved changes detection
    - Apply accessibility settings
    - Return result when bottom sheet is dismissed
    - _Requirements: 1.1, 1.3, 2.5, 5.5, 6.4, 6.5_

  - [ ]* 1.6 Write property test for navigation observer
    - **Property 1: Auto-close on navigation**
    - **Property 2: Navigation observer registration**
    - **Validates: Requirements 1.1, 1.2, 1.4**

  - [ ]* 1.7 Write property test for unsaved changes detection
    - **Property 11: Unsaved changes confirmation**
    - **Property 12: Confirmed dismissal cleanup**
    - **Property 13: Cancelled dismissal preservation**
    - **Property 14: Successful submission bypass**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**

- [ ] 2. Checkpoint - Verify core infrastructure
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 3. Update Apply Leave bottom sheet
  - [ ] 3.1 Refactor ApplyLeavePage to use enhanced FullscreenBottomSheet
    - Replace custom header with FullscreenBottomSheet widget
    - Remove custom close icon implementation
    - Configure unsaved changes detection for leave form fields
    - Set up navigation observer for auto-close
    - Add semantic labels for accessibility
    - Configure initial focus on first form field
    - _Requirements: 1.4, 2.1, 2.2, 2.4, 3.6, 5.1, 6.1, 6.2, 6.3, 6.5_

  - [ ]* 3.2 Write unit tests for ApplyLeavePage
    - Test close icon styling and position
    - Test form state preservation on cancel dismissal
    - Test form state cleanup on confirmed dismissal
    - Test successful submission without confirmation
    - Test accessibility labels and focus management
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3_

- [ ] 4. Update Apply Claim bottom sheet
  - [ ] 4.1 Refactor ApplyClaimPage to use enhanced FullscreenBottomSheet
    - Replace custom header with FullscreenBottomSheet widget
    - Remove custom close icon implementation
    - Configure unsaved changes detection for claim form fields
    - Set up navigation observer for auto-close
    - Add semantic labels for accessibility
    - Configure initial focus on first form field
    - _Requirements: 1.4, 2.1, 2.2, 2.4, 3.6, 5.1, 6.1, 6.2, 6.3, 6.5_

  - [ ]* 4.2 Write unit tests for ApplyClaimPage
    - Test close icon styling and position
    - Test form state preservation on cancel dismissal
    - Test form state cleanup on confirmed dismissal
    - Test successful submission without confirmation
    - Test accessibility labels and focus management
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3_

- [ ] 5. Update Apply Supply bottom sheet
  - [ ] 5.1 Refactor ApplySupplyPage to use enhanced FullscreenBottomSheet
    - Replace custom header with FullscreenBottomSheet widget
    - Remove custom close icon implementation
    - Configure unsaved changes detection for supply form fields
    - Set up navigation observer for auto-close
    - Add semantic labels for accessibility
    - Configure initial focus on first form field
    - _Requirements: 1.4, 2.1, 2.2, 2.4, 3.6, 5.1, 6.1, 6.2, 6.3, 6.5_

  - [ ]* 5.2 Write unit tests for ApplySupplyPage
    - Test close icon styling and position
    - Test form state preservation on cancel dismissal
    - Test form state cleanup on confirmed dismissal
    - Test successful submission without confirmation
    - Test accessibility labels and focus management
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3_

- [ ] 6. Checkpoint - Verify all bottom sheets updated
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Register navigation observer in main app
  - [ ] 7.1 Update MaterialApp in main.dart
    - Add BottomSheetNavigationObserver to navigatorObservers list
    - Ensure observer is properly initialized
    - _Requirements: 1.2_

  - [ ]* 7.2 Write integration test for navigation observer registration
    - Test that observer receives navigation events
    - Test that bottom sheets close on navigation
    - Test across all three bottom sheet types
    - _Requirements: 1.1, 1.2, 1.4_

- [ ] 8. Implement centralized version management
  - [ ] 8.1 Create version extraction function in build.gradle
    - Implement getPubspecVersion() function to read pubspec.yaml
    - Parse version format (major.minor.patch+build) using regex
    - Extract semantic version (major.minor.patch) for versionName
    - Extract build number for versionCode
    - Validate version format and fail build with descriptive error if invalid
    - _Requirements: 4.1, 4.2, 4.4, 4.7_

  - [ ] 8.2 Update Android build configuration to use extracted version
    - Call getPubspecVersion() in build.gradle
    - Set versionCode to extracted build number
    - Set versionName to extracted semantic version
    - Remove hardcoded version values
    - _Requirements: 4.3, 4.5, 4.6_

  - [ ]* 8.3 Write property test for version extraction
    - **Property 7: Version extraction from pubspec**
    - **Property 8: Version synchronization round-trip**
    - **Property 9: Version mapping correctness**
    - **Property 10: Invalid version format handling**
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.5, 4.6, 4.7**

  - [ ]* 8.4 Write unit tests for version management
    - Test valid version formats (e.g., "2.0.2+4", "1.0.0+1", "10.5.3+42")
    - Test invalid version formats (missing components, wrong separators, non-numeric)
    - Test build failure with descriptive error messages
    - Test version synchronization after pubspec.yaml update
    - _Requirements: 4.2, 4.4, 4.7_

- [ ] 9. Checkpoint - Verify version management
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 10. Write property test for app header visibility
  - **Property 4: App header visibility toggle**
  - **Validates: Requirements 2.2, 2.4**

- [ ]* 11. Write property test for close icon dismissal
  - **Property 6: Close icon dismissal behavior**
  - **Validates: Requirements 3.5**

- [ ]* 12. Write property test for accessibility
  - **Property 15: Close icon accessibility label**
  - **Property 16: Header accessibility label**
  - **Property 17: Initial focus management**
  - **Property 18: Logical tab order**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.5**

- [ ]* 13. Write integration tests for end-to-end workflows
  - Test navigation from dashboard closes open bottom sheet
  - Test bottom sheet full-screen display with hidden app header
  - Test unsaved changes workflow (fill form, dismiss, confirm/cancel)
  - Test successful submission workflow (fill form, submit, auto-dismiss)
  - Test keyboard navigation through all form fields
  - _Requirements: 1.1, 1.4, 2.1, 2.2, 2.4, 5.1, 5.2, 5.3, 5.4, 5.5, 6.4, 6.5_

- [ ] 14. Final checkpoint - Comprehensive verification
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The implementation follows a bottom-up approach: core infrastructure → individual pages → integration
- Version management is independent and can be implemented in parallel with bottom sheet improvements
