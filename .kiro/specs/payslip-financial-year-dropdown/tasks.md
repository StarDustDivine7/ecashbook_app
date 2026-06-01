# Implementation Plan: Payslip Financial Year Dropdown

## Overview

This implementation modifies the payslip page's year selection dropdown to display financial years (e.g., "2025-2026") instead of individual calendar years (e.g., "2025"). The change is isolated to the UI presentation layer while maintaining full backward compatibility with existing API integration.

## Tasks

- [ ] 1. Modify the years getter to generate financial year strings
  - Update the `years` getter in `_PayslipPageState` to generate financial year strings in format "YYYY-YYYY+1"
  - Filter to only include financial years where starting year >= 2020
  - Use `whereType<String>()` to handle null filtering for invalid years
  - _Requirements: 1.1, 1.2, 1.3_

- [ ]* 1.1 Write property test for financial year format consistency
  - **Property 1: Financial Year Format Consistency**
  - **Validates: Requirements 1.1**

- [ ]* 1.2 Write property test for financial year list bounds
  - **Property 2: Financial Year List Bounds**
  - **Validates: Requirements 1.2, 1.3, 5.1**

- [ ] 2. Implement starting year extraction method
  - Create `_extractStartingYear()` method in `_PayslipPageState` class
  - Parse financial year string (format "YYYY-YYYY+1") to extract starting year
  - Return empty string for invalid formats to prevent API calls
  - Handle edge cases: empty strings, invalid formats, non-numeric values
  - _Requirements: 2.1, 2.2, 5.2_

- [ ]* 2.1 Write property test for starting year extraction round trip
  - **Property 3: Starting Year Extraction Round Trip**
  - **Validates: Requirements 2.1, 2.4, 3.2, 3.3**

- [ ]* 2.2 Write property test for invalid input handling
  - **Property 6: Invalid Input Handling**
  - **Validates: Requirements 5.2, 5.4**

- [ ] 3. Update year dropdown onChanged callback
  - Modify the year dropdown's `onChanged` callback in `_buildDropdown()` method
  - Call `_extractStartingYear()` to parse selected financial year before storing in `selectedYear` state
  - Maintain existing state clearing behavior for `_payslipVisible`, `_companyInfo`, `_errorMessage`, `_errorStatus`
  - _Requirements: 2.3, 4.2, 4.3_

- [ ]* 3.1 Write property test for state storage after selection
  - **Property 4: State Storage After Selection**
  - **Validates: Requirements 2.3**

- [ ]* 3.2 Write property test for state clearing on selection change
  - **Property 5: State Clearing on Selection Change**
  - **Validates: Requirements 4.2, 4.3**

- [ ] 4. Checkpoint - Verify dropdown functionality
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 5. Write unit tests for specific examples
  - Test year 2026 generates correct financial year list (Requirements 1.4)
  - Test extraction of "2025" from "2025-2026" (Requirements 2.2)
  - Test boundary year 2020 is included in list
  - Test year 2019 is excluded from list
  - Test dropdown hint text displays "Select Year" when no selection (Requirements 4.1)

- [ ]* 6. Write integration test for end-to-end flow
  - Test financial year selection triggers correct API call with proper format
  - Verify `_buildFinancialYear()` receives extracted starting year
  - Verify API receives financial year in format "YYYY-YYYY+1"
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 7. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The implementation maintains full backward compatibility with existing API integration
- No changes required to `_buildFinancialYear()` method or API service layer
- All property tests should run with minimum 100 iterations
- Focus on UI presentation change only - business logic remains unchanged
