# Dropdown Dark Mode Visibility Fix Design

## Overview

This design addresses a critical visibility bug where dropdown menus in the eCashbook Flutter application become unreadable in dark mode due to hardcoded light theme colors. The bug manifests as black text on black backgrounds when the device is in dark mode, making dropdown content invisible to users.

The fix will replace hardcoded color values with theme-aware colors that automatically adapt to the current theme mode (light or dark). This ensures dropdowns remain readable in both theme modes while preserving all existing functionality and visual design in light mode.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when dropdowns are rendered in dark mode with hardcoded light theme colors
- **Property (P)**: The desired behavior - dropdowns should display with appropriate background and text colors that ensure readability in the current theme mode
- **Preservation**: Existing dropdown functionality (selection, callbacks, state management) and light mode appearance that must remain unchanged
- **dropdownColor**: The Flutter DropdownButton property that sets the background color of the dropdown menu overlay
- **Theme.of(context)**: Flutter's theme access mechanism that provides the current active theme (light or dark)
- **ColorScheme**: Flutter's color system that defines theme-aware colors for surfaces, backgrounds, and text
- **Hardcoded Colors**: Static color constants like `_cardWhite`, `_textDark`, `_surfaceColor` that don't adapt to theme changes

## Bug Details

### Fault Condition

The bug manifests when the device is in dark mode and a user opens any dropdown menu. The dropdown displays with inappropriate colors because the code uses hardcoded light theme color constants that don't adapt to the active theme mode.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type DropdownRenderContext
  OUTPUT: boolean
  
  RETURN input.themeMode == ThemeMode.dark
         AND input.dropdownColor IN [hardcodedLightColors]
         AND input.textColor IN [hardcodedDarkTextColors]
         AND NOT isThemeAware(input.dropdownColor)
END FUNCTION

WHERE:
  hardcodedLightColors = [Colors.white, Color(0xFFF8FAFC), _cardWhite, _surfaceColor]
  hardcodedDarkTextColors = [Color(0xFF0F172A), _textDark, Colors.black87]
```

### Examples

- **Task Status Dropdown**: In `lib/features/tasks/task_view.dart` line 275, `dropdownColor: TaskViewPage._cardWhite` forces white background in dark mode, combined with dark text colors, making text invisible
- **Leave Type Dropdown**: In `lib/features/leave/apply_leave.dart` lines 186-199, uses `_surfaceColor` (light gray) background with `_textDark` (nearly black) text, causing poor contrast in dark mode
- **Expenditure Claim Dropdown**: In `lib/features/expenditure/apply_claim.dart` lines 265-269, uses `_surface` and `_textDark` constants that don't adapt to dark mode
- **Payslip Filter Dropdown**: In `lib/features/payslip/payslip_page.dart` line 456, uses `_textGray` which may not provide sufficient contrast in dark mode

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Dropdown selection functionality must continue to work exactly as before (onChanged callbacks, state updates)
- Dropdown visual design in light mode must remain unchanged (white backgrounds, dark text, existing borders and shadows)
- All dropdown menu items, icons, and decorative elements must continue to render correctly
- Dropdown positioning, animation, and interaction behavior must remain unchanged

**Scope:**
All inputs and interactions that do NOT involve theme mode changes should be completely unaffected by this fix. This includes:
- Mouse/touch interactions with dropdowns (opening, selecting, closing)
- Dropdown state management and value updates
- Dropdown styling properties (borders, shadows, padding, border radius)
- Other UI components (cards, buttons, inputs) that already use theme-aware colors

## Hypothesized Root Cause

Based on the code analysis, the root causes are:

1. **Hardcoded dropdownColor Property**: The `dropdownColor` property in DropdownButton widgets is set to hardcoded light theme constants like `_cardWhite` or `Colors.white`, which don't adapt when the theme changes to dark mode

2. **Hardcoded Text Colors in DropdownMenuItem**: Text styles within dropdown items use hardcoded dark color constants like `_textDark` (Color(0xFF0F172A)) that remain dark even in dark mode, creating black-on-black text

3. **Static Color Constants**: Multiple files define static color constants (`_cardWhite`, `_surfaceColor`, `_textDark`) that are used throughout the UI without checking the current theme mode

4. **Missing Theme Context Usage**: The dropdown implementations don't use `Theme.of(context).colorScheme` to access theme-aware colors that automatically adapt to light/dark mode

## Correctness Properties

Property 1: Fault Condition - Dropdown Visibility in Dark Mode

_For any_ dropdown widget rendered when the device theme mode is dark, the fixed implementation SHALL use theme-aware background colors (from Theme.of(context).colorScheme.surface) and theme-aware text colors (from Theme.of(context).colorScheme.onSurface) that provide sufficient contrast for readability.

**Validates: Requirements 2.1, 2.3, 2.4**

Property 2: Preservation - Light Mode Appearance and Functionality

_For any_ dropdown widget rendered when the device theme mode is light OR any dropdown interaction (selection, state update, callback), the fixed implementation SHALL produce exactly the same visual appearance and functional behavior as the original code, preserving white backgrounds, dark text, and all existing functionality.

**Validates: Requirements 2.2, 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**Files to Modify**:
1. `lib/features/tasks/task_view.dart`
2. `lib/features/leave/apply_leave.dart`
3. `lib/features/expenditure/apply_claim.dart`
4. `lib/features/supply/apply_supply.dart`
5. `lib/features/payslip/payslip_page.dart`

**Specific Changes**:

1. **Replace Hardcoded dropdownColor**:
   - Change: `dropdownColor: TaskViewPage._cardWhite`
   - To: `dropdownColor: Theme.of(context).colorScheme.surface`
   - Rationale: `colorScheme.surface` automatically provides white in light mode and Color(0xFF1E1E1E) in dark mode (as defined in app_theme.dart)

2. **Replace Hardcoded Text Colors in DropdownMenuItem**:
   - Change: `TextStyle(color: _textDark)` or `TextStyle(color: Color(0xFF0F172A))`
   - To: `TextStyle(color: Theme.of(context).colorScheme.onSurface)`
   - Rationale: `colorScheme.onSurface` provides appropriate text color for the current theme's surface color

3. **Replace Hardcoded Hint Text Colors**:
   - Change: `TextStyle(color: _textLight)` or `TextStyle(color: _textGray)`
   - To: `TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))`
   - Rationale: Maintains the lighter appearance for hint text while adapting to theme

4. **Replace Hardcoded Icon Colors** (if applicable):
   - Change: `Icon(Icons.keyboard_arrow_down_rounded, color: _textDark)`
   - To: `Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface)`
   - Rationale: Icons should match the text color for consistency

5. **Verify Container Background Colors**:
   - Ensure dropdown container decorations also use theme-aware colors
   - Change: `color: _surfaceColor` or `color: _cardWhite`
   - To: `color: Theme.of(context).colorScheme.surface`

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code in dark mode, then verify the fix works correctly in both theme modes and preserves existing behavior.

### Exploratory Fault Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Manually test the application on a device or emulator with dark mode enabled. Open each dropdown menu and observe the visibility of text and background colors. Document specific instances where text is invisible or has insufficient contrast. Run these observations on the UNFIXED code to confirm the bug manifestation.

**Test Cases**:
1. **Task Status Dropdown Test**: Open task details page in dark mode, click status dropdown (will show invisible text on unfixed code)
2. **Leave Type Dropdown Test**: Open apply leave page in dark mode, click leave type dropdown (will show invisible text on unfixed code)
3. **Expenditure Claim Dropdown Test**: Open apply claim page in dark mode, click claim type dropdown (will show invisible text on unfixed code)
4. **Payslip Filter Dropdown Test**: Open payslip page in dark mode, click month/year filter dropdown (will show poor contrast on unfixed code)

**Expected Counterexamples**:
- Dropdown menus display with black/dark backgrounds and black/dark text, making text invisible
- Possible causes: hardcoded `dropdownColor` property, hardcoded text colors in TextStyle, missing theme context usage

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (dark mode enabled), the fixed dropdowns produce the expected behavior (readable text with sufficient contrast).

**Pseudocode:**
```
FOR ALL dropdown WHERE isBugCondition(dropdown) DO
  result := renderDropdown_fixed(dropdown, ThemeMode.dark)
  ASSERT hasReadableContrast(result.backgroundColor, result.textColor)
  ASSERT result.backgroundColor == Theme.dark.colorScheme.surface
  ASSERT result.textColor == Theme.dark.colorScheme.onSurface
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (light mode enabled OR functional interactions), the fixed dropdowns produce the same result as the original implementation.

