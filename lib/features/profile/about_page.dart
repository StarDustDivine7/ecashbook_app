import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'Version ${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _version = 'Version unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          // physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // App Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // App Name
                    const Text(
                      'EcashBook',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    const Text(
                      'Smart Employee Management Solution',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Version Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _version,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // About Section
              _buildSection(
                title: 'About',
                icon: Icons.info_rounded,
                child: const Text(
                  "eCashbook is India’s Compliance Infrastructure Platform (CIP) built for MSMEs in a regulated, digital economy. Going beyond traditional bookkeeping software, eCashbook provides a unified system that integrates accounting, compliance readiness, HR, payroll, inventory, and secure documentation. Designed to work seamlessly with Chartered Accountants—without replacing professional judgment, the platform embeds compliance into daily operations, ensuring continuous audit readiness, transparency, and control. This reduces operational risk and enables business owners to focus on growth while compliance runs reliably in the background. eCashbook doesn’t just record transactions—it builds confidence, continuity, and control for MSMEs.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              // Features Section
              _buildSection(
                title: 'Key Features',
                icon: Icons.star_rounded,
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.fingerprint_rounded,
                      'Biometric Authentication',
                      'Secure login with fingerprint and face recognition',
                    ),
                    _buildFeatureItem(
                      Icons.schedule_rounded,
                      'Attendance Tracking',
                      'Real-time attendance monitoring with GPS support',
                    ),
                    _buildFeatureItem(
                      Icons.attach_money_rounded,
                      'Payroll Management',
                      'Automated salary calculations and payslip generation',
                    ),
                    _buildFeatureItem(
                      Icons.beach_access_rounded,
                      'Leave Management',
                      'Apply and track leave requests seamlessly',
                    ),
                    _buildFeatureItem(
                      Icons.task_alt_rounded,
                      'Task Management',
                      'Assign and monitor tasks efficiently',
                    ),
                    _buildFeatureItem(
                      Icons.receipt_long_rounded,
                      'Expense Claims',
                      'Submit and track expenditure claims',
                    ),
                    _buildFeatureItem(
                      Icons.inventory_2_rounded,
                      'Supply Requisitions',
                      'Manage supply requests and approvals',
                    ),
                  ],
                ),
              ),

              // // Help & Support Section
              // _buildSection(
              //   title: 'Help & Support',
              //   icon: Icons.help_rounded,
              //   child: Column(
              //     children: [
              //       _buildSupportItem(
              //         Icons.fax_rounded,
              //         'FAQs',
              //         'Find answers to commonly asked questions',
              //       ),
              //       _buildSupportItem(
              //         Icons.book_rounded,
              //         'User Guide',
              //         'Learn how to use all features effectively',
              //       ),
              //       _buildSupportItem(
              //         Icons.video_library_rounded,
              //         'Video Tutorials',
              //         'Watch step-by-step video guides',
              //       ),
              //       _buildSupportItem(
              //         Icons.chat_rounded,
              //         'Live Chat',
              //         'Get instant help from our support team',
              //       ),
              //       _buildSupportItem(
              //         Icons.bug_report_rounded,
              //         'Report an Issue',
              //         'Help us improve by reporting bugs',
              //       ),
              //       _buildSupportItem(
              //         Icons.feedback_rounded,
              //         'Send Feedback',
              //         'Share your thoughts and suggestions',
              //       ),
              //     ],
              //   ),
              // ),

              // Contact Section
              _buildSection(
                title: 'Get in Touch',
                icon: Icons.contact_support_rounded,
                child: Column(
                  children: [
                    _buildContactItem(
                      Icons.email_rounded,
                      'Email',
                      'support@ecashbook.in',
                      'mailto:support@ecashbook.in',
                    ),
                    _buildContactItem(
                      Icons.language_rounded,
                      'Website',
                      'www.ecashbook.in',
                      'https://www.ecashbook.in',
                    ),
                    _buildContactItem(
                      Icons.phone_rounded,
                      'Support',
                      '+91-8444089530',
                      'tel:+91-8444089530',
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Made with ❤️ by Team ClicknGo Tech Service Pvt.Ltd ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© ${DateTime.now().year} EcashBook. All rights reserved.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: const Color(0xFF64748B),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    String url,
  ) {
    return InkWell(
      onTap: () async {
        // Copy to clipboard
        await Clipboard.setData(ClipboardData(text: value));
        // You could show a snackbar here to indicate copied
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
