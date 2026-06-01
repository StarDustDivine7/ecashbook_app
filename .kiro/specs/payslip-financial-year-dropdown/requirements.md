# Requirements Document

## Introduction

This feature modifies the payslip page's year selection dropdown to display financial years (e.g., "2025-2026", "2024-2025") instead of individual calendar years (e.g., "2025", "2024"). This is a UI-only change that improves user experience by showing the financial year format directly in the dropdown, while maintaining backward compatibility with the existing API that expects a starting year for financial year calculations.

## Glossary

- **Payslip_Page**: The Flutter page component that displays employee payslip information and selection controls
- **Year_Dropdown**: The dropdown UI component that allows users to select a year for payslip retrieval
- **Financial_Year**: A 12-month period used for financial reporting, displayed in the format "YYYY-YYYY+1" (e.g., "2025-2026")
- **Starting_Year**: The first year in a financial year pair (e.g., 2025 in "2025-2026")
- **API_Service**: The backend service that accepts financial year parameters for payslip data retrieval

## Requirements

### Requirement 1: Display Financial Years in Dropdown

**User Story:** As a user, I want to see financial years in the year dropdown, so that I can easily understand which financial period I'm selecting.

#### Acceptance Criteria

1. THE Year_Dropdown SHALL display financial years in the format "YYYY-YYYY+1" (e.g., "2025-2026", "2024-2025", "2023-2024")
2. THE Year_Dropdown SHALL generate financial year options starting from the current year going back 10 years
3. THE Year_Dropdown SHALL filter financial years to only include those where the Starting_Year is 2020 or later
4. WHEN the current year is 2026, THE Year_Dropdown SHALL display options: "2026-2027", "2025-2026", "2024-2025", "2023-2024", "2022-2023", "2021-2022", "2020-2021"

### Requirement 2: Extract Starting Year from Selection

**User Story:** As a developer, I want the system to extract the starting year from the financial year selection, so that the existing API integration continues to work without modification.

#### Acceptance Criteria

1. WHEN a user selects a financial year from the Year_Dropdown, THE Payslip_Page SHALL extract the Starting_Year from the selected value
2. WHEN the selected financial year is "2025-2026", THE Payslip_Page SHALL extract "2025" as the Starting_Year
3. THE Payslip_Page SHALL store the extracted Starting_Year in the selectedYear state variable
4. THE Payslip_Page SHALL use the extracted Starting_Year for all existing financial year calculations and API calls

### Requirement 3: Maintain API Compatibility

**User Story:** As a developer, I want the API integration to remain unchanged, so that backend services continue to receive the correct financial year format.

#### Acceptance Criteria

1. THE Payslip_Page SHALL continue to use the _buildFinancialYear() method to construct the financial year parameter for API calls
2. WHEN the Starting_Year is "2025", THE _buildFinancialYear() method SHALL return "2025-2026"
3. THE API_Service SHALL receive the financial year parameter in the same format as before the UI change
4. THE Payslip_Page SHALL maintain backward compatibility with all existing payslip data retrieval logic

### Requirement 4: Preserve Dropdown Behavior

**User Story:** As a user, I want the dropdown to behave consistently with the existing month dropdown, so that the interface remains intuitive.

#### Acceptance Criteria

1. THE Year_Dropdown SHALL display a hint text "Select Year" when no financial year is selected
2. WHEN a user changes the financial year selection, THE Payslip_Page SHALL clear any previously loaded payslip data
3. WHEN a user changes the financial year selection, THE Payslip_Page SHALL clear any error messages
4. THE Year_Dropdown SHALL maintain the same visual styling and layout as the current implementation
5. THE Year_Dropdown SHALL remain disabled until the user selects a month (if such behavior exists in current implementation)

### Requirement 5: Handle Edge Cases

**User Story:** As a developer, I want the system to handle edge cases gracefully, so that the application remains stable under all conditions.

#### Acceptance Criteria

1. WHEN the financial year list generation encounters an invalid year, THE Payslip_Page SHALL skip that entry and continue generating valid financial years
2. WHEN parsing a selected financial year value, IF the format is invalid, THEN THE Payslip_Page SHALL handle the error gracefully and prevent API calls
3. THE Year_Dropdown SHALL display at least one financial year option (2020-2021) even if the current year calculation fails
4. WHEN the extracted Starting_Year is empty or null, THE Payslip_Page SHALL prevent the "Generate Payslip" button from being enabled