**Pseudocode:**
```
FOR ALL dropdown WHERE NOT isBugCondition(dropdown) DO
  ASSERT renderDropdown_original(dropdown, ThemeMode.light) == renderDropdown_fixed(dropdown, ThemeMode.light)
  ASSERT dropdown_original.onChanged == dropdown_fixed.onChanged
  ASSERT dropdown_original.functionality == dropdown_fixed.functionality
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across different dropdown configurations
- It catches edge cases that manual testing might miss (different item counts, different value types, edge cases in selection)
- It provides strong guarantees that behavior is unchanged for all light mode scenarios and functional interactions

**Test Plan**: Observe behavior on UNFIXED code first in light mode to document the expected appearance, then write property-based tests capturing that behavior. Verify that all dropdown interactions (opening, selecting, closing) continue to work identically.

**Test Cases**:
1. **Light Mode Appearance Preservation**: Observe that dropdowns in light mode have white backgrounds and dark text on unfixed code, then verify this continues after fix
2. **Selection Functionality Preservation**: Observe that selecting dropdown items triggers onChanged callbacks correctly on unfixed code, then verify this continues after fix
3. **Dropdown State Preservation**: Observe that dropdown state updates correctly when values change on unfixed code, then verify this continues after fix
4. **Visual Design Preservation**: Observe that borders, shadows, padding, and border radius remain unchanged on unfixed code, then verify this continues after fix

### Unit Tests

- Test dropdown rendering in light mode with theme-aware colors (should match original white background)
- Test dropdown rendering in dark mode with theme-aware colors (should have dark background and light text)
- Test that dropdown text colors provide sufficient contrast in both modes
- Test edge cases (empty dropdowns, single item dropdowns, very long item text)

### Property-Based Tests

- Generate random dropdown configurations (different item counts, different value types) and verify they render correctly in both theme modes
- Generate random theme mode switches and verify dropdowns adapt correctly without losing state
- Test that all dropdown interactions (selection, state updates) work identically across many scenarios in both theme modes

### Integration Tests

- Test full user flow: navigate to each page with dropdowns, switch device to dark mode, verify all dropdowns are readable
- Test theme switching: start in light mode, open dropdown, switch to dark mode, verify dropdown updates correctly
- Test that other UI components (cards, buttons, inputs) remain unaffected by dropdown color changes
