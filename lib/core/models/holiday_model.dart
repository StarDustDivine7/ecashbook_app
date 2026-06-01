class Holiday {
  final int id;
  final String holidayName;
  final String holidayDate;
  final String holidayType;
  final String? holidayDescription;  // Made nullable

  Holiday({
    required this.id,
    required this.holidayName,
    required this.holidayDate,
    required this.holidayType,
    this.holidayDescription,  // Made optional
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    try {
      return Holiday(
        id: json['id'] as int? ?? 0,
        holidayName: (json['holidayName'] as String?)?.trim() ?? 'Unnamed Holiday',
        holidayDate: (json['holidayDate'] as String?)?.trim() ?? '',
        holidayType: (json['holidayType'] as String?)?.trim() ?? 'Other',
        holidayDescription: (json['holidayDescription'] as String?)?.trim(),
      );
    } catch (e) {
      // Provide default values if parsing fails
      return Holiday(
        id: 0,
        holidayName: 'Invalid Holiday',
        holidayDate: DateTime.now().toIso8601String(),
        holidayType: 'Error',
        holidayDescription: 'Failed to parse holiday data: $e',
      );
    }
  }

  // Helper method to safely format the date
  String formatDate() {
    if (holidayDate.isEmpty) return 'Date not available';
    
    try {
      final date = DateTime.tryParse(holidayDate);
      if (date != null) {
        return '${date.day} ${_getMonthName(date.month)} ${date.year}';
      }
      return holidayDate; // Return original if parsing fails
    } catch (e) {
      return holidayDate; // Return original on error
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
}
