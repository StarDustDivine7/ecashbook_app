# Requirements Document

## Introduction

This document specifies requirements for improving bottom sheet behavior and centralizing version management in the Flutter employee management application. The improvements address UI consistency issues with bottom sheets (Apply Leave, Expenditure Claim, Supply Requisition) and eliminate manual version synchronization between pubspec.yaml and Android build configuration.

## Glossary

- **Bottom_Sheet**: A modal UI component displayed from the bottom of the screen using showModalBottomSheet()
- **Navigation_Event**: User action that changes the current screen route in the application
- **App_Header**: The AppBar widget displayed at the top of the application screens
- **Version_Manager**: The build system component responsible for reading and applying version information
- **Pubspec_File**: The pubspec.yaml file containing Flutter project metadata and version
- **Build_Gradle**: The android/app/build.gradle file containing Android build configuration
- **Bottom_Sheet_Helper**: The showFullscreenBottomSheet() function in lib/shared/fullscreen_bottom_sheet.dart
- **Close_Icon**: The IconButton with Icons.close_rounded displayed in the bottom sheet header

## Requirements

### Requirement 1: Auto-Close Bottom Sheets on Navigation

**User Story:** As a user, I want bottom sheets to automatically close when I navigate to a different screen, so that I don't encounter UI conflicts or overlapping content.

#### Acceptance Criteria

1. WHEN a Bottom_Sheet is open AND a Navigation_Event occurs, THE Bottom_Sheet_Helper SHALL close the Bottom_Sheet before the navigation completes
2. THE Bottom_Sheet_Helper SHALL detect navigation events using route observers or navigation listeners
3. WHEN the Bottom_Sheet closes due to navigation, THE Bottom_Sheet_Helper SHALL clean up any form state or controllers
4. FOR ALL bottom sheet types (Apply Leave, Expenditure Claim, Supply Requisition), THE auto-close behavior SHALL apply consistently

### Requirement 2: Full-Screen Bottom Sheet Display

**User Story:** As a user, I want bottom sheets to use the full screen height and hide the app header, so that I have maximum space for viewing and filling out forms.

#### Acceptance Criteria

1. WHEN a Bottom_Sheet is displayed, THE Bottom_Sheet SHALL occupy the full screen height from top to bottom
2. WHEN a Bottom_Sheet is displayed, THE App_Header SHALL be hidden from view
3. THE Bottom_Sheet SHALL use SafeArea to respect system UI elements (status bar, notches)
4. WHEN the Bottom_Sheet is dismissed, THE App_Header SHALL reappear
5. THE Bottom_Sheet SHALL maintain isScrollControlled: true to enable full-screen behavior

### Requirement 3: Consistent Close Icon Styling

**User Story:** As a user, I want all bottom sheets to have the same close button appearance and position, so that the interface feels consistent and predictable.

#### Acceptance Criteria

1. THE Close_Icon SHALL use Icons.close_rounded with size 24 across all bottom sheets
2. THE Close_Icon SHALL be positioned in the top-right corner of the bottom sheet header
3. THE Close_Icon SHALL use white color against the gradient header background
4. THE Close_Icon SHALL be wrapped in an IconButton with consistent padding
5. WHEN the Close_Icon is tapped, THE Bottom_Sheet SHALL dismiss with Navigator.pop()
6. FOR ALL bottom sheet pages (ApplyLeavePage, ApplyClaimPage, ApplySupplyPage), THE Close_Icon styling SHALL match exactly

### Requirement 4: Centralized Version Management

**User Story:** As a developer, I want the app version to be managed from a single source, so that I don't have to manually update version numbers in multiple files and risk inconsistencies.

#### Acceptance Criteria

1. THE Version_Manager SHALL read version information from the Pubspec_File as the single source of truth
2. THE Build_Gradle SHALL extract versionCode and versionName from the Pubspec_File automatically during build
3. WHEN the version in Pubspec_File is updated, THE Build_Gradle SHALL reflect the new version without manual edits
4. THE Version_Manager SHALL parse the Pubspec_File version format (major.minor.patch+build) correctly
5. THE Build_Gradle SHALL map the build number from Pubspec_File to Android versionCode
6. THE Build_Gradle SHALL map the semantic version from Pubspec_File to Android versionName
7. IF the Pubspec_File version format is invalid, THEN THE Version_Manager SHALL fail the build with a descriptive error message

### Requirement 5: Bottom Sheet State Management

**User Story:** As a user, I want my form inputs to be preserved when I accidentally dismiss a bottom sheet, so that I don't lose my work.

#### Acceptance Criteria

1. WHEN a Bottom_Sheet is dismissed by dragging down, THE Bottom_Sheet SHALL prompt for confirmation if form fields contain unsaved data
2. THE Bottom_Sheet SHALL detect unsaved data by checking if any TextEditingController has non-empty text
3. WHEN the user confirms dismissal, THE Bottom_Sheet SHALL clear all form state
4. WHEN the user cancels dismissal, THE Bottom_Sheet SHALL remain open with form data intact
5. WHEN the submit button is pressed successfully, THE Bottom_Sheet SHALL dismiss without confirmation

### Requirement 6: Bottom Sheet Accessibility

**User Story:** As a user with accessibility needs, I want bottom sheets to be navigable and usable with assistive technologies, so that I can access all application features.

#### Acceptance Criteria

1. THE Close_Icon SHALL have a semantic label "Close" for screen readers
2. THE Bottom_Sheet header SHALL have a semantic label matching the title text
3. WHEN a Bottom_Sheet opens, THE focus SHALL move to the first form field
4. THE Bottom_Sheet SHALL support keyboard navigation for all interactive elements
5. THE Bottom_Sheet SHALL maintain a logical tab order through form fields
