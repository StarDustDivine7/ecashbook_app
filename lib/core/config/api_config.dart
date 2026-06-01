// lib/core/api/api_config.dart
class ApiConfig {
  // static const String baseUrl = "https://testapp.ecashbook.in/api";
  //   static const String baseUrl = "https://test.ecashbook.in/api";
  static const String baseUrl = "https://portal.ecashbook.in/api";

  static const String policyList = "$baseUrl/users/policies/policy-list";
  static const String updatePolicyReadStatus =
      "$baseUrl/users/policies/update-policy-read-status";

  static const String login = "$baseUrl/login";
  static const String logout = "$baseUrl/auth/logout";
  static const String employeeDetails = "$baseUrl/users/employee/details";
  static const String punchIn = "$baseUrl/users/employee/punch-in";
  static const String lunchIn = "$baseUrl/users/employee/lunch-in";
  static const String lunchOut = "$baseUrl/users/employee/lunch-out";
  static const String breakIn = "$baseUrl/users/employee/break-in";
  static const String breakOut = "$baseUrl/users/employee/break-out";
  static const String punchOut = "$baseUrl/users/employee/punch-out";
  static const String taskList = "$baseUrl/users/task/task-list";
  static const String taskDetails = "$baseUrl/users/task/task-details";
  static const String taskStatusUpdate =
      "$baseUrl/users/task/task-status-update";
  static const String completedTaskList =
      "$baseUrl/users/task/completed-task-list";
  static const String companyHolidays = "$baseUrl/users/company/holidays";
  static const String attendanceSummary =
      "$baseUrl/users/attendance/range-summary";
  static const String attendanceDailyActivity =
      "$baseUrl/users/attendance/daily-activity";
  static const String applyLeave = "$baseUrl/users/employee/apply-leave";
  static const String listOfLeave = "$baseUrl/users/employee/list-of-leave";
  static const String leaveDetails = "$baseUrl/users/employee/leave-details";
  static const String payslipDetails =
      "$baseUrl/users/payslips/payslip-details";
  static const String performanceReviewList =
      "$baseUrl/users/review/employee_review_list";

  // Expenditure Claims
  static const String claimList =
      "$baseUrl/users/expenditure-claims/claim-list";
  static const String claimDetails =
      "$baseUrl/users/expenditure-claims/claim-details";
  static const String submitClaim =
      "$baseUrl/users/expenditure-claims/submit-claim";

  // Supply Requisitions
  static const String supplyList =
      "$baseUrl/users/expenditure-claims/supply-list";
  static const String supplyDetails =
      "$baseUrl/users/expenditure-claims/supply-details";
  static const String submitSupply =
      "$baseUrl/users/expenditure-claims/submit-Supply";

  static const String hrLetterList = "$baseUrl/users/hr-letters/letter-list";
}
