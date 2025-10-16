import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PayslipData {
  final String employeeName;
  final String month;
  final int year;
  final double basicSalary;
  final double hra;
  final double conveyance;
  final double medical;
  final double specialBonus;
  final double epf;
  final double professionalTax;
  final double esi;

  PayslipData({
    required this.employeeName,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.hra,
    required this.conveyance,
    required this.medical,
    required this.specialBonus,
    required this.epf,
    required this.professionalTax,
    required this.esi,
  });

  double get totalEarnings => basicSalary + hra + conveyance + medical + specialBonus;
  double get totalDeductions => epf + professionalTax + esi;
  double get netPayable => totalEarnings - totalDeductions;

  Map<String, dynamic> toJson() {
    return {
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'basicSalary': basicSalary,
      'hra': hra,
      'conveyance': conveyance,
      'medical': medical,
      'specialBonus': specialBonus,
      'epf': epf,
      'professionalTax': professionalTax,
      'esi': esi,
    };
  }

  factory PayslipData.fromJson(Map<String, dynamic> json) {
    return PayslipData(
      employeeName: json['employeeName'] ?? '',
      month: json['month'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      basicSalary: (json['basicSalary'] ?? 0).toDouble(),
      hra: (json['hra'] ?? 0).toDouble(),
      conveyance: (json['conveyance'] ?? 0).toDouble(),
      medical: (json['medical'] ?? 0).toDouble(),
      specialBonus: (json['specialBonus'] ?? 0).toDouble(),
      epf: (json['epf'] ?? 0).toDouble(),
      professionalTax: (json['professionalTax'] ?? 0).toDouble(),
      esi: (json['esi'] ?? 0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'PayslipData(name: $employeeName, month: $month, year: $year, net: $netPayable)';
  }
}

class PayslipService {
  static const String _storageKey = 'cached_payslips';
  static const String _employeeDataKey = 'employee_data';
  final Random _random = Random();

  // ✅ DEFAULT EMPLOYEE DATA (Can be updated)
  Map<String, String> _employeeData = {
    'name': 'John Doe',
    'id': 'EMP001',
    'department': 'Software Development',
    'designation': 'Senior Developer',
    'email': 'john.doe@company.com',
    'phone': '+91 98765 43210',
  };

  // ✅ Constructor - Load employee data on initialization
  PayslipService() {
    _loadEmployeeData();
  }

  // ✅ GET PAYSLIP FOR SPECIFIC MONTH/YEAR
  Future<PayslipData?> getPayslip(String month, int year) async {
    try {
      // Check if payslip exists in cache first
      final cachedPayslip = await _getCachedPayslip(month, year);
      if (cachedPayslip != null) {
        return cachedPayslip;
      }

      // Generate new payslip (simulate API call)
      final payslip = await _generatePayslip(month, year);

      // Cache the generated payslip
      await _cachePayslip(payslip);

      return payslip;

    } catch (e) {
      debugPrint('❌ Error fetching payslip: $e');
      return null;
    }
  }

  // ✅ GENERATE PAYSLIP WITH REALISTIC DATA - IMPROVED VERSION
  Future<PayslipData> _generatePayslip(String month, int year) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Base salary with some variation based on year (annual increments)
    final baseAmount = 45000.0 + (_random.nextDouble() * 10000); // 45k-55k range
    final yearlyIncrement = (year - 2020) * 2000.0; // 2k increment per year
    final baseSalary = baseAmount + yearlyIncrement;

    // Calculate components based on base salary
    final hra = baseSalary * 0.40; // 40% HRA
    final conveyance = 3000.0; // Fixed conveyance
    final medical = 2500.0; // Fixed medical
    final specialBonus = _getMonthlyBonus(month); // Monthly bonus variation

    // ✅ IMPROVED: Calculate total earnings first for ESI
    final totalEarnings = baseSalary + hra + conveyance + medical + specialBonus;

    // Deductions with proper calculations
    final epf = baseSalary * 0.12; // 12% EPF on basic salary only
    final professionalTax = _calculatePT(totalEarnings); // PT based on total earnings

    // ✅ IMPROVED: ESI calculation on total earnings with ceiling
    final esiRate = 0.0075; // 0.75%
    final esiAmount = totalEarnings * esiRate;
    final esi = esiAmount > 750.0 ? 750.0 : esiAmount; // Cap at 750

    return PayslipData(
      employeeName: _employeeData['name']!,
      month: month,
      year: year,
      basicSalary: baseSalary,
      hra: hra,
      conveyance: conveyance,
      medical: medical,
      specialBonus: specialBonus,
      epf: epf,
      professionalTax: professionalTax,
      esi: esi,
    );
  }

  // ✅ CALCULATE PROFESSIONAL TAX BASED ON SALARY SLAB
  double _calculatePT(double totalEarnings) {
    if (totalEarnings <= 15000) return 0;
    if (totalEarnings <= 25000) return 150;
    if (totalEarnings <= 40000) return 200;
    return 250; // Above 40k
  }

  // ✅ GET MONTHLY BONUS BASED ON MONTH
  double _getMonthlyBonus(String month) {
    const monthlyBonuses = {
      'January': 5000.0,    // New Year bonus
      'February': 2000.0,   // Regular
      'March': 8000.0,      // Year-end bonus
      'April': 3000.0,      // Regular
      'May': 2500.0,        // Regular
      'June': 4000.0,       // Mid-year bonus
      'July': 2000.0,       // Regular
      'August': 3500.0,     // Regular
      'September': 2500.0,  // Regular
      'October': 6000.0,    // Festival bonus
      'November': 4000.0,   // Festival bonus
      'December': 10000.0,  // Year-end bonus
    };

    return monthlyBonuses[month] ?? 2000.0;
  }

  // ✅ CACHE PAYSLIP LOCALLY
  Future<void> _cachePayslip(PayslipData payslip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPayslips = await _getAllCachedPayslips();

      // Add or update payslip
      final key = '${payslip.month}_${payslip.year}';
      cachedPayslips[key] = payslip.toJson();

      // Save to preferences
      await prefs.setString(_storageKey, jsonEncode(cachedPayslips));

    } catch (e) {
      debugPrint('❌ Error caching payslip: $e');
    }
  }

  // ✅ GET CACHED PAYSLIP
  Future<PayslipData?> _getCachedPayslip(String month, int year) async {
    try {
      final cachedPayslips = await _getAllCachedPayslips();
      final key = '${month}_$year';

      if (cachedPayslips.containsKey(key)) {
        return PayslipData.fromJson(cachedPayslips[key]);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached payslip: $e');
      return null;
    }
  }

  // ✅ GET ALL CACHED PAYSLIPS
  Future<Map<String, dynamic>> _getAllCachedPayslips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_storageKey);

      if (cachedData != null) {
        return Map<String, dynamic>.from(jsonDecode(cachedData));
      }

      return {};
    } catch (e) {
      debugPrint('❌ Error getting all cached payslips: $e');
      return {};
    }
  }

  // ✅ GET PAYSLIP HISTORY
  Future<List<PayslipData>> getPayslipHistory() async {
    try {
      final cachedPayslips = await _getAllCachedPayslips();
      final payslips = <PayslipData>[];

      for (final payslipJson in cachedPayslips.values) {
        payslips.add(PayslipData.fromJson(payslipJson));
      }

      // Sort by year and month (newest first)
      payslips.sort((a, b) {
        final aDate = DateTime(a.year, _getMonthNumber(a.month));
        final bDate = DateTime(b.year, _getMonthNumber(b.month));
        return bDate.compareTo(aDate);
      });

      return payslips;
    } catch (e) {
      debugPrint('❌ Error getting payslip history: $e');
      return [];
    }
  }

  // ✅ GET CURRENT MONTH PAYSLIP
  Future<PayslipData?> getCurrentMonthPayslip() async {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return await getPayslip(months[now.month - 1], now.year);
  }

  // ✅ GET YEARLY TOTALS
  Future<Map<String, double>> getYearlyTotals(int year) async {
    try {
      final history = await getPayslipHistory();
      final yearPayslips = history.where((p) => p.year == year).toList();

      double totalEarnings = 0;
      double totalDeductions = 0;
      double totalNet = 0;
      double totalBasic = 0;
      double totalHRA = 0;
      double totalEPF = 0;

      for (final payslip in yearPayslips) {
        totalEarnings += payslip.totalEarnings;
        totalDeductions += payslip.totalDeductions;
        totalNet += payslip.netPayable;
        totalBasic += payslip.basicSalary;
        totalHRA += payslip.hra;
        totalEPF += payslip.epf;
      }

      return {
        'totalEarnings': totalEarnings,
        'totalDeductions': totalDeductions,
        'netPayable': totalNet,
        'totalBasic': totalBasic,
        'totalHRA': totalHRA,
        'totalEPF': totalEPF,
        'averageMonthly': yearPayslips.isNotEmpty ? totalNet / yearPayslips.length : 0,
        'monthsCount': yearPayslips.length.toDouble(),
      };
    } catch (e) {
      debugPrint('❌ Error calculating yearly totals: $e');
      return {};
    }
  }

  // ✅ GET MONTHS WITH PAYSLIPS FOR A YEAR
  Future<List<String>> getAvailableMonths(int year) async {
    try {
      final history = await getPayslipHistory();
      final yearPayslips = history.where((p) => p.year == year).toList();

      // Sort months chronologically
      yearPayslips.sort((a, b) => _getMonthNumber(a.month).compareTo(_getMonthNumber(b.month)));

      return yearPayslips.map((p) => p.month).toList();
    } catch (e) {
      debugPrint('❌ Error getting available months: $e');
      return [];
    }
  }

  // ✅ GET AVAILABLE YEARS
  Future<List<int>> getAvailableYears() async {
    try {
      final history = await getPayslipHistory();
      final years = history.map((p) => p.year).toSet().toList();
      years.sort((a, b) => b.compareTo(a)); // Newest first
      return years;
    } catch (e) {
      debugPrint('❌ Error getting available years: $e');
      return [];
    }
  }

  // ✅ CHECK IF PAYSLIP EXISTS
  Future<bool> hasPayslip(String month, int year) async {
    try {
      final cachedPayslips = await _getAllCachedPayslips();
      final key = '${month}_$year';
      return cachedPayslips.containsKey(key);
    } catch (e) {
      debugPrint('❌ Error checking payslip existence: $e');
      return false;
    }
  }

  // ✅ DELETE PAYSLIP
  Future<bool> deletePayslip(String month, int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPayslips = await _getAllCachedPayslips();
      final key = '${month}_$year';

      if (cachedPayslips.containsKey(key)) {
        cachedPayslips.remove(key);
        await prefs.setString(_storageKey, jsonEncode(cachedPayslips));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error deleting payslip: $e');
      return false;
    }
  }

  // ✅ CLEAR ALL PAYSLIPS
  Future<void> clearAllPayslips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('❌ Error clearing payslips: $e');
    }
  }

  // ✅ EXPORT DATA FOR BACKUP
  Future<String> exportPayslipData() async {
    try {
      final history = await getPayslipHistory();
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'employeeData': _employeeData,
        'totalPayslips': history.length,
        'payslips': history.map((p) => p.toJson()).toList(),
        'version': '1.0',
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ Error exporting data: $e');
      return '';
    }
  }

  // ✅ IMPORT DATA FROM BACKUP
  Future<bool> importPayslipData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);

      if (data['payslips'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final importedPayslips = <String, dynamic>{};

        for (final payslipJson in data['payslips']) {
          final payslip = PayslipData.fromJson(payslipJson);
          final key = '${payslip.month}_${payslip.year}';
          importedPayslips[key] = payslip.toJson();
        }

        await prefs.setString(_storageKey, jsonEncode(importedPayslips));

        // Import employee data if available
        if (data['employeeData'] != null) {
          _employeeData = Map<String, String>.from(data['employeeData']);
          await _saveEmployeeData();
        }
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error importing data: $e');
      return false;
    }
  }

  // ✅ GET PAYSLIP STATISTICS
  Future<Map<String, dynamic>> getPayslipStatistics() async {
    try {
      final history = await getPayslipHistory();

      if (history.isEmpty) {
        return {'hasData': false};
      }

      final totalPayslips = history.length;
      final totalEarnings = history.fold<double>(0, (sum, p) => sum + p.totalEarnings);
      final totalDeductions = history.fold<double>(0, (sum, p) => sum + p.totalDeductions);
      final totalNet = history.fold<double>(0, (sum, p) => sum + p.netPayable);

      final avgEarnings = totalEarnings / totalPayslips;
      final avgDeductions = totalDeductions / totalPayslips;
      final avgNet = totalNet / totalPayslips;

      final highestPay = history.map((p) => p.netPayable).reduce((a, b) => a > b ? a : b);
      final lowestPay = history.map((p) => p.netPayable).reduce((a, b) => a < b ? a : b);

      return {
        'hasData': true,
        'totalPayslips': totalPayslips,
        'totalEarnings': totalEarnings,
        'totalDeductions': totalDeductions,
        'totalNet': totalNet,
        'avgEarnings': avgEarnings,
        'avgDeductions': avgDeductions,
        'avgNet': avgNet,
        'highestPay': highestPay,
        'lowestPay': lowestPay,
        'years': getAvailableYears(),
      };
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {'hasData': false, 'error': e.toString()};
    }
  }

  // ✅ UTILITY: GET MONTH NUMBER
  int _getMonthNumber(String month) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
    return months[month] ?? 1;
  }

  // ✅ LOAD EMPLOYEE DATA FROM STORAGE
  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeDataString = prefs.getString(_employeeDataKey);

      if (employeeDataString != null) {
        final data = jsonDecode(employeeDataString);
        _employeeData = Map<String, String>.from(data);
        debugPrint('✅ Loaded employee data for ${_employeeData['name']}');
      }
    } catch (e) {
      debugPrint('❌ Error loading employee data: $e');
    }
  }

  // ✅ SAVE EMPLOYEE DATA TO STORAGE
  Future<void> _saveEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_employeeDataKey, jsonEncode(_employeeData));
      debugPrint('💾 Saved employee data');
    } catch (e) {
      debugPrint('❌ Error saving employee data: $e');
    }
  }

  // ✅ UPDATE EMPLOYEE DATA
  Future<void> updateEmployeeData({
    String? name,
    String? id,
    String? department,
    String? designation,
    String? email,
    String? phone,
  }) async {
    if (name != null) _employeeData['name'] = name;
    if (id != null) _employeeData['id'] = id;
    if (department != null) _employeeData['department'] = department;
    if (designation != null) _employeeData['designation'] = designation;
    if (email != null) _employeeData['email'] = email;
    if (phone != null) _employeeData['phone'] = phone;

    await _saveEmployeeData();
    debugPrint('✅ Updated employee data');
  }

  // ✅ GET EMPLOYEE DATA
  Map<String, String> getEmployeeData() {
    return Map<String, String>.from(_employeeData);
  }

  // ✅ SIMULATE API ERROR (FOR TESTING)
  Future<PayslipData?> getPayslipWithError(String month, int year) async {
    await Future.delayed(const Duration(seconds: 1));
    throw Exception('Network error: Unable to fetch payslip data');
  }

  // ✅ BULK GENERATE PAYSLIPS (FOR TESTING/DEMO)
  Future<List<PayslipData>> generateBulkPayslips({
    required int startYear,
    required int endYear,
    List<String>? months,
  }) async {
    try {
      const allMonths = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      final monthsToGenerate = months ?? allMonths;
      final generatedPayslips = <PayslipData>[];

      for (int year = startYear; year <= endYear; year++) {
        for (final month in monthsToGenerate) {
          // Skip future months
          final currentDate = DateTime.now();
          final payslipDate = DateTime(year, _getMonthNumber(month));

          if (payslipDate.isBefore(currentDate)) {
            final payslip = await _generatePayslip(month, year);
            await _cachePayslip(payslip);
            generatedPayslips.add(payslip);

            // Small delay to prevent overwhelming
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      }

      debugPrint('✅ Generated ${generatedPayslips.length} bulk payslips');
      return generatedPayslips;
    } catch (e) {
      debugPrint('❌ Error generating bulk payslips: $e');
      return [];
    }
  }

  // ✅ CLEANUP OLD PAYSLIPS (Keep only last N years)
  Future<int> cleanupOldPayslips({int keepYears = 3}) async {
    try {
      final currentYear = DateTime.now().year;
      final cutoffYear = currentYear - keepYears;

      final history = await getPayslipHistory();
      final toDelete = history.where((p) => p.year < cutoffYear).toList();

      int deletedCount = 0;
      for (final payslip in toDelete) {
        final success = await deletePayslip(payslip.month, payslip.year);
        if (success) deletedCount++;
      }

      debugPrint('🧹 Cleaned up $deletedCount old payslips');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error cleaning up payslips: $e');
      return 0;
    }
  }
}
