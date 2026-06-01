# Bugfix Requirements Document

## Introduction

This document addresses a critical visibility issue in the eCashbook Flutter application where dropdown menus become unreadable in dark mode. When the mobile device is set to dark mode, dropdown menus display with a black background and black text, rendering the text invisible to users. This affects all dropdown menus throughout the application and severely impacts usability for users who prefer or require dark mode.

The fix will ensure that dropdown menus have appropriate background and text colors that maintain readability in both light and dark theme modes.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the device is in dark mode AND a user opens any dropdown menu THEN the system displays the dropdown with a black background and black text, making the text invisible

1.2 WHEN the device is in dark mode AND a user interacts with dropdown menu items THEN the system renders text that is unreadable due to insufficient contrast between background and text colors

1.3 WHEN dropdowns have hardcoded light theme colors (e.g., `dropdownColor: _cardWhite`) AND the device is in dark mode THEN the system fails to adapt the dropdown styling to the active theme

### Expected Behavior (Correct)

2.1 WHEN the device is in dark mode AND a user opens any dropdown menu THEN the system SHALL display the dropdown with an appropriate dark theme background color (e.g., Color(0xFF1E1E1E) or similar) and light-colored text that ensures readability

2.2 WHEN the device is in light mode AND a user opens any dropdown menu THEN the system SHALL display the dropdown with an appropriate light theme background color (e.g., white) and dark-colored text that ensures readability

2.3 WHEN dropdown menus are rendered THEN the system SHALL use theme-aware colors that automatically adapt to the current theme mode (light or dark) without hardcoded color values

2.4 WHEN dropdown menu items are displayed THEN the system SHALL ensure sufficient contrast ratio between background and text colors to meet accessibility standards in both theme modes

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the device is in light mode AND dropdowns are currently working correctly THEN the system SHALL CONTINUE TO display dropdowns with white backgrounds and dark text with proper visibility

3.2 WHEN users interact with dropdown menus (opening, selecting items, closing) THEN the system SHALL CONTINUE TO maintain all existing functional behavior including selection handling, state management, and callbacks

3.3 WHEN dropdown menus display icons, borders, and other visual elements THEN the system SHALL CONTINUE TO render these elements correctly in both theme modes

3.4 WHEN the app theme is configured in `lib/core/theme/app_theme.dart` THEN the system SHALL CONTINUE TO respect all other theme settings for cards, buttons, inputs, and other UI components without modification
