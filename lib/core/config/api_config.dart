class ApiConfig {
  static const String baseUrl = 'https://testapp.ecashbook.in/api/';

  static const String login = '${baseUrl}login';
  static const String employeeDetails = '${baseUrl}users/employee/details';
  static const String punchIn = '${baseUrl}users/employee/punch-in';
  static const String lunchIn = '${baseUrl}users/employee/lunch-in';
  static const String lunchOut = '${baseUrl}users/employee/lunch-out';

  // NEW
  static const String breakIn = '${baseUrl}users/employee/break-in';
  static const String breakOut = '${baseUrl}users/employee/break-out';

  // NEW: punch out
  static const String punchOut = '${baseUrl}users/employee/punch-out';
}
