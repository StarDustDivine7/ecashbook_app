class Holiday {
  final int id;
  final String holidayName;
  final String holidayDate;
  final String holidayType;
  final String holidayDescription;

  Holiday({
    required this.id,
    required this.holidayName,
    required this.holidayDate,
    required this.holidayType,
    required this.holidayDescription,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      holidayName: json['holidayName'],
      holidayDate: json['holidayDate'],
      holidayType: json['holidayType'],
      holidayDescription: json['holidayDescription'],
    );
  }
}
